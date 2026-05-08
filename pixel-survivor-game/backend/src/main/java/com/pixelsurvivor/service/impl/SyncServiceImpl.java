package com.pixelsurvivor.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.pixelsurvivor.common.exception.BusinessException;
import com.pixelsurvivor.common.result.ResultCode;
import com.pixelsurvivor.dto.SyncDownloadVO;
import com.pixelsurvivor.dto.SyncUploadDTO;
import com.pixelsurvivor.entity.UserSaveData;
import com.pixelsurvivor.mapper.UserSaveDataMapper;
import com.pixelsurvivor.service.SyncService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * 数据同步服务实现
 * <p>所有存档数据以 JSON 形式存储在 t_user_save_data 表中</p>
 */
@Service
@RequiredArgsConstructor
public class SyncServiceImpl implements SyncService {

    private final UserSaveDataMapper userSaveDataMapper;
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void upload(Long userId, SyncUploadDTO data) {
        if (data.getSaveData() == null) {
            throw new BusinessException(ResultCode.PARAM_ERROR);
        }

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

        // 清除用户信息缓存
        redisTemplate.delete("user:info:" + userId);
    }

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