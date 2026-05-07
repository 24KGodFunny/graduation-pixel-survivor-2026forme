package com.pixelsurvivor.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.pixelsurvivor.common.exception.BusinessException;
import com.pixelsurvivor.common.result.ResultCode;
import com.pixelsurvivor.entity.Friend;
import com.pixelsurvivor.entity.User;
import com.pixelsurvivor.mapper.FriendMapper;
import com.pixelsurvivor.service.FriendService;
import com.pixelsurvivor.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 好友服务实现类
 * <p>实现好友请求发送、接受/拒绝、好友列表查询等业务逻辑，
 * 接受好友请求时自动创建双向好友关系</p>
 *
 * @author PixelSurvivor
 */
@Service
@RequiredArgsConstructor
public class FriendServiceImpl extends ServiceImpl<FriendMapper, Friend> implements FriendService {

    private final UserService userService;

    @Override
    public boolean sendRequest(Long userId, Long friendId) {
        if (userId.equals(friendId)) {
            throw new BusinessException(ResultCode.BAD_REQUEST);
        }
        User friend = userService.getById(friendId);
        if (friend == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }
        LambdaQueryWrapper<Friend> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Friend::getUserId, userId).eq(Friend::getFriendId, friendId);
        if (this.count(wrapper) > 0) {
            throw new BusinessException(ResultCode.ALREADY_FRIENDS);
        }
        Friend f = new Friend();
        f.setUserId(userId);
        f.setFriendId(friendId);
        f.setStatus(0);
        f.setCreatedAt(LocalDateTime.now());
        return this.save(f);
    }

    @Override
    public boolean handleRequest(Long requestId, boolean accept) {
        Friend f = this.getById(requestId);
        if (f == null) {
            throw new BusinessException(ResultCode.NOT_FOUND);
        }
        if (accept) {
            f.setStatus(1);
            this.updateById(f);
            // 创建双向好友关系
            Friend reverse = new Friend();
            reverse.setUserId(f.getFriendId());
            reverse.setFriendId(f.getUserId());
            reverse.setStatus(1);
            reverse.setCreatedAt(LocalDateTime.now());
            return this.save(reverse);
        } else {
            f.setStatus(2);
            return this.updateById(f);
        }
    }

    @Override
    public List<Friend> getFriendList(Long userId) {
        LambdaQueryWrapper<Friend> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Friend::getUserId, userId).eq(Friend::getStatus, 1);
        return this.list(wrapper);
    }
}