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
 * 面试重点 - 认证流程:
 *   1. 检查请求头是否有 Authorization: Bearer xxx
 *   2. 调用 JwtUtil.validateToken() 验证签名和过期时间
 *   3. 检查 tokenType=="game"（防止管理员 Token 访问游戏接口，或反过来）
 *   4. 从 Token 解析 userId，存入 request attribute → Controller 通过 @RequestAttribute 获取
 *
 * 面试重点 - 为什么不把认证逻辑放在 Controller 里?
 *   拦截器是横切关注点（cross-cutting concern），与业务逻辑无关。
 *   如果放在 Controller，每个接口都要写重复的认证代码。拦截器统一处理，Controller 只管业务。
 *
 * 面试重点 - OPTIONS 请求为什么放行?
 *   浏览器跨域请求会先发一个 OPTIONS 预检请求（CORS preflight），
 *   检查服务端是否允许跨域。预检请求不携带 Token，所以必须放行。
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
        // OPTIONS请求放行（CORS 预检请求不携带 Token）
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        // 第一步：从请求头提取 Bearer Token
        String token = request.getHeader("Authorization");
        if (token == null || !token.startsWith("Bearer ")) {
            writeError(response, ResultCode.UNAUTHORIZED);
            return false;
        }

        // 去掉 "Bearer " 前缀，得到纯 Token 字符串
        token = token.substring(7);

        // 第二步：验证 Token 签名和过期时间
        if (!jwtUtil.validateToken(token)) {
            writeError(response, ResultCode.UNAUTHORIZED);
            return false;
        }

        // 第三步：验证 Token 类型为 "game"（硬隔离，防止越权）
        String type = jwtUtil.getTokenType(token);
        if (!"game".equals(type)) {
            writeError(response, ResultCode.FORBIDDEN);
            return false;
        }

        // 第四步：将 userId 存入 request attribute，供 Controller 通过 @RequestAttribute 获取
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