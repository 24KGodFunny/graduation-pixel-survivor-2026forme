package com.pixelsurvivor.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.pixelsurvivor.entity.UserCharacter;

import java.util.List;

/**
 * 用户角色服务接口
 */
public interface UserCharacterService extends IService<UserCharacter> {

    /** 获取用户已解锁的角色列表 */
    List<UserCharacter> getUserCharacters(Long userId);

    /** 解锁角色 */
    boolean unlockCharacter(Long userId, String characterCode);

    /** 选择当前使用角色 */
    boolean selectCharacter(Long userId, String characterCode);

    /** 强化角色属性 */
    boolean upgradeCharacter(Long userId, String characterCode, String attrType);
}