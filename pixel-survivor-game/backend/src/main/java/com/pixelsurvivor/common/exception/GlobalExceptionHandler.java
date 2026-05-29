package com.pixelsurvivor.common.exception;

import com.pixelsurvivor.common.result.Result;
import com.pixelsurvivor.common.result.ResultCode;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.validation.BindException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * 全局异常处理器
 *
 * 面试重点 - 为什么需要全局异常处理?
 *   如果没有全局异常处理，每个 Controller 方法都要 try-catch 异常并手动构造错误响应。
 *   @RestControllerAdvice + @ExceptionHandler 可以统一拦截异常，Controller 只管抛异常。
 *
 * 面试重点 - 异常处理的优先级:
 *   具体异常的 @ExceptionHandler 优先于通用的 Exception handler。
 *   本项目处理顺序：BusinessException（业务异常）→ 参数校验异常 → 兜底 Exception。
 *   兜底 handler 记录完整堆栈日志，但只返回 "服务器内部错误"，不暴露内部信息给客户端（安全考虑）。
 *
 * 面试重点 - @RestControllerAdvice vs @ControllerAdvice:
 *   @RestControllerAdvice = @ControllerAdvice + @ResponseBody
 *   方法返回值自动作为 HTTP 响应体（JSON），不需要额外加 @ResponseBody。
 *
 * @author PixelSurvivor
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public Result<?> handleBusinessException(BusinessException e) {
        log.warn("业务异常: code={}, message={}", e.getCode(), e.getMessage());
        return Result.error(e.getCode(), e.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<?> handleValidationException(MethodArgumentNotValidException e) {
        String message = e.getBindingResult().getFieldErrors().stream()
                .map(error -> error.getField() + ": " + error.getDefaultMessage())
                .reduce((a, b) -> a + "; " + b)
                .orElse("参数校验失败");
        return Result.error(ResultCode.BAD_REQUEST, message);
    }

    @ExceptionHandler(BindException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<?> handleBindException(BindException e) {
        String message = e.getFieldErrors().stream()
                .map(error -> error.getField() + ": " + error.getDefaultMessage())
                .reduce((a, b) -> a + "; " + b)
                .orElse("参数绑定失败");
        return Result.error(ResultCode.BAD_REQUEST, message);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<?> handleConstraintViolation(ConstraintViolationException e) {
        return Result.error(ResultCode.BAD_REQUEST, e.getMessage());
    }

    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public Result<?> handleException(Exception e) {
        log.error("系统异常", e);
        return Result.error(ResultCode.INTERNAL_ERROR);
    }
}