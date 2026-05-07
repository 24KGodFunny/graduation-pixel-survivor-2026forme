package com.pixelsurvivor.controller;

import com.pixelsurvivor.common.result.Result;
import com.pixelsurvivor.entity.UserItem;
import com.pixelsurvivor.service.UserItemService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 游戏端 - 背包控制器
 * <p>处理背包物品查询、使用等请求</p>
 *
 * @author PixelSurvivor
 */
@RestController
@RequestMapping("/api/game/inventory")
@RequiredArgsConstructor
public class GameInventoryController {

    private final UserItemService userItemService;

    /** 获取用户背包物品列表 */
    @GetMapping("/items")
    public Result<List<UserItem>> getItems(@RequestAttribute Long userId) {
        return Result.success(userItemService.getUserItems(userId));
    }

    /** 使用/消耗物品 */
    @PostMapping("/use")
    public Result<?> useItem(@RequestAttribute Long userId, @RequestBody Map<String, Object> params) {
        String itemCode = params.get("itemCode").toString();
        int quantity = Integer.parseInt(params.getOrDefault("quantity", 1).toString());
        userItemService.consumeItem(userId, itemCode, quantity);
        return Result.success("物品使用成功");
    }
}