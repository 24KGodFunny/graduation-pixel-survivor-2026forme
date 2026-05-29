package com.pixelsurvivor.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Spring Security 配置
 *
 * 面试重点 - 为什么保留 Spring Security 但禁用了它的大部分功能?
 *   本项目只需要 Spring Security 的 BCryptPasswordEncoder 做密码加密。
 *   认证逻辑由自定义的 HandlerInterceptor 处理（GameAuthInterceptor / AdminAuthInterceptor），
 *   而不是 Security 的 Filter Chain。所以这里禁用了 CSRF、Session、Form Login、HTTP Basic，
 *   把所有请求 permitAll，相当于"借用"了 Security 的密码编码能力。
 *
 * 面试重点 - 为什么禁用 CSRF?
 *   CSRF（跨站请求伪造）防护需要服务端生成 CSRF Token 并让前端每次请求携带。
 *   但本项目是无状态 REST API，前端通过 JWT Bearer Token 认证（不依赖 Cookie），
 *   天然免疫 CSRF 攻击（攻击者无法获取 JWT Token 来伪造请求）。
 *
 * 面试重点 - 为什么禁用 Session?
 *   JWT 是无状态的认证方式，每个请求通过 Token 自包含身份信息。
 *   如果启用 Session，Tomcat 会为每个请求创建 HttpSession，浪费内存且与 JWT 理念矛盾。
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // 禁用CSRF（REST API使用JWT不依赖Cookie，天然免疫CSRF）
            .csrf(AbstractHttpConfigurer::disable)
            // 禁用Session（JWT无状态认证，不需要服务端存储会话）
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            // 禁用form登录和HTTP Basic（认证由自定义拦截器处理）
            .formLogin(AbstractHttpConfigurer::disable)
            .httpBasic(AbstractHttpConfigurer::disable)
            // 允许所有请求通过（认证由自定义拦截器处理）
            .authorizeHttpRequests(auth -> auth
                .anyRequest().permitAll());

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}