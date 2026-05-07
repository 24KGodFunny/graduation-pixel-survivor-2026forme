package com.pixelsurvivor.common.exception;

import com.pixelsurvivor.common.result.ResultCode;
import lombok.Getter;

/**
 * 自定义业务异常
 * <p>在Service层业务逻辑校验失败时抛出（如余额不足、商品下架等），
 * 由 GlobalExceptionHandler 统一捕获并转换为 Result 响应</p>
 *
 * @author PixelSurvivor
 */
@Getter
public class BusinessException extends RuntimeException {

    private final int code;

    public BusinessException(ResultCode resultCode) {
        super(resultCode.getMessage());
        this.code = resultCode.getCode();
    }

    public BusinessException(ResultCode resultCode, String message) {
        super(message);
        this.code = resultCode.getCode();
    }

    public BusinessException(int code, String message) {
        super(message);
        this.code = code;
    }
}