package com.pixelsurvivor.config;

import com.fasterxml.jackson.annotation.JsonAutoDetect;
import com.fasterxml.jackson.annotation.PropertyAccessor;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.jsontype.impl.LaissezFaireSubTypeValidator;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.serializer.Jackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

/**
 * Redis序列化配置
 *
 * 面试重点 - 为什么要自定义 RedisTemplate?
 *   Spring Boot 自动配置的 RedisTemplate 使用 JdkSerializationRedisSerializer 序列化 Value，
 *   序列化后的数据是二进制格式，不可读、不跨语言。
 *   自定义为 Jackson2JsonRedisSerializer 后，Redis 中存储的是 JSON 字符串，
 *   可直接在 Redis CLI 中查看，且 Python/Go 等其他语言也能解析。
 *
 * 面试重点 - 为什么需要两个 RedisTemplate?
 *   RedisTemplate<String, Object>: 存储 Java 对象（User 等），Value 用 Jackson 序列化
 *   StringRedisTemplate: 存储简单字符串（限流计数、在线用户 Set 等），Key 和 Value 都是 String
 *
 * 面试重点 - JavaTimeModule 的作用?
 *   Jackson 默认不支持 Java 8 的 LocalDateTime 等时间类型序列化，
 *   注册 JavaTimeModule 后可以正确处理 LocalDateTime → JSON 字符串的转换。
 *
 * @author PixelSurvivor
 */
@Configuration
public class RedisConfig {

    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory factory) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(factory);

        // Key 使用 String 序列化器（可读的字符串格式）
        StringRedisSerializer stringSerializer = new StringRedisSerializer();
        template.setKeySerializer(stringSerializer);
        template.setHashKeySerializer(stringSerializer);

        // Value 使用 Jackson JSON 序列化器（替代默认的 JDK 二进制序列化）
        ObjectMapper om = new ObjectMapper();
        om.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
        // 启用多态类型信息，确保反序列化时能还原子类型
        om.activateDefaultTyping(LaissezFaireSubTypeValidator.instance,
                ObjectMapper.DefaultTyping.NON_FINAL);
        // 支持 Java 8 时间类型（LocalDateTime 等）的序列化
        om.registerModule(new JavaTimeModule());

        Jackson2JsonRedisSerializer<Object> jsonSerializer =
                new Jackson2JsonRedisSerializer<>(om, Object.class);
        template.setValueSerializer(jsonSerializer);
        template.setHashValueSerializer(jsonSerializer);

        template.afterPropertiesSet();
        return template;
    }

    @Bean
    public StringRedisTemplate stringRedisTemplate(RedisConnectionFactory factory) {
        return new StringRedisTemplate(factory);
    }
}