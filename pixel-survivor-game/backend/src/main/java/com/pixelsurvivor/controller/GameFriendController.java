package com.pixelsurvivor.controller;

import com.pixelsurvivor.common.result.Result;
import com.pixelsurvivor.entity.Friend;
import com.pixelsurvivor.service.FriendService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 游戏端 - 好友控制器
 * <p>处理游戏客户端的好友列表查询、发送好友请求、
 * 接受/拒绝好友请求等社交功能请求</p>
 *
 * @author PixelSurvivor
 */
@RestController
@RequestMapping("/api/game/friend")
@RequiredArgsConstructor
public class GameFriendController {

    private final FriendService friendService;

    @GetMapping("/list")
    public Result<List<Friend>> getFriends(@RequestAttribute Long userId) {
        return Result.success(friendService.getFriendList(userId));
    }

    @PostMapping("/request")
    public Result<?> sendRequest(@RequestAttribute Long userId, @RequestBody Map<String, Long> params) {
        friendService.sendRequest(userId, params.get("friendId"));
        return Result.success("好友请求已发送");
    }

    @PostMapping("/handle")
    public Result<?> handleRequest(@RequestAttribute Long userId, @RequestBody Map<String, Object> params) {
        Long requestId = Long.valueOf(params.get("requestId").toString());
        Boolean accept = Boolean.valueOf(params.get("accept").toString());
        friendService.handleRequest(requestId, accept);
        return Result.success(accept ? "已接受好友请求" : "已拒绝好友请求");
    }
}