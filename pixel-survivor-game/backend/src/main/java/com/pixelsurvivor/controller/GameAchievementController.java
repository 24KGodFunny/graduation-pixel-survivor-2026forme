package com.pixelsurvivor.controller;

import com.pixelsurvivor.common.result.Result;
import com.pixelsurvivor.entity.UserAchievement;
import com.pixelsurvivor.service.UserAchievementService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 游戏端 - 成就控制器
 * <p>处理成就查询、进度更新、奖励领取等请求</p>
 *
 * @author PixelSurvivor
 */
@RestController
@RequestMapping("/api/game/achievement")
@RequiredArgsConstructor
public class GameAchievementController {

    private final UserAchievementService userAchievementService;

    /** 获取用户成就进度列表 */
    @GetMapping("/list")
    public Result<List<UserAchievement>> getAchievements(@RequestAttribute Long userId) {
        return Result.success(userAchievementService.getUserAchievements(userId));
    }

    /** 更新成就进度（游戏客户端上报） */
    @PostMapping("/progress")
    public Result<?> updateProgress(@RequestAttribute Long userId, @RequestBody Map<String, Object> params) {
        String achievementCode = params.get("achievementCode").toString();
        int progress = Integer.parseInt(params.get("progress").toString());
        userAchievementService.updateProgress(userId, achievementCode, progress);
        return Result.success();
    }

    /** 领取成就奖励 */
    @PostMapping("/claim")
    public Result<?> claimReward(@RequestAttribute Long userId, @RequestBody Map<String, String> params) {
        String achievementCode = params.get("achievementCode");
        userAchievementService.claimReward(userId, achievementCode);
        return Result.success("成就奖励领取成功");
    }
}