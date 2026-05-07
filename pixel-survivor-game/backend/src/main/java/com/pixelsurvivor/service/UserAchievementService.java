package com.pixelsurvivor.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.pixelsurvivor.entity.UserAchievement;

import java.util.List;

/**
 * 用户成就服务接口
 */
public interface UserAchievementService extends IService<UserAchievement> {

    /** 获取用户成就进度列表 */
    List<UserAchievement> getUserAchievements(Long userId);

    /** 更新成就进度 */
    boolean updateProgress(Long userId, String achievementCode, int progress);

    /** 领取成就奖励 */
    boolean claimReward(Long userId, String achievementCode);
}