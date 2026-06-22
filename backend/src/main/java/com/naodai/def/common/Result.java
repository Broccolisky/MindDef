package com.naodai.def.common;

/**
 * 统一响应格式
 * 所有接口统一返回 Result<T> 结构
 */
public class Result<T> {

    /** 业务状态码：0=成功，400=参数错误，401=未认证，403=无权限，409=冲突，500=服务器错误 */
    private int code;

    /** 提示信息 */
    private String msg;

    /** 业务数据 */
    private T data;

    private Result() {}

    private Result(int code, String msg, T data) {
        this.code = code;
        this.msg = msg;
        this.data = data;
    }

    // ──────────── 成功 ────────────

    public static <T> Result<T> ok(T data) {
        return new Result<>(ResultCode.SUCCESS, "success", data);
    }

    public static <T> Result<T> ok() {
        return ok(null);
    }

    // ──────────── 失败 ────────────

    public static <T> Result<T> fail(int code, String msg) {
        return new Result<>(code, msg, null);
    }

    public static <T> Result<T> fail(int code) {
        return fail(code, ResultCode.getMessage(code));
    }

    // ──────────── Getter / Setter ────────────

    public int getCode() { return code; }
    public void setCode(int code) { this.code = code; }

    public String getMsg() { return msg; }
    public void setMsg(String msg) { this.msg = msg; }

    public T getData() { return data; }
    public void setData(T data) { this.data = data; }
}
