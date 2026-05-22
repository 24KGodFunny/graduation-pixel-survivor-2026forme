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
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
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
@Slf4j
@Service
@RequiredArgsConstructor
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

    private final StringRedisTemplate stringRedisTemplate;
    private final RedisTemplate<String, Object> redisTemplate;
    private final PasswordEncoder passwordEncoder;

    /**
     * 用户注册
     * <p>校验用户名是否重复，使用 BCrypt 对密码进行加密存储。
     * 新用户默认赠送 500 游戏币和 50 钻石，昵称默认为"像素冒险家"。</p>
     *
     * @param username 用户名（不可重复）
     * @param password 明文密码（将被 BCrypt 加密后存储）
     * @param nickname 用户昵称（可选，为空时使用默认昵称"像素冒险家"）
     * @return 注册成功的用户实体（含数据库自增 ID）
     * @throws BusinessException 当用户名已存在时抛出 USERNAME_EXISTS 异常
     */
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

    /**
     * 用户登录
     * <p>根据用户名查询用户，使用 BCrypt 校验密码是否匹配。
     * 登录前检查用户封禁状态（status=1 表示已封禁，禁止登录）。
     * 登录成功后更新在线状态（is_online=1）和最后登录时间。</p>
     *
     * @param username 用户名
     * @param password 明文密码（将与数据库中的 BCrypt 密文比对）
     * @return 登录成功的用户实体
     * @throws BusinessException 用户名或密码错误时抛出 USERNAME_OR_PASSWORD_ERROR 异常
     * @throws BusinessException 用户已被封禁时抛出 USER_DISABLED 异常
     */
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

        // 将用户加入 Redis 在线集合
        try {
            stringRedisTemplate.opsForSet().add(RedisConstant.USER_ONLINE, user.getId().toString());
        } catch (Exception e) {
            log.warn("Redis在线用户记录失败: {}", e.getMessage());
        }

        return user;
    }

    /**
     * 根据用户 ID 获取用户信息
     * <p>采用 Cache-Aside（旁路缓存）模式：优先从 Redis 缓存中读取用户数据，
     * 缓存未命中时回源到 MySQL 数据库查询，并将结果回填到缓存中。
     * 当前实现直接查询数据库，Redis 缓存读写逻辑待完善。</p>
     *
     * @param userId 用户 ID
     * @return 用户实体
     * @throws BusinessException 当用户不存在时抛出 USER_NOT_FOUND 异常
     */
    @Override
    public User getUserById(Long userId) {
        String cacheKey = RedisConstant.USER_INFO + userId;

        // 1. 先查Redis缓存
        try {
            User cached = (User) redisTemplate.opsForValue().get(cacheKey);
            if (cached != null) {
                return cached;
            }
        } catch (Exception e) {
            log.warn("Redis查询用户缓存失败，降级查询数据库: {}", e.getMessage());
        }

        // 2. 缓存未命中，查询数据库
        User user = this.getById(userId);
        if (user == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }

        // 3. 将查询结果写入Redis缓存（TTL 30分钟）
        try {
            redisTemplate.opsForValue().set(cacheKey, user, 30, TimeUnit.MINUTES);
        } catch (Exception e) {
            log.warn("Redis写入用户缓存失败: {}", e.getMessage());
        }

        return user;
    }

    /**
     * 更新用户货币（游戏币和钻石）
     * <p>在原有数值上进行增量更新，支持正数增加和负数扣除。
     * 更新完成后删除 Redis 中的用户缓存，确保下次查询能从数据库获取最新数据。</p>
     *
     * @param userId   用户 ID
     * @param coins    游戏币增量（正数为增加，负数为扣除）
     * @param diamonds 钻石增量（正数为增加，负数为扣除）
     * @return true 表示更新成功
     * @throws BusinessException 当用户不存在时抛出 USER_NOT_FOUND 异常
     */
    @Override
    public boolean updateCurrency(Long userId, Long coins, Long diamonds) {
        User user = this.getById(userId);
        if (user == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }
        user.setGameCoin(user.getGameCoin() + coins);
        user.setDiamond(user.getDiamond() + diamonds);
        user.setUpdatedAt(LocalDateTime.now());
        // 清除缓存（降级：Redis异常不影响主流程）
        try {
            stringRedisTemplate.delete(RedisConstant.USER_INFO + userId);
        } catch (Exception e) {
            log.warn("Redis删除用户缓存失败: {}", e.getMessage());
        }
        return this.updateById(user);
    }

    /**
     * 更新用户游戏统计数据
     * <p>支持更新等级、经验、最高波次和游戏时长四项数据。
     * 最高波次（maxWave）采用"仅升不降"策略——只有当新的波次记录高于历史记录时才更新，
     * 确保始终保留玩家的最佳成绩。游戏时长（playTime）为累加值，在原有基础上增加本次游戏时间。
     * 等级和经验直接覆盖写入。更新完成后删除 Redis 缓存。</p>
     *
     * @param userId   用户 ID
     * @param level    当前等级（可为 null，表示不更新该字段）
     * @param exp     当前经验值（可为 null，表示不更新该字段）
     * @param maxWave  本次游戏达到的最高波次（仅当高于历史记录时才会写入）
     * @param playTime 本次游戏时长，单位秒（累加到总游戏时长）
     * @return true 表示更新成功
     * @throws BusinessException 当用户不存在时抛出 USER_NOT_FOUND 异常
     */
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
        try {
            stringRedisTemplate.delete(RedisConstant.USER_INFO + userId);
        } catch (Exception e) {
            log.warn("Redis删除用户缓存失败: {}", e.getMessage());
        }
        return this.updateById(user);
    }

    /**
     * 更新用户在线状态
     * <p>设置用户的 is_online 字段，用于标记当前是否在线（1 在线 / 0 离线）。</p>
     *
     * @param userId   用户 ID
     * @param isOnline 在线状态（1 表示在线，0 表示离线）
     * @return true 表示更新成功
     * @throws BusinessException 当用户不存在时抛出 USER_NOT_FOUND 异常
     */
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

    /**
     * 彻底删除用户（按用户名）
     * <p>先根据用户名查找用户记录，然后从数据库中物理删除该用户，
     * 同时清除 Redis 中该用户的缓存数据。此方法带有事务保护（@Transactional），
     * 确保删除操作的原子性。</p>
     *
     * @param username 用户名
     * @throws BusinessException 当用户不存在时抛出 USER_NOT_FOUND 异常
     */
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

        // 3. 清除 Redis 缓存（降级：Redis异常不影响主流程）
        try {
            stringRedisTemplate.delete(RedisConstant.USER_INFO + userId);
        } catch (Exception e) {
            log.warn("Redis删除用户缓存失败: {}", e.getMessage());
        }
    }
}
