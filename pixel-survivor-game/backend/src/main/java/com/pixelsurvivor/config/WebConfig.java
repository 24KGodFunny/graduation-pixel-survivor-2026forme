package com.pixelsurvivor.config;

import com.pixelsurvivor.config.interceptor.GameAuthInterceptor;
import com.pixelsurvivor.config.interceptor.AdminAuthInterceptor;
import com.pixelsurvivor.config.interceptor.RateLimitInterceptor;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web MVC配置类
 *
 * 面试重点 - 拦截器链设计:
 *   三个拦截器按 order 优先级执行：
 *   order=0: RateLimitInterceptor（限流）—— 最先执行，超限直接返回 429，不走后续认证
 *   order=1: GameAuthInterceptor（游戏端认证）—— 处理 /api/game/** 路径
 *   order=2: AdminAuthInterceptor（管理端认证）—— 处理 /api/admin/** 路径
 *
 *   为什么先限流再认证？如果认证通过了但被限流拦截，浪费了认证的计算资源。
 *   先限流可以尽早拒绝恶意请求，保护后续逻辑。
 *
 * 面试重点 - 路径隔离:
 *   /api/game/** 用 GameAuthInterceptor → 只接受 tokenType="game" 的 Token
 *   /api/admin/** 用 AdminAuthInterceptor → 只接受 tokenType="admin" 的 Token
 *   登录/注册路径被排除（excludePathPatterns），不需要 Token
 *
 * 面试重点 - Interceptor vs Filter:
 *   Filter 是 Servlet 规范，所有请求都经过（包括静态资源）
 *   Interceptor 是 Spring MVC 特有，只拦截经过 DispatcherServlet 的请求
 *   Interceptor 可以访问 Handler（Controller方法）和方法参数，Filter 不行
 *   本项目用 Interceptor 是因为需要根据路径区分认证策略 + 注入 userId 到 request attribute
 *
 * @author PixelSurvivor
 */
@Configuration
@RequiredArgsConstructor
public class WebConfig implements WebMvcConfigurer {

    private final GameAuthInterceptor gameAuthInterceptor;
    private final AdminAuthInterceptor adminAuthInterceptor;
    private final RateLimitInterceptor rateLimitInterceptor;

    /**
     * CORS 跨域配置
     * 面试重点：allowCredentials=true 时，allowedOriginPatterns 不能用 "*"，
     * 必须用 allowedOriginPatterns("*") 代替 allowedOrigins("*")。
     * maxAge=3600 表示预检请求（OPTIONS）的缓存时间为 1 小时。
     */
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOriginPatterns("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // API限流拦截器（优先级最高，对所有 /api/** 生效）
        registry.addInterceptor(rateLimitInterceptor)
                .addPathPatterns("/api/**")
                .order(0);

        // 游戏端认证拦截器
        registry.addInterceptor(gameAuthInterceptor)
                .addPathPatterns("/api/game/**")
                .excludePathPatterns(
                        "/api/game/auth/**",
                        "/api/game/user/login",
                        "/api/game/user/register"
                );

        // 管理端认证拦截器
        registry.addInterceptor(adminAuthInterceptor)
                .addPathPatterns("/api/admin/**")
                .excludePathPatterns("/api/admin/auth/login");
    }
}