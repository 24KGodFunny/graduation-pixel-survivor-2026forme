package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 地图定义实体
 * 对应数据库表 t_map_definition
 */
@Data
@TableName("t_map_definition")
public class MapDefinition {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 唯一业务标识，如 endless_road */
    private String mapCode;

    /** 地图名称，如 无尽之路 */
    private String mapName;

    /** 所属章节 */
    private Integer chapter;

    /** 章节内排序 */
    private Integer orderIndex;

    /** 解锁前置地图编码（NULL=初始即可见） */
    private String requiredMapCode;

    /** 是否启用（1=启用，0=弃用） */
    private Integer isActive;

    /** 创建时间 */
    private LocalDateTime createdAt;
}