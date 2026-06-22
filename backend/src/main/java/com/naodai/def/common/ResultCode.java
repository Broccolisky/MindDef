package com.naodai.def.common;

/**
 * 响应码常量
 */
public class ResultCode {

    public static final int SUCCESS = 0;

    public static final int BAD_REQUEST = 400;
    public static final int UNAUTHORIZED = 401;
    public static final int FORBIDDEN = 403;
    public static final int CONFLICT = 409;
    public static final int SERVER_ERROR = 500;

    /**
     * 根据状态码获取默认提示信息
     */
    public static String getMessage(int code) {
        switch (code) {
            case SUCCESS:      return "success";
            case BAD_REQUEST:  return "参数错误";
            case UNAUTHORIZED: return "未登录或Token已过期";
            case FORBIDDEN:    return "无权限";
            case CONFLICT:     return "数据冲突";
            case SERVER_ERROR: return "服务器繁忙，请稍后重试";
            default:           return "未知错误";
        }
    }
}
