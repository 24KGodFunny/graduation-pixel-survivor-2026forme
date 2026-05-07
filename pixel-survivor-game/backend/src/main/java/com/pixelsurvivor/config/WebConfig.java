package com.pixelsurvivor.config;

import com.pixelsurvivor.config.interceptor.GameAuthInterceptor;
import com.pixelsurvivor.config.interceptor.AdminAuthInterceptor;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web MVC配置类
 * <p>配置跨域（CORS）策略和注册认证拦截器：
 * 游戏端拦截器拦截 /api/game/** 路径，管理端拦截器拦截 /api/admin/** 路径，
 * 各自排除登录/注册等无需认证的接口</p>
 *
 * @author PixelSurvivor
 */
@Configuration
@RequiredArgsConstructor
public class WebConfig implements WebMvcConfigurer {

    private final GameAuthInterceptor gameAuthInterceptor;
    private final AdminAuthInterceptor adminAuthInterceptor;

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