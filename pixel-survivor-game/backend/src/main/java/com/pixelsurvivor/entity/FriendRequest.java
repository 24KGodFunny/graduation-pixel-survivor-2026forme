package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 好友请求实体
 */
@Data
@TableName("t_friend_request")
public class FriendRequest {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long fromUserId;

    private Long toUserId;

    /** 申请消息 */
    private String message;

    /** 状态: 0待处理 1同意 2拒绝 */
    private Integer status;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}