package com.pixelsurvivor.controller;

import com.pixelsurvivor.common.result.Result;
import com.pixelsurvivor.entity.UserDailyTask;
import com.pixelsurvivor.service.UserDailyTaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 游戏端 - 每日任务控制器
 * <p>处理每日任务查询、进度更新、奖励领取等请求</p>
 *
 * @author PixelSurvivor
 */
@RestController
@RequestMapping("/api/game/task")
@RequiredArgsConstructor
public class GameTaskController {

    private final UserDailyTaskService userDailyTaskService;

    /** 获取今日任务列表 */
    @GetMapping("/today")
    public Result<List<UserDailyTask>> getTodayTasks(@RequestAttribute Long userId) {
        return Result.success(userDailyTaskService.getTodayTasks(userId));
    }

    /** 更新任务进度（游戏客户端上报） */
    @PostMapping("/progress")
    public Result<?> updateProgress(@RequestAttribute Long userId, @RequestBody Map<String, Object> params) {
        String taskCode = params.get("taskCode").toString();
        int progress = Integer.parseInt(params.get("progress").toString());
        userDailyTaskService.updateProgress(userId, taskCode, progress);
        return Result.success();
    }

    /** 领取任务奖励 */
    @PostMapping("/claim")
    public Result<?> claimReward(@RequestAttribute Long userId, @RequestBody Map<String, String> params) {
        String taskCode = params.get("taskCode");
        userDailyTaskService.claimReward(userId, taskCode);
        return Result.success("任务奖励领取成功");
    }
}