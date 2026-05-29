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
 *
 * 面试重点 - AOP 核心概念:
 *   切面（Aspect）= 切点（Pointcut）+ 通知（Advice）
 *   - 切点：@annotation(operationLog) 表示拦截所有标注了 @OperationLog 注解的方法
 *   - 通知：@Around 环绕通知，可以控制方法执行前后的逻辑
 *
 * 面试重点 - @Around vs @Before/@After:
 *   @Around 是最强大的通知类型，可以：
 *   (1) 在方法执行前做处理
 *   (2) 调用 joinPoint.proceed() 执行目标方法
 *   (3) 在方法执行后做处理（无论成功或异常）
 *   (4) 修改返回值（本项目没用到这个能力）
 *   @Before 只能在方法前执行，@After 只能在方法后执行，都不能拿到方法耗时。
 *
 * 面试重点 - 为什么用 JdbcTemplate 而不是 MyBatis Mapper?
 *   AOP 切面的初始化时机可能早于某些 Bean，在切面中注入 Mapper 可能有循环依赖风险。
 *   JdbcTemplate 是 Spring 原生提供的，注入更安全。而且日志写入只是简单 INSERT，
 *   不需要 MyBatis 的查询能力。
 *
 * 面试重点 - 为什么在 finally 块中保存日志?
 *   finally 块保证无论目标方法正常返回还是抛异常，日志都会被记录。
 *   如果方法抛异常，errorMsg 会记录异常信息，日志照样入库。
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