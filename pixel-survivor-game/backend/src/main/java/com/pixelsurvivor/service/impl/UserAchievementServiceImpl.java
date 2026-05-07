package com.pixelsurvivor.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.pixelsurvivor.common.exception.BusinessException;
import com.pixelsurvivor.common.result.ResultCode;
import com.pixelsurvivor.entity.User;
import com.pixelsurvivor.entity.UserAchievement;
import com.pixelsurvivor.mapper.UserAchievementMapper;
import com.pixelsurvivor.service.UserAchievementService;
import com.pixelsurvivor.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 用户成就服务实现类
 */
@Service
@RequiredArgsConstructor
public class UserAchievementServiceImpl extends ServiceImpl<UserAchievementMapper, UserAchievement> implements UserAchievementService {

    private final UserService userService;

    @Override
    public List<UserAchievement> getUserAchievements(Long userId) {
        LambdaQueryWrapper<UserAchievement> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserAchievement::getUserId, userId);
        return this.list(wrapper);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean updateProgress(Long userId, String achievementCode, int progress) {
        LambdaQueryWrapper<UserAchievement> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserAchievement::getUserId, userId)
                .eq(UserAchievement::getAchievementCode, achievementCode);
        UserAchievement achievement = this.getOne(wrapper);
        if (achievement == null) {
            // 首次记录
            achievement = new UserAchievement();
            achievement.setUserId(userId);
            achievement.setAchievementCode(achievementCode);
            achievement.setProgress(progress);
            achievement.setIsCompleted(0);
            achievement.setIsRewarded(0);
            achievement.setCreatedAt(LocalDateTime.now());
            achievement.setUpdatedAt(LocalDateTime.now());
            return this.save(achievement);
        }
        if (achievement.getIsCompleted() == 1) {
            return true; // 已完成，无需更新
        }
        achievement.setProgress(progress);
        achievement.setUpdatedAt(LocalDateTime.now());
        return this.updateById(achievement);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean claimReward(Long userId, String achievementCode) {
        LambdaQueryWrapper<UserAchievement> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserAchievement::getUserId, userId)
                .eq(UserAchievement::getAchievementCode, achievementCode);
        UserAchievement achievement = this.getOne(wrapper);
        if (achievement == null || achievement.getIsCompleted() != 1) {
            throw new BusinessException(ResultCode.ACHIEVEMENT_NOT_COMPLETED);
        }
        if (achievement.getIsRewarded() == 1) {
            throw new BusinessException(ResultCode.ACHIEVEMENT_REWARD_ALREADY_CLAIMED);
        }
        achievement.setIsRewarded(1);
        achievement.setCompletedAt(LocalDateTime.now());
        achievement.setUpdatedAt(LocalDateTime.now());
        return this.updateById(achievement);
    }
}