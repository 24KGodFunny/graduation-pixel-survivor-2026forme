package com.pixelsurvivor.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.pixelsurvivor.entity.ShopItem;

import java.util.List;

/**
 * 商品服务接口
 * <p>定义商品分页查询、购买等业务方法</p>
 *
 * @author PixelSurvivor
 */
public interface ShopItemService extends IService<ShopItem> {

    /**
     * 分页查询上架商品列表(带Redis缓存)
     */
    IPage<ShopItem> getShopItems(int page, int size, String type);

    /**
     * 获取所有上架商品(用于客户端同步)
     */
    List<ShopItem> getAllActiveItems();

    /**
     * 根据itemCode获取商品
     */
    ShopItem getByItemCode(String itemCode);

    /**
     * 购买商品（使用itemCode）
     */
    boolean purchaseItem(Long userId, String itemCode, Integer quantity);
}