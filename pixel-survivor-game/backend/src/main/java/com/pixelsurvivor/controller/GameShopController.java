package com.pixelsurvivor.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.pixelsurvivor.common.result.Result;
import com.pixelsurvivor.entity.ShopItem;
import com.pixelsurvivor.service.ShopItemService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 游戏端 - 商城控制器
 * <p>处理游戏客户端的商品浏览和购买请求，
 * 所有接口需要通过 GameAuthInterceptor 鉴权</p>
 *
 * @author PixelSurvivor
 */
@RestController
@RequestMapping("/api/game/shop")
@RequiredArgsConstructor
public class GameShopController {

    private final ShopItemService shopItemService;

    @GetMapping("/items")
    public Result<IPage<ShopItem>> getItems(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String type) {
        return Result.success(shopItemService.getShopItems(page, size, type));
    }

    @GetMapping("/items/{itemCode}")
    public Result<ShopItem> getItem(@PathVariable String itemCode) {
        return Result.success(shopItemService.getByItemCode(itemCode));
    }

    @PostMapping("/purchase")
    public Result<?> purchase(@RequestAttribute Long userId, @RequestBody Map<String, Object> params) {
        String itemCode = params.get("itemCode").toString();
        Integer quantity = Integer.valueOf(params.getOrDefault("quantity", 1).toString());
        shopItemService.purchaseItem(userId, itemCode, quantity);
        return Result.success("购买成功");
    }
}