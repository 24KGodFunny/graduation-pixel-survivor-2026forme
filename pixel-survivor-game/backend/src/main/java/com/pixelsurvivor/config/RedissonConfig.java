package com.pixelsurvivor.config;

import org.redisson.Redisson;
import org.redisson.api.RedissonClient;
import org.redisson.config.Config;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Redisson 分布式锁客户端配置
 * <p>读取 application.yml 中 spring.data.redis.* 的 Redis 连接信息
 * （host、port、database），创建 RedissonClient 单节点模式 Bean，
 * 用于游戏端和管理端分布式锁场景（如购买防超卖、签到防重等）</p>
 *
 * @author PixelSurvivor
 */
@Configuration
public class RedissonConfig {

    /**
     * Redis 服务器地址
     */
    @Value("${spring.data.redis.host}")
    private String host;

    /**
     * Redis 服务器端口
     */
    @Value("${spring.data.redis.port}")
    private int port;

    /**
     * Redis 数据库索引
     */
    @Value("${spring.data.redis.database:0}")
    private int database;

    /**
     * 创建 RedissonClient Bean
     * <p>使用单服务器模式（single server）连接 Redis，
     * 地址格式为 redis://host:port，数据库索引通过 setDatabase 指定</p>
     *
     * @return RedissonClient 实例，用于获取分布式锁、信号量等
     */
    @Bean(destroyMethod = "shutdown")
    public RedissonClient redissonClient() {
        Config config = new Config();
        config.useSingleServer()
                .setAddress("redis://" + host + ":" + port)
                .setDatabase(database);
        return Redisson.create(config);
    }
}
