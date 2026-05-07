package com.pixelsurvivor.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.pixelsurvivor.common.exception.BusinessException;
import com.pixelsurvivor.common.result.ResultCode;
import com.pixelsurvivor.entity.UserCharacter;
import com.pixelsurvivor.mapper.UserCharacterMapper;
import com.pixelsurvivor.service.UserCharacterService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 用户角色服务实现类
 */
@Service
@RequiredArgsConstructor
public class UserCharacterServiceImpl extends ServiceImpl<UserCharacterMapper, UserCharacter> implements UserCharacterService {

    @Override
    public List<UserCharacter> getUserCharacters(Long userId) {
        LambdaQueryWrapper<UserCharacter> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserCharacter::getUserId, userId);
        return this.list(wrapper);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean unlockCharacter(Long userId, String characterCode) {
        LambdaQueryWrapper<UserCharacter> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserCharacter::getUserId, userId)
                .eq(UserCharacter::getCharacterCode, characterCode);
        UserCharacter existing = this.getOne(wrapper);
        if (existing != null) {
            throw new BusinessException(ResultCode.CHARACTER_ALREADY_UNLOCKED);
        }
        UserCharacter character = new UserCharacter();
        character.setUserId(userId);
        character.setCharacterCode(characterCode);
        character.setIsSelected(0);
        character.setLevel(1);
        character.setHpUpgrade(0);
        character.setAtkUpgrade(0);
        character.setDefUpgrade(0);
        character.setSpeedUpgrade(0);
        character.setCombatPower(0);
        character.setAcquiredAt(LocalDateTime.now());
        character.setUpdatedAt(LocalDateTime.now());
        return this.save(character);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean selectCharacter(Long userId, String characterCode) {
        // 取消当前选中的角色
        LambdaQueryWrapper<UserCharacter> allWrapper = new LambdaQueryWrapper<>();
        allWrapper.eq(UserCharacter::getUserId, userId)
                .eq(UserCharacter::getIsSelected, 1);
        List<UserCharacter> selected = this.list(allWrapper);
        for (UserCharacter c : selected) {
            c.setIsSelected(0);
            c.setUpdatedAt(LocalDateTime.now());
            this.updateById(c);
        }
        // 选中新角色
        LambdaQueryWrapper<UserCharacter> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserCharacter::getUserId, userId)
                .eq(UserCharacter::getCharacterCode, characterCode);
        UserCharacter character = this.getOne(wrapper);
        if (character == null) {
            throw new BusinessException(ResultCode.CHARACTER_NOT_UNLOCKED);
        }
        character.setIsSelected(1);
        character.setUpdatedAt(LocalDateTime.now());
        return this.updateById(character);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean upgradeCharacter(Long userId, String characterCode, String attrType) {
        LambdaQueryWrapper<UserCharacter> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserCharacter::getUserId, userId)
                .eq(UserCharacter::getCharacterCode, characterCode);
        UserCharacter character = this.getOne(wrapper);
        if (character == null) {
            throw new BusinessException(ResultCode.CHARACTER_NOT_UNLOCKED);
        }
        switch (attrType) {
            case "hp":
                character.setHpUpgrade(character.getHpUpgrade() + 1);
                break;
            case "atk":
                character.setAtkUpgrade(character.getAtkUpgrade() + 1);
                break;
            case "def":
                character.setDefUpgrade(character.getDefUpgrade() + 1);
                break;
            case "speed":
                character.setSpeedUpgrade(character.getSpeedUpgrade() + 1);
                break;
            default:
                throw new BusinessException(ResultCode.PARAM_ERROR);
        }
        character.setUpdatedAt(LocalDateTime.now());
        return this.updateById(character);
    }
}