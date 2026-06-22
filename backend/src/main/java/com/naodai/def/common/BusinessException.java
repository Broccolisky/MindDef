package com.naodai.def.common;

/**
 * 业务异常，携带业务状态码
 * 由 GlobalExceptionHandler 统一处理，返回友好提示
 */
public class BusinessException extends RuntimeException {

    private final int code;

    public BusinessException(int code, String message) {
        super(message);
        this.code = code;
    }

    public BusinessException(String message) {
        this(ResultCode.BAD_REQUEST, message);
    }

    public int getCode() {
        return code;
    }
}
