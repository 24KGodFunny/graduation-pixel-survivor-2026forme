package com.pixelsurvivor.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.pixelsurvivor.common.constant.RedisConstant;
import com.pixelsurvivor.common.exception.BusinessException;
import com.pixelsurvivor.common.result.ResultCode;
import com.pixelsurvivor.entity.User;
import com.pixelsurvivor.mapper.UserMapper;
import com.pixelsurvivor.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.concurrent.TimeUnit;

/**
 * 用户服务实现类
 * <p>实现用户注册、登录、信息查询、货币更新等业务逻辑，
 * 使用 Redis 缓存用户信息，使用 BCrypt 加密密码</p>
 *
 * @author PixelSurvivor
 */
@Service
@RequiredArgsConstructor
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

    private final StringRedisTemplate redisTemplate;
    private final PasswordEncoder passwordEncoder;

    @Override
    public User register(String username, String password, String nickname) {
        // 检查用户名是否已存在
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(User::getUsername, username);
        if (this.count(wrapper) > 0) {
            throw new BusinessException(ResultCode.USERNAME_EXISTS);
        }
        User user = new User();
        user.setUsername(username);
        user.setPassword(passwordEncoder.encode(password));
        user.setNickname(StringUtils.hasText(nickname) ? nickname : "像素冒险家");
        user.setGameCoin(500L);
        user.setDiamond(50L);
        user.setLevel(1);
        user.setExp(0);
        user.setMaxWave(0);
        user.setTotalPlayTime(0);
        user.setIsOnline(0);
        user.setStatus(0);
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());
        this.save(user);

        return user;
    }

    @Override
    public User login(String username, String password) {
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(User::getUsername, username);
        User user = this.getOne(wrapper);
        if (user == null || !passwordEncoder.matches(password, user.getPassword())) {
            throw new BusinessException(ResultCode.USERNAME_OR_PASSWORD_ERROR);
        }
        if (user.getStatus() == 1) {
            throw new BusinessException(ResultCode.USER_DISABLED);
        }
        // 更新在线状态
        user.setIsOnline(1);
        user.setLastLoginAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());
        this.updateById(user);
        return user;
    }

    @Override
    public User getUserById(Long userId) {
        // 先查Redis缓存
        String cacheKey = RedisConstant.USER_INFO + userId;
        // 直接查数据库(MyBatis-Plus自带缓存可后续优化)
        User user = this.getById(userId);
        if (user == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }
        return user;
    }

    @Override
    public boolean updateCurrency(Long userId, Long coins, Long diamonds) {
        User user = this.getById(userId);
        if (user == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }
        user.setGameCoin(user.getGameCoin() + coins);
        user.setDiamond(user.getDiamond() + diamonds);
        user.setUpdatedAt(LocalDateTime.now());
        // 清除缓存
        redisTemplate.delete(RedisConstant.USER_INFO + userId);
        return this.updateById(user);
    }

    @Override
    public boolean updateGameStats(Long userId, Integer level, Integer exp, Integer maxWave, Integer playTime) {
        User user = this.getById(userId);
        if (user == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }
        if (level != null) {
            user.setLevel(level);
        }
        if (exp != null) {
            user.setExp(exp);
        }
        if (maxWave != null && maxWave > user.getMaxWave()) {
            user.setMaxWave(maxWave);
        }
        if (playTime != null) {
            user.setTotalPlayTime(user.getTotalPlayTime() + playTime);
        }
        user.setUpdatedAt(LocalDateTime.now());
        redisTemplate.delete(RedisConstant.USER_INFO + userId);
        return this.updateById(user);
    }

    @Override
    public boolean updateOnlineStatus(Long userId, Integer isOnline) {
        User user = this.getById(userId);
        if (user == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }
        user.setIsOnline(isOnline);
        user.setUpdatedAt(LocalDateTime.now());
        return this.updateById(user);
    }

    @Override
    @Transactional
    public void deleteUserCompletely(String username) {
        // 1. 查找用户
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(User::getUsername, username);
        User user = this.getOne(wrapper);
        if (user == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }
        Long userId = user.getId();

        // 2. 删除 user
        this.removeById(userId);

        // 3. 清除 Redis 缓存
        redisTemplate.delete(RedisConstant.USER_INFO + userId);
    }
}
