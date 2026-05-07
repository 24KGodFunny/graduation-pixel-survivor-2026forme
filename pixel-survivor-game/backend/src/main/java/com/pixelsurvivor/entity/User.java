package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户实体
 */
@Data
@TableName("t_user")
public class User {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String username;

    private String password;

    /** 昵称 */
    private String nickname;

    /** 头像URL */
    private String avatarUrl;

    /** 邮箱 */
    private String email;

    /** 游戏币 */
    private Long gameCoin;

    /** 钻石 */
    private Long diamond;

    /** 等级 */
    private Integer level;

    /** 经验值 */
    private Integer exp;

    /** 总游戏时长(秒) */
    private Integer totalPlayTime;

    /** 最高波数 */
    private Integer maxWave;

    /** 状态: 1-正常, 0-封禁 */
    private Integer status;

    /** 是否在线 */
    private Integer isOnline;

    /** 最后登录时间 */
    private LocalDateTime lastLoginAt;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}
