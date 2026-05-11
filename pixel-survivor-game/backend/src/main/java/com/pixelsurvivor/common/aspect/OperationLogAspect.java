package com.pixelsurvivor.common.aspect;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pixelsurvivor.common.annotation.OperationLog;
import com.pixelsurvivor.common.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

/**
 * 操作日志AOP切面
 * <p>拦截所有标注了 {@link OperationLog} 注解的Controller方法，
 * 通过 @Around 环绕通知自动记录：操作人、模块、类型、请求参数、
 * 响应结果、IP地址、耗时等信息，并异步写入 admin_operation_log 表</p>
 *
 * @author PixelSurvivor
 */
@Slf4j
@Aspect
@Component
@RequiredArgsConstructor
public class OperationLogAspect {

    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper;
    private final JwtUtil jwtUtil;

    @Around("@annotation(operationLog)")
    public Object around(ProceedingJoinPoint joinPoint, OperationLog operationLog) throws Throwable {
        long startTime = System.currentTimeMillis();
        Object result = null;
        String errorMsg = null;

        try {
            result = joinPoint.proceed();
            return result;
        } catch (Throwable e) {
            errorMsg = e.getMessage();
            throw e;
        } finally {
            long costTime = System.currentTimeMillis() - startTime;
            try {
                saveLog(joinPoint, operationLog, result, errorMsg, costTime);
            } catch (Exception e) {
                log.error("保存操作日志失败", e);
            }
        }
    }

    private void saveLog(ProceedingJoinPoint joinPoint, OperationLog operationLog,
                         Object result, String errorMsg, long costTime) {
        ServletRequestAttributes attributes =
                (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes == null) return;

        HttpServletRequest request = attributes.getRequest();

        // 从Token解析管理员信息
        Long adminId = null;
        String adminUsername = "unknown";
        String token = request.getHeader("Authorization");
        if (token != null && token.startsWith("Bearer ")) {
            token = token.substring(7);
            try {
                adminId = jwtUtil.getAdminId(token);
                adminUsername = jwtUtil.parseToken(token).get("username", String.class);
            } catch (Exception ignored) {}
        }

        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        String className = joinPoint.getTarget().getClass().getSimpleName();
        String methodName = signature.getName();

        String params;
        try {
            params = objectMapper.writeValueAsString(joinPoint.getArgs());
            if (params.length() > 1000) params = params.substring(0, 1000);
        } catch (Exception e) {
            params = "序列化失败";
        }

        String response;
        try {
            response = objectMapper.writeValueAsString(result);
            if (response.length() > 1000) response = response.substring(0, 1000);
        } catch (Exception e) {
            response = "序列化失败";
        }

        String sql = "INSERT INTO t_admin_operation_log (admin_id, admin_username, module, operation, " +
                "description, method, params, response, ip, error_msg, cost_time, created_at) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())";

        jdbcTemplate.update(sql,
                adminId,
                adminUsername,
                operationLog.module(),
                operationLog.operation(),
                operationLog.description(),
                className + "." + methodName,
                params,
                response,
                getClientIp(request),
                errorMsg,
                costTime
        );
    }

    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("X-Real-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }
        if (ip != null && ip.contains(",")) {
            ip = ip.split(",")[0].trim();
        }
        return ip;
    }
}