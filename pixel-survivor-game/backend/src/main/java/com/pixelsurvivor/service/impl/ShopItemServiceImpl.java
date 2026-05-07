package com.pixelsurvivor.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.pixelsurvivor.common.exception.BusinessException;
import com.pixelsurvivor.common.result.ResultCode;
import com.pixelsurvivor.entity.PurchaseRecord;
import com.pixelsurvivor.entity.ShopItem;
import com.pixelsurvivor.entity.User;
import com.pixelsurvivor.entity.UserItem;
import com.pixelsurvivor.mapper.ShopItemMapper;
import com.pixelsurvivor.service.ShopItemService;
import com.pixelsurvivor.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * 商品服务实现类
 * <p>实现商品分页查询、购买等业务逻辑，
 * 购买流程包含余额校验、库存扣减、购买记录生成、用户背包更新等操作，
 * 使用 @Transactional 保证事务一致性</p>
 *
 * @author PixelSurvivor
 */
@Service
@RequiredArgsConstructor
public class ShopItemServiceImpl extends ServiceImpl<ShopItemMapper, ShopItem> implements ShopItemService {

    private final UserService userService;
    private final com.pixelsurvivor.mapper.UserItemMapper userItemMapper;
    private final com.pixelsurvivor.mapper.PurchaseRecordMapper purchaseRecordMapper;

    @Override
    public IPage<ShopItem> getShopItems(int page, int size, String type) {
        LambdaQueryWrapper<ShopItem> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ShopItem::getStatus, 1);
        wrapper.orderByAsc(ShopItem::getSortOrder);
        return this.page(new Page<>(page, size), wrapper);
    }

    @Override
    public List<ShopItem> getAllActiveItems() {
        LambdaQueryWrapper<ShopItem> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ShopItem::getStatus, 1);
        wrapper.orderByAsc(ShopItem::getSortOrder);
        return this.list(wrapper);
    }

    @Override
    public ShopItem getByItemCode(String itemCode) {
        LambdaQueryWrapper<ShopItem> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ShopItem::getItemCode, itemCode);
        return this.getOne(wrapper);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean purchaseItem(Long userId, String itemCode, Integer quantity) {
        // 通过itemCode查询商品
        LambdaQueryWrapper<ShopItem> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(ShopItem::getItemCode, itemCode);
        ShopItem item = this.getOne(queryWrapper);
        if (item == null || item.getStatus() != 1) {
            throw new BusinessException(ResultCode.ITEM_OFF_SHELF);
        }
        if (item.getStock() != -1 && item.getStock() < quantity) {
            throw new BusinessException(ResultCode.STOCK_NOT_ENOUGH);
        }
        User user = userService.getById(userId);
        if (user == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }

        // 计算总价 - 优先使用游戏币，如果游戏币价格为0则使用钻石
        int totalCost;
        int payType; // 1游戏币 2钻石
        if (item.getPriceCoin() != null && item.getPriceCoin() > 0) {
            totalCost = item.getPriceCoin() * quantity;
            payType = 1;
            if (user.getGameCoin() < totalCost) {
                throw new BusinessException(ResultCode.COIN_NOT_ENOUGH);
            }
            user.setGameCoin(user.getGameCoin() - totalCost);
        } else if (item.getPriceDiamond() != null && item.getPriceDiamond() > 0) {
            totalCost = item.getPriceDiamond() * quantity;
            payType = 2;
            if (user.getDiamond() < totalCost) {
                throw new BusinessException(ResultCode.DIAMOND_NOT_ENOUGH);
            }
            user.setDiamond(user.getDiamond() - totalCost);
        } else {
            throw new BusinessException(ResultCode.PARAM_ERROR);
        }

        user.setUpdatedAt(LocalDateTime.now());
        userService.updateById(user);

        // 扣减库存
        if (item.getStock() != -1) {
            item.setStock(item.getStock() - quantity);
            item.setUpdatedAt(LocalDateTime.now());
            this.updateById(item);
        }

        // 记录购买
        PurchaseRecord record = new PurchaseRecord();
        record.setOrderNo(UUID.randomUUID().toString().replace("-", ""));
        record.setUserId(userId);
        record.setItemCode(itemCode);
        record.setItemName(item.getItemCode());
        record.setPayType(payType);
        record.setQuantity(quantity);
        record.setTotalPrice(totalCost);
        record.setStatus(1);
        record.setCreatedAt(LocalDateTime.now());
        purchaseRecordMapper.insert(record);

        // 更新用户背包
        LambdaQueryWrapper<UserItem> uw = new LambdaQueryWrapper<>();
        uw.eq(UserItem::getUserId, userId).eq(UserItem::getItemCode, itemCode);
        UserItem userItem = userItemMapper.selectOne(uw);
        if (userItem != null) {
            userItem.setQuantity(userItem.getQuantity() + quantity);
            userItem.setUpdatedAt(LocalDateTime.now());
            userItemMapper.updateById(userItem);
        } else {
            userItem = new UserItem();
            userItem.setUserId(userId);
            userItem.setItemCode(itemCode);
            userItem.setQuantity(quantity);
            userItem.setIsEquipped(0);
            userItem.setAcquiredAt(LocalDateTime.now());
            userItemMapper.insert(userItem);
        }
        return true;
    }
}