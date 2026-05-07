package com.pixelsurvivor.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.pixelsurvivor.entity.UserDailyTask;

import java.util.List;

/**
 * 用户每日任务服务接口
 */
public interface UserDailyTaskService extends IService<UserDailyTask> {

    /** 获取用户今日任务进度列表 */
    List<UserDailyTask> getTodayTasks(Long userId);

    /** 更新任务进度 */
    boolean updateProgress(Long userId, String taskCode, int progress);

    /** 领取任务奖励 */
    boolean claimReward(Long userId, String taskCode);
}