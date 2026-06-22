package com.naodai.def.dto;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;

/**
 * 登录响应 DTO
 */
@ApiModel("登录响应")
public class LoginResponse {

    @ApiModelProperty("JWT Token")
    private String token;
    @ApiModelProperty("用户ID")
    private Long userId;
    @ApiModelProperty("昵称")
    private String nickname;

    public LoginResponse(String token, Long userId, String nickname) {
        this.token = token;
        this.userId = userId;
        this.nickname = nickname;
    }

    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }
}
