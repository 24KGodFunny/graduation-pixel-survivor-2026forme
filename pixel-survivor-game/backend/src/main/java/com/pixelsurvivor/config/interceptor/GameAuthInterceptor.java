package com.pixelsurvivor.config.interceptor;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pixelsurvivor.common.result.Result;
import com.pixelsurvivor.common.result.ResultCode;
import com.pixelsurvivor.common.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * 游戏端JWT认证拦截器
 * <p>拦截 /api/game/** 路径（排除 /api/game/auth/**），
 * 从请求头提取Bearer Token并验证有效性，确认Token类型为"game"后
 * 将userId写入request属性供下游Controller使用</p>
 *
 * @author PixelSurvivor
 */
@Component
@RequiredArgsConstructor
public class GameAuthInterceptor implements HandlerInterceptor {

    private final JwtUtil jwtUtil;
    private final ObjectMapper objectMapper;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
                             Object handler) throws Exception {
        // OPTIONS请求放行
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        String token = request.getHeader("Authorization");
        if (token == null || !token.startsWith("Bearer ")) {
            writeError(response, ResultCode.UNAUTHORIZED);
            return false;
        }

        token = token.substring(7);
        if (!jwtUtil.validateToken(token)) {
            writeError(response, ResultCode.UNAUTHORIZED);
            return false;
        }

        // 验证Token类型
        String type = jwtUtil.getTokenType(token);
        if (!"game".equals(type)) {
            writeError(response, ResultCode.FORBIDDEN);
            return false;
        }

        // 将用户信息存入request
        Long userId = jwtUtil.getUserId(token);
        request.setAttribute("userId", userId);
        return true;
    }

    private void writeError(HttpServletResponse response, ResultCode resultCode) throws Exception {
        response.setContentType("application/json;charset=UTF-8");
        response.setStatus(401);
        response.getWriter().write(objectMapper.writeValueAsString(Result.error(resultCode)));
    }
}