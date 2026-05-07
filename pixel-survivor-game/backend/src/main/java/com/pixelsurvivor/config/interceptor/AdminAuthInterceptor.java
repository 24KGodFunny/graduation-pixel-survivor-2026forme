package com.pixelsurvivor.config.interceptor;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pixelsurvivor.common.result.Result;
import com.pixelsurvivor.common.result.ResultCode;
import com.pixelsurvivor.common.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * 管理端 JWT 认证拦截器
 * <p>
 * 拦截 /api/admin/** 路径，但排除登录接口 {@code /api/admin/auth/login}。
 * 从请求头提取 Bearer Token 并验证有效性，确认 Token 类型为 "admin" 后
 * 将 adminId 写入 request 属性供下游 Controller 使用。
 * </p>
 *
 * @author PixelSurvivor
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AdminAuthInterceptor implements HandlerInterceptor {

    private final JwtUtil jwtUtil;
    private final ObjectMapper objectMapper;

    /**
     * 路径匹配器，用于判断请求是否属于登录放行路径
     */
    private static final AntPathMatcher PATH_MATCHER = new AntPathMatcher();

    /**
     * 需要放行的公开接口（不需要 token）
     */
    private static final String LOGIN_PATH = "/api/admin/login";

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
                             Object handler) throws Exception {
        // 1. 放行 OPTIONS 预检请求
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        String requestUri = request.getRequestURI();

        // 2. 放行登录接口，不进行 token 校验
        if (PATH_MATCHER.match(LOGIN_PATH, requestUri)) {
            log.debug("放行管理端登录接口: {}", requestUri);
            return true;
        }

        // 3. 获取并校验 Authorization 头
        String token = request.getHeader("Authorization");
        if (token == null || !token.startsWith("Bearer ")) {
            log.warn("管理端请求缺少有效的 Authorization 头: {}", requestUri);
            writeError(response, ResultCode.UNAUTHORIZED);
            return false;
        }

        token = token.substring(7);

        // 4. 校验 token 是否有效（过期、签名错误等）
        if (!jwtUtil.validateToken(token)) {
            log.warn("管理端 token 无效或已过期: {}", requestUri);
            writeError(response, ResultCode.UNAUTHORIZED);
            return false;
        }

        // 5. 校验 token 类型必须为 "admin"
        String type = jwtUtil.getTokenType(token);
        if (!"admin".equals(type)) {
            log.warn("管理端 token 类型错误，期望 admin，实际 {}: {}", type, requestUri);
            writeError(response, ResultCode.FORBIDDEN);
            return false;
        }

        // 6. 提取 adminId 并存入 request 属性
        Long adminId = jwtUtil.getAdminId(token);
        request.setAttribute("adminId", adminId);
        log.debug("管理端认证成功，adminId: {}", adminId);
        return true;
    }

    /**
     * 返回认证失败的 JSON 响应
     * @param response HttpServletResponse 对象
     * @param resultCode 失败的结果码（UNAUTHORIZED 或 FORBIDDEN）
     */
    private void writeError(HttpServletResponse response, ResultCode resultCode) throws Exception {
        response.setContentType("application/json;charset=UTF-8");
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);  // 统一返回 401
        response.getWriter().write(objectMapper.writeValueAsString(Result.error(resultCode)));
    }
}