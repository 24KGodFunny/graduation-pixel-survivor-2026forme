package com.pixelsurvivor.controller;

import com.pixelsurvivor.common.result.Result;
import com.pixelsurvivor.common.util.JwtUtil;
import com.pixelsurvivor.entity.User;
import com.pixelsurvivor.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * 游戏端 - 用户控制器
 * <p>处理游戏客户端的用户注册、登录、信息查询与修改等请求，
 * 登录成功后返回 JWT Token 供后续请求鉴权使用</p>
 *
 * @author PixelSurvivor
 */
@RestController
@RequestMapping("/api/game/user")
@RequiredArgsConstructor
public class GameUserController {

    private final UserService userService;
    private final JwtUtil jwtUtil;

    @PostMapping("/login")
    public Result<?> login(@RequestBody Map<String, String> params) {
        String username = params.get("username");
        String password = params.get("password");
        User user = userService.login(username, password);
        String token = jwtUtil.generateGameToken(user.getId(), user.getUsername());
        Map<String, Object> data = new HashMap<>();
        data.put("token", token);
        data.put("userId", user.getId());
        data.put("nickname", user.getNickname());
        return Result.success(data);
    }

    @PostMapping("/register")
    public Result<?> register(@RequestBody Map<String, String> params) {
        String username = params.get("username");
        String password = params.get("password");
        String nickname = params.getOrDefault("nickname", username);
        User user = userService.register(username, password, nickname);
        Map<String, Object> data = new HashMap<>();
        data.put("id", user.getId());
        data.put("username", user.getUsername());
        data.put("nickname", user.getNickname());
        return Result.success("注册成功", data);
    }

    @GetMapping("/info")
    public Result<User> getUserInfo(@RequestAttribute Long userId) {
        User user = userService.getUserById(userId);
        user.setPassword(null);
        return Result.success(user);
    }

    @PutMapping("/info")
    public Result<?> updateInfo(@RequestAttribute Long userId, @RequestBody Map<String, String> params) {
        User user = userService.getById(userId);
        if (params.containsKey("nickname")) {
            user.setNickname(params.get("nickname"));
        }
        if (params.containsKey("avatar")) {
            user.setAvatarUrl(params.get("avatar"));
        }
        userService.updateById(user);
        return Result.success();
    }
}
