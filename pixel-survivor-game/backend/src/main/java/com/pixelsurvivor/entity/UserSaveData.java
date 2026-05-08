package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户全局存档实体
 * <p>将所有存档数据以 JSON 形式存储在一个字段中</p>
 */
@Data
@TableName("t_user_save_data")
public class UserSaveData {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    /**
     * 存档JSON数据（包含角色、地图、成就、金币、钻石等全部状态）
     */
    private String saveData;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}