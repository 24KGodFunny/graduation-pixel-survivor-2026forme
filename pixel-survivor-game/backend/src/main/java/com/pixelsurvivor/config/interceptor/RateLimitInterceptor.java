package com.pixelsurvivor.config.interceptor;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pixelsurvivor.common.annotation.RateLimit;
import com.pixelsurvivor.common.constant.RedisConstant;
import com.pixelsurvivor.common.result.Result;
import com.pixelsurvivor.common.result.ResultCode;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.concurrent.TimeUnit;

/**
 * API 请求频率限制拦截器
 *
 * 面试重点 - 固定窗口限流算法:
 *   用 Redis INCR 命令对每个 IP 的请求计数，原子操作保证并发安全。
 *   首次请求（INCR 返回 1）时设置 EXPIRE 过期时间，窗口结束后计数器自动清除。
 *   简单高效，但存在临界点问题：窗口切换瞬间可能有 2 倍流量突刺。
 *
 * 面试重点 - 固定窗口 vs 滑动窗口 vs 令牌桶:
 *   固定窗口：简单（2 条 Redis 命令），但有临界点突刺
 *   滑动窗口：记录每次请求时间戳，精确但内存开销大（可用 Sorted Set 实现）
 *   令牌桶：固定速率放令牌，允许突发流量（桶容量 > 1），适合需要平滑限流的场景
 *
 * 面试重点 - fail-open vs fail-closed:
 *   fail-open（本项目采用）：Redis 挂了就放行请求。优点：不影响业务可用性。
 *   缺点：失去限流保护。适合内部系统、对可用性要求高的场景。
 *   fail-closed：Redis 挂了就拒绝所有请求。优点：安全。缺点：Redis 故障导致服务不可用。
 *
 * @author PixelSurvivor
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RateLimitInterceptor implements HandlerInterceptor {

    /**
     * Redis 字符串操作模板，用于执行 INCR 和 EXPIRE 命令
     */
    private final StringRedisTemplate stringRedisTemplate;

    /**
     * JSON 序列化工具，用于返回 429 响应
     */
    private final ObjectMapper objectMapper;

    /**
     * 请求前置处理：校验当前 IP 是否超出限流阈值
     *
     * <p>执行流程：
     * <ol>
     *   <li>如果不是 HandlerMethod（静态资源等），直接放行</li>
     *   <li>反射获取方法上的 @RateLimit 注解，无注解则放行</li>
     *   <li>提取客户端真实 IP</li>
     *   <li>拼接 Redis Key：rate:api:{ip}</li>
     *   <li>执行 INCR 命令；若返回 1 表示首次请求，同时设置过期时间</li>
     *   <li>比较当前计数与 maxRequests，超限则返回 429</li>
     * </ol>
     * 当 Redis 操作抛出异常时，记录警告日志并放行（fail-open 策略）</p>
     *
     * @param request  客户端 HTTP 请求
     * @param response 服务端 HTTP 响应
     * @param handler  被拦截的处理器对象，仅处理 HandlerMethod 类型
     * @return true 放行，false 拦截并返回 429
     */
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
                             Object handler) throws Exception {
        // 1. 只拦截 Controller 方法，静态资源/OPTIONS 直接放行
        if (!(handler instanceof HandlerMethod)) {
            return true;
        }

        HandlerMethod handlerMethod = (HandlerMethod) handler;

        // 2. 获取方法上的 @RateLimit 注解
        RateLimit rateLimit = handlerMethod.getMethodAnnotation(RateLimit.class);
        if (rateLimit == null) {
            return true;
        }

        int window = rateLimit.window();
        int maxRequests = rateLimit.maxRequests();

        // 3. 提取客户端 IP
        String clientIp = getClientIp(request);

        // 4. 构造 Redis Key
        String redisKey = RedisConstant.RATE_API + clientIp;

        try {
            // 5. 执行 INCR，Redis 保证原子性
            Long count = stringRedisTemplate.opsForValue().increment(redisKey);

            // 6. 首次访问为该 Key 设置过期时间
            if (count != null && count == 1) {
                stringRedisTemplate.expire(redisKey, window, TimeUnit.SECONDS);
            }

            // 7. 判断是否超出限流阈值
            if (count != null && count > maxRequests) {
                log.warn("IP [{}] 在 {} 秒内请求次数超过 {} 次，已触发限流", clientIp, window, maxRequests);
                writeRateLimitResponse(response, window);
                return false;
            }
        } catch (Exception e) {
            // Redis 不可用时 fail-open，记录警告日志后放行
            log.warn("Redis 操作异常，限流拦截器降级放行: {}", e.getMessage());
            return true;
        }

        return true;
    }

    /**
     * 返回 HTTP 429 (Too Many Requests) 的 JSON 响应
     *
     * @param response HttpServletResponse 对象
     * @param window   限流时间窗口（秒），用于提示信息
     * @throws Exception 写入响应流时的 IO 异常
     */
    private void writeRateLimitResponse(HttpServletResponse response, int window) throws Exception {
        response.setContentType("application/json;charset=UTF-8");
        response.setStatus(429);
        response.getWriter().write(objectMapper.writeValueAsString(
                Result.error(429, "请求过于频繁，请 " + window + " 秒后重试")
        ));
    }

    /**
     * 提取客户端真实 IP 地址
     * <p>依次检查以下请求头，优先取代理/负载均衡器传递的真实 IP：
     * <ol>
     *   <li>X-Forwarded-For（可能有多个 IP，取第一个）</li>
     *   <li>X-Real-IP</li>
     *   <li>request.getRemoteAddr()（直接连接 IP）</li>
     * </ol></p>
     *
     * @param request 客户端 HTTP 请求
     * @return 客户端真实 IP 字符串
     */
    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("X-Real-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }
        // X-Forwarded-For 可能包含多个 IP："client, proxy1, proxy2"，取第一个
        if (ip != null && ip.contains(",")) {
            ip = ip.split(",")[0].trim();
        }
        return ip;
    }
}
