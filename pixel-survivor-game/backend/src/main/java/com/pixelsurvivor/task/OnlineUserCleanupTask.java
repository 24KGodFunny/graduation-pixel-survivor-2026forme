package com.pixelsurvivor.task;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.pixelsurvivor.common.constant.RedisConstant;
import com.pixelsurvivor.entity.User;
import com.pixelsurvivor.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.Set;

/**
 * 在线用户定时清理任务
 * <p>每隔 5 分钟执行一次，扫描 Redis 在线用户集合 {@code user:online}，
 * 对比数据库中用户的 {@code is_online} 字段，将数据库中已标记为离线的用户
 * 从 Redis Set 中移除，保证在线状态数据的一致性。</p>
 *
 * <p>该任务依赖于：
 * <ul>
 *   <li>{@link StringRedisTemplate} —— 操作 Redis Set</li>
 *   <li>{@link UserMapper} —— 查询数据库用户状态</li>
 *   <li>{@link org.springframework.scheduling.annotation.EnableScheduling}
 *       —— 已在主启动类 {@code PixelSurvivorApplication} 上启用</li>
 * </ul></p>
 *
 * @author PixelSurvivor
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OnlineUserCleanupTask {

    /**
     * Redis 字符串操作模板，用于操作在线用户 Set
     */
    private final StringRedisTemplate stringRedisTemplate;

    /**
     * 用户表 Mapper，用于查询 is_online 字段
     */
    private final UserMapper userMapper;

    /**
     * 定时清理在线用户 —— 每隔 5 分钟执行一次
     *
     * <p>执行流程：
     * <ol>
     *   <li>从 Redis 获取 {@code user:online} 集合中的所有 userId</li>
     *   <li>遍历每个 userId，查询数据库该用户的 {@code is_online} 字段</li>
     *   <li>如果用户不存在或 {@code is_online != 1}，从 Redis Set 中移除</li>
     *   <li>如果 Redis 不可用，记录警告日志并跳过本次清理</li>
     * </ol></p>
     *
     * <p>容错策略：
     * <ul>
     *   <li>Redis 连接异常 → 降级（记录警告日志，不抛异常，不影响其他定时任务）</li>
     *   <li>单个用户查询异常 → 跳过该用户，继续处理下一个</li>
     * </ul></p>
     */
    @Scheduled(fixedRate = 300000)
    public void cleanOfflineUsers() {
        log.info("========== 在线用户清理任务开始 ==========");

        // 1. 从 Redis 获取在线用户集合
        Set<String> onlineUserIds;
        try {
            onlineUserIds = stringRedisTemplate.opsForSet().members(RedisConstant.USER_ONLINE);
        } catch (Exception e) {
            log.warn("Redis 连接异常，跳过本次在线用户清理任务: {}", e.getMessage());
            return;
        }

        // 2. 校验是否为空集合
        if (onlineUserIds == null || onlineUserIds.isEmpty()) {
            log.info("当前无在线用户记录，清理任务结束");
            return;
        }

        log.info("当前 Redis 中记录的在线用户数量: {}", onlineUserIds.size());

        int removedCount = 0;

        // 3. 遍历检查每个用户
        for (String userIdStr : onlineUserIds) {
            try {
                Long userId = Long.parseLong(userIdStr);

                // 查询数据库中的用户状态
                User user = userMapper.selectOne(
                        new LambdaQueryWrapper<User>()
                                .select(User::getId, User::getIsOnline)
                                .eq(User::getId, userId)
                );

                // 用户不存在 或 is_online 不为 1，从在线集合中移除
                if (user == null || user.getIsOnline() == null || user.getIsOnline() != 1) {
                    stringRedisTemplate.opsForSet().remove(RedisConstant.USER_ONLINE, userIdStr);
                    removedCount++;
                    log.debug("移除离线用户: userId={}, isOnline={}",
                            userId, user != null ? user.getIsOnline() : "用户不存在");
                }
            } catch (NumberFormatException e) {
                // 非法 userId 格式，直接从 Set 中移除
                log.warn("Redis 在线集合中存在非法 userId: {}，已移除", userIdStr);
                try {
                    stringRedisTemplate.opsForSet().remove(RedisConstant.USER_ONLINE, userIdStr);
                    removedCount++;
                } catch (Exception ignored) {
                    // 移除失败也忽略，下次清理再处理
                }
            } catch (Exception e) {
                log.warn("检查用户 [{}] 在线状态时发生异常，跳过: {}", userIdStr, e.getMessage());
            }
        }

        log.info("在线用户清理任务完成，共移除 {} 个离线用户，Redis 中当前在线用户数: {}",
                removedCount, getOnlineUserCount());
        log.info("========== 在线用户清理任务结束 ==========");
    }

    /**
     * 获取 Redis 中当前在线用户数量
     * <p>如果 Redis 不可用，返回 -1 表示未知</p>
     *
     * @return 在线用户数量，Redis 不可用时返回 -1
     */
    private long getOnlineUserCount() {
        try {
            Long size = stringRedisTemplate.opsForSet().size(RedisConstant.USER_ONLINE);
            return size != null ? size : 0;
        } catch (Exception e) {
            log.debug("获取在线用户数量失败: {}", e.getMessage());
            return -1;
        }
    }
}
