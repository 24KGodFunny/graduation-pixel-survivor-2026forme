package com.pixelsurvivor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 角色定义实体
 * 对应数据库表 t_character_definition
 */
@Data
@TableName("t_character_definition")
public class CharacterDefinition {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 唯一业务标识，如 maphy */
    private String charCode;

    /** 角色中文名，如 玛菲 */
    private String charName;

    /** 角色英文名，如 Maphy */
    private String charNameEn;

    /** 角色描述 */
    private String description;

    /** 基础生命上限 */
    private Integer maxHp;

    /** 基础移动速度 */
    private Float speed;

    /** 基础护甲 */
    private Float armor;

    /** 伤害倍率 */
    private Float damageMult;

    /** 冷却倍率 */
    private Float cooldownMult;

    /** 暴击率 */
    private Float critChance;

    /** 暴击伤害 */
    private Float critDamage;

    /** 幸运值 */
    private Float luck;

    /** 成长值 */
    private Float growth;

    /** 贪婪值 */
    private Float greed;

    /** 拾取范围 */
    private Float magnetRange;

    /** 初始武器编码 */
    private String startingWeapon;

    /** 被动技能编码 */
    private String passive;

    /** 解锁所需金币（0=免费/条件解锁） */
    private Integer unlockCost;

    /** 解锁条件描述（NULL=默认解锁） */
    private String unlockCondition;

    /** 是否启用（1=启用，0=弃用） */
    private Integer isActive;

    /** 创建时间 */
    private LocalDateTime createdAt;
}