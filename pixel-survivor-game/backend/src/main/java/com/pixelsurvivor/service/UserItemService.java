package com.pixelsurvivor.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.pixelsurvivor.entity.UserItem;

import java.util.List;

/**
 * 用户背包服务接口
 */
public interface UserItemService extends IService<UserItem> {

    /** 获取用户背包物品列表 */
    List<UserItem> getUserItems(Long userId);

    /** 使用/消耗物品 */
    boolean consumeItem(Long userId, String itemCode, int quantity);
}