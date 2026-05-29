package com.pixelsurvivor.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.pixelsurvivor.common.constant.RedisConstant;
import com.pixelsurvivor.common.exception.BusinessException;
import com.pixelsurvivor.common.result.ResultCode;
import com.pixelsurvivor.dto.SyncDownloadVO;
import com.pixelsurvivor.dto.SyncUploadDTO;
import com.pixelsurvivor.entity.UserSaveData;
import com.pixelsurvivor.mapper.UserSaveDataMapper;
import com.pixelsurvivor.service.SyncService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.redisson.api.RLock;
import org.redisson.api.RedissonClient;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * 数据同步服务实现
 * <p>所有存档数据以 JSON 形式存储在 t_user_save_data 表中</p>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SyncServiceImpl implements SyncService {

    private final UserSaveDataMapper userSaveDataMapper;
    private final StringRedisTemplate stringRedisTemplate;
    private final ObjectMapper objectMapper;
    private final RedissonClient redissonClient;

    /**
     * 上传（同步）用户游戏存档数据到服务端
     * <p>将 SyncUploadDTO 中的存档数据（Map 结构）通过 Jackson 序列化为 JSON 字符串，
     * 存入 t_user_save_data 表。采用 upsert 策略，已有记录则更新，否则新增。
     * 写入完成后清除用户在 Redis 中的信息缓存，确保数据一致性。</p>
     *
     * @param userId 用户 ID
     * @param data   上传的存档数据 DTO，包含 saveData（Map 形式的游戏存档键值对）
     * @throws BusinessException 当存档数据为空时抛出 PARAM_ERROR 异常
     */
    /**
     * 上传（同步）用户游戏存档数据到服务端
     *
     * 面试重点 - 并发场景分析:
     *   同一用户可能在手机和电脑同时登录游戏并触发存档上传。没有锁的情况下：
     *   1. 设备A读取旧存档 → 修改 → 写入
     *   2. 设备B同时读取旧存档 → 修改 → 写入
     *   3. 设备B后写入，覆盖了设备A的修改 → 设备A的数据丢失
     *
     * 面试重点 - Redisson tryLock 参数含义:
     *   tryLock(3, 10, TimeUnit.SECONDS)
     *   - waitTime=3: 最多等待 3 秒获取锁，3 秒内拿不到就放弃（避免无限阻塞）
     *   - leaseTime=10: 锁最多持有 10 秒，超时自动释放（防止单个设备崩溃导致死锁）
     *   - 如果业务执行超过 10 秒，Redisson 的 WatchDog 会自动续期（leaseTime > 0 时 WatchDog 不启动）
     *
     * 面试重点 - @Transactional(rollbackFor = Exception.class):
     *   默认只回滚 RuntimeException，加 rollbackFor=Exception.class 确保所有异常都回滚。
     *   但注意：分布式锁的 lock/unlock 在事务之外，锁的释放不依赖事务回滚。
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void upload(Long userId, SyncUploadDTO data) {
        if (data.getSaveData() == null) {
            throw new BusinessException(ResultCode.PARAM_ERROR);
        }

        // 使用 Redisson 分布式锁防止同一用户并发上传导致数据损坏
        String lockKey = RedisConstant.LOCK_SYNC_UPLOAD + userId;
        RLock lock = redissonClient.getLock(lockKey);
        try {
            if (lock.tryLock(3, 10, TimeUnit.SECONDS)) {
                try {
                    doUpload(userId, data);
                } finally {
                    lock.unlock();
                }
            } else {
                throw new BusinessException(ResultCode.PARAM_ERROR, "同步操作过于频繁，请稍后再试");
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new BusinessException(ResultCode.INTERNAL_ERROR);
        }
    }

    /**
     * 执行实际的上传逻辑（在分布式锁保护下调用）
     */
    private void doUpload(Long userId, SyncUploadDTO data) {
        // 将 Map 转为 JSON 字符串
        String jsonStr;
        try {
            jsonStr = objectMapper.writeValueAsString(data.getSaveData());
        } catch (JsonProcessingException e) {
            throw new BusinessException(ResultCode.PARAM_ERROR);
        }

        // 查询是否已有存档
        LambdaQueryWrapper<UserSaveData> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserSaveData::getUserId, userId);
        UserSaveData existing = userSaveDataMapper.selectOne(wrapper);

        if (existing != null) {
            existing.setSaveData(jsonStr);
            existing.setUpdatedAt(LocalDateTime.now());
            userSaveDataMapper.updateById(existing);
        } else {
            UserSaveData newSave = new UserSaveData();
            newSave.setUserId(userId);
            newSave.setSaveData(jsonStr);
            newSave.setCreatedAt(LocalDateTime.now());
            newSave.setUpdatedAt(LocalDateTime.now());
            userSaveDataMapper.insert(newSave);
        }

        // 清除用户信息缓存（降级：Redis异常不影响主流程）
        try {
            stringRedisTemplate.delete(RedisConstant.USER_INFO + userId);
        } catch (Exception e) {
            log.warn("Redis删除用户缓存失败: {}", e.getMessage());
        }
    }

    /**
     * 下载（获取）用户游戏存档数据
     * <p>从 t_user_save_data 表查询指定用户的存档 JSON 字符串，
     * 通过 Jackson 反序列化为 Map 后封装到 SyncDownloadVO 中返回给客户端。
     * 若用户无存档记录或 JSON 解析失败，则返回 saveData 为 null 的空 VO 对象，
     * 由客户端自行使用默认值初始化游戏状态。</p>
     *
     * @param userId 用户 ID
     * @return SyncDownloadVO 包含存档数据 Map，无存档时 saveData 为 null
     */
    @Override
    public SyncDownloadVO download(Long userId) {
        LambdaQueryWrapper<UserSaveData> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserSaveData::getUserId, userId);
        UserSaveData saveData = userSaveDataMapper.selectOne(wrapper);

        SyncDownloadVO vo = new SyncDownloadVO();
        if (saveData != null && saveData.getSaveData() != null) {
            try {
                // 将 JSON 字符串解析为 Map 返回给前端
                Map<String, Object> dataMap = objectMapper.readValue(
                        saveData.getSaveData(),
                        new TypeReference<Map<String, Object>>() {}
                );
                vo.setSaveData(dataMap);
            } catch (JsonProcessingException e) {
                // JSON 解析失败，返回空
                vo.setSaveData(null);
            }
        }
        return vo;
    }
}