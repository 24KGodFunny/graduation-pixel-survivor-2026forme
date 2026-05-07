package com.pixelsurvivor.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.pixelsurvivor.common.exception.BusinessException;
import com.pixelsurvivor.common.result.ResultCode;
import com.pixelsurvivor.entity.UserItem;
import com.pixelsurvivor.mapper.UserItemMapper;
import com.pixelsurvivor.service.UserItemService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 用户背包服务实现类
 */
@Service
@RequiredArgsConstructor
public class UserItemServiceImpl extends ServiceImpl<UserItemMapper, UserItem> implements UserItemService {

    @Override
    public List<UserItem> getUserItems(Long userId) {
        LambdaQueryWrapper<UserItem> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserItem::getUserId, userId);
        wrapper.gt(UserItem::getQuantity, 0);
        return this.list(wrapper);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean consumeItem(Long userId, String itemCode, int quantity) {
        LambdaQueryWrapper<UserItem> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserItem::getUserId, userId).eq(UserItem::getItemCode, itemCode);
        UserItem userItem = this.getOne(wrapper);
        if (userItem == null || userItem.getQuantity() < quantity) {
            throw new BusinessException(ResultCode.ITEM_NOT_ENOUGH);
        }
        userItem.setQuantity(userItem.getQuantity() - quantity);
        userItem.setUpdatedAt(LocalDateTime.now());
        return this.updateById(userItem);
    }
}