package com.pixelsurvivor.common.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * API 接口限流注解
 * <p>标记在 Controller 方法上，配合 {@link com.pixelsurvivor.config.interceptor.RateLimitInterceptor}
 * 实现基于 Redis 固定窗口的 IP 级别请求频率限制，防止接口被恶意刷量或爬虫攻击</p>
 *
 * <p>使用示例：
 * <pre>{@code
 * @RateLimit(window = 60, maxRequests = 100)
 * @GetMapping("/some-api")
 * public Result<?> someApi() {
 *     // ...
 * }
 * }</pre>
 * 表示在 60 秒窗口内同一 IP 最多允许 100 次请求</p>
 *
 * @author PixelSurvivor
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface RateLimit {

    /**
     * 限流时间窗口（秒）
     * <p>在该时间段内统计请求次数，窗口结束后计数器重置</p>
     *
     * @return 窗口大小，默认 60 秒
     */
    int window() default 60;

    /**
     * 最大请求次数
     * <p>在指定时间窗口内允许的最大请求数量</p>
     *
     * @return 最大请求数，默认 100
     */
    int maxRequests() default 100;
}
