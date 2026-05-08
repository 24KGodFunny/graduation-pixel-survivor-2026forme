package com.pixelsurvivor.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.pixelsurvivor.entity.User;

/**
 * 用户服务接口
 * <p>定义用户注册、登录、信息查询、货币更新等业务方法</p>
 *
 * @author PixelSurvivor
 */
public interface UserService extends IService<User> {

    /**
     * 用户注册
     */
    User register(String username, String password, String nickname);

    /**
     * 用户登录
     */
    User login(String username, String password);

    /**
     * 根据ID获取用户信息(带Redis缓存)
     */
    User getUserById(Long userId);

    /**
     * 更新用户游戏币/钻石
     */
    boolean updateCurrency(Long userId, Long coins, Long diamonds);

    /**
     * 更新用户游戏统计（等级、经验、最高波数、游戏时长）
     */
    boolean updateGameStats(Long userId, Integer level, Integer exp, Integer maxWave, Integer playTime);

    /**
     * 更新用户在线状态
     */
    boolean updateOnlineStatus(Long userId, Integer isOnline);

    /**
     * 根据用户名彻底删除用户（包括所有关联表数据）
     */
    void deleteUserCompletely(String username);
}
