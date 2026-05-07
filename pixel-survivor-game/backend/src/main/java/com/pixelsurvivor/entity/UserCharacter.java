package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户角色实体（角色定义由游戏客户端资源管理）
 * <p>character_code 对应游戏客户端 characters.json 中的 id 字段</p>
 * <p>角色名、基础属性、技能、武器类型等均在客户端资源中定义</p>
 * <p>数据库只记录用户对该角色的解锁状态和强化数据</p>
 */
@Data
@TableName("t_user_character")
public class UserCharacter {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    /** 角色编码，对应游戏客户端资源ID，如 char_warrior */
    private String characterCode;

    /** 是否当前选中 */
    private Integer isSelected;

    /** 角色等级 */
    private Integer level;

    /** 生命强化次数 */
    private Integer hpUpgrade;

    /** 攻击强化次数 */
    private Integer atkUpgrade;

    /** 防御强化次数 */
    private Integer defUpgrade;

    /** 移速强化次数 */
    private Integer speedUpgrade;

    /** 战力 */
    private Integer combatPower;

    private LocalDateTime acquiredAt;

    private LocalDateTime updatedAt;
}