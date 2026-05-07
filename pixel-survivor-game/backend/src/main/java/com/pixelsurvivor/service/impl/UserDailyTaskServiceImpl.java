package com.pixelsurvivor.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.pixelsurvivor.common.exception.BusinessException;
import com.pixelsurvivor.common.result.ResultCode;
import com.pixelsurvivor.entity.UserDailyTask;
import com.pixelsurvivor.mapper.UserDailyTaskMapper;
import com.pixelsurvivor.service.UserDailyTaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 用户每日任务服务实现类
 */
@Service
@RequiredArgsConstructor
public class UserDailyTaskServiceImpl extends ServiceImpl<UserDailyTaskMapper, UserDailyTask> implements UserDailyTaskService {

    @Override
    public List<UserDailyTask> getTodayTasks(Long userId) {
        LambdaQueryWrapper<UserDailyTask> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserDailyTask::getUserId, userId)
                .eq(UserDailyTask::getTaskDate, LocalDate.now());
        return this.list(wrapper);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean updateProgress(Long userId, String taskCode, int progress) {
        LambdaQueryWrapper<UserDailyTask> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserDailyTask::getUserId, userId)
                .eq(UserDailyTask::getTaskCode, taskCode)
                .eq(UserDailyTask::getTaskDate, LocalDate.now());
        UserDailyTask task = this.getOne(wrapper);
        if (task == null) {
            // 首次记录
            task = new UserDailyTask();
            task.setUserId(userId);
            task.setTaskCode(taskCode);
            task.setTaskDate(LocalDate.now());
            task.setProgress(progress);
            task.setIsCompleted(0);
            task.setIsRewarded(0);
            task.setCreatedAt(LocalDateTime.now());
            task.setUpdatedAt(LocalDateTime.now());
            return this.save(task);
        }
        if (task.getIsCompleted() == 1) {
            return true; // 已完成，无需更新
        }
        task.setProgress(progress);
        task.setUpdatedAt(LocalDateTime.now());
        return this.updateById(task);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean claimReward(Long userId, String taskCode) {
        LambdaQueryWrapper<UserDailyTask> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserDailyTask::getUserId, userId)
                .eq(UserDailyTask::getTaskCode, taskCode)
                .eq(UserDailyTask::getTaskDate, LocalDate.now());
        UserDailyTask task = this.getOne(wrapper);
        if (task == null || task.getIsCompleted() != 1) {
            throw new BusinessException(ResultCode.TASK_NOT_COMPLETED);
        }
        if (task.getIsRewarded() == 1) {
            throw new BusinessException(ResultCode.TASK_REWARD_ALREADY_CLAIMED);
        }
        task.setIsRewarded(1);
        task.setUpdatedAt(LocalDateTime.now());
        return this.updateById(task);
    }
}