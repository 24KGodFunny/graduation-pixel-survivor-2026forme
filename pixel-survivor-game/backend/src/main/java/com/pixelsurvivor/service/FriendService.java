package com.pixelsurvivor.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.pixelsurvivor.entity.Friend;

import java.util.List;

/**
 * 好友服务接口
 * <p>定义好友请求发送、处理、好友列表查询等业务方法</p>
 *
 * @author PixelSurvivor
 */
public interface FriendService extends IService<Friend> {

    /**
     * 发送好友请求
     */
    boolean sendRequest(Long userId, Long friendId);

    /**
     * 处理好友请求
     */
    boolean handleRequest(Long requestId, boolean accept);

    /**
     * 获取好友列表
     */
    List<Friend> getFriendList(Long userId);
}