package com.pixelsurvivor.controller;

import com.pixelsurvivor.common.result.Result;
import com.pixelsurvivor.entity.UserCharacter;
import com.pixelsurvivor.service.UserCharacterService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 游戏端 - 角色控制器
 * <p>处理角色解锁、选择、强化等请求</p>
 *
 * @author PixelSurvivor
 */
@RestController
@RequestMapping("/api/game/character")
@RequiredArgsConstructor
public class GameCharacterController {

    private final UserCharacterService userCharacterService;

    /** 获取用户已解锁的角色列表 */
    @GetMapping("/list")
    public Result<List<UserCharacter>> getCharacters(@RequestAttribute Long userId) {
        return Result.success(userCharacterService.getUserCharacters(userId));
    }

    /** 解锁角色（消耗游戏币） */
    @PostMapping("/unlock")
    public Result<?> unlock(@RequestAttribute Long userId, @RequestBody Map<String, String> params) {
        String characterCode = params.get("characterCode");
        userCharacterService.unlockCharacter(userId, characterCode);
        return Result.success("角色解锁成功");
    }

    /** 选择当前使用角色 */
    @PostMapping("/select")
    public Result<?> select(@RequestAttribute Long userId, @RequestBody Map<String, String> params) {
        String characterCode = params.get("characterCode");
        userCharacterService.selectCharacter(userId, characterCode);
        return Result.success("角色选择成功");
    }

    /** 强化角色属性 */
    @PostMapping("/upgrade")
    public Result<?> upgrade(@RequestAttribute Long userId, @RequestBody Map<String, String> params) {
        String characterCode = params.get("characterCode");
        String attrType = params.get("attrType");
        userCharacterService.upgradeCharacter(userId, characterCode, attrType);
        return Result.success("强化成功");
    }
}