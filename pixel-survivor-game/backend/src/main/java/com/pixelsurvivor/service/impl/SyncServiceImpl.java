package com.pixelsurvivor.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.pixelsurvivor.common.exception.BusinessException;
import com.pixelsurvivor.common.result.ResultCode;
import com.pixelsurvivor.dto.SyncDownloadVO;
import com.pixelsurvivor.dto.SyncUploadDTO;
import com.pixelsurvivor.entity.*;
import com.pixelsurvivor.mapper.*;
import com.pixelsurvivor.service.SyncService;
import com.pixelsurvivor.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SyncServiceImpl implements SyncService {

    private final UserService userService;
    private final UserCharacterMapper userCharacterMapper;
    private final UserMapProgressMapper userMapProgressMapper;
    private final UserAchievementMapper userAchievementMapper;
    private final UserGameStatsMapper userGameStatsMapper;
    private final StringRedisTemplate redisTemplate;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void upload(Long userId, SyncUploadDTO data) {
        User user = userService.getById(userId);
        if (user == null) {
            throw new BusinessException(ResultCode.USER_NOT_FOUND);
        }

        // 1. 用户基础属性
        if (data.getCoins() != null) user.setGameCoin(data.getCoins());
        if (data.getDiamonds() != null) user.setDiamond(data.getDiamonds());
        if (data.getLevel() != null) user.setLevel(data.getLevel());
        if (data.getExp() != null) user.setExp(data.getExp());
        user.setUpdatedAt(LocalDateTime.now());
        userService.updateById(user);

        // 2. 角色数据
        if (data.getCharacters() != null) {
            for (SyncUploadDTO.CharacterData charData : data.getCharacters()) {
                LambdaQueryWrapper<UserCharacter> wrapper = new LambdaQueryWrapper<>();
                wrapper.eq(UserCharacter::getUserId, userId)
                        .eq(UserCharacter::getCharacterCode, charData.getCharacterCode());
                UserCharacter existing = userCharacterMapper.selectOne(wrapper);

                if (existing != null) {
                    existing.setLevel(Math.max(nvl(existing.getLevel()), nvl(charData.getLevel())));
                    existing.setHpUpgrade(Math.max(nvl(existing.getHpUpgrade()), nvl(charData.getHpUpgrade())));
                    existing.setAtkUpgrade(Math.max(nvl(existing.getAtkUpgrade()), nvl(charData.getAtkUpgrade())));
                    existing.setDefUpgrade(Math.max(nvl(existing.getDefUpgrade()), nvl(charData.getDefUpgrade())));
                    existing.setSpeedUpgrade(Math.max(nvl(existing.getSpeedUpgrade()), nvl(charData.getSpeedUpgrade())));
                    existing.setCombatPower(Math.max(nvl(existing.getCombatPower()), nvl(charData.getCombatPower())));
                    existing.setUpdatedAt(LocalDateTime.now());
                    userCharacterMapper.updateById(existing);
                } else {
                    UserCharacter newChar = new UserCharacter();
                    newChar.setUserId(userId);
                    newChar.setCharacterCode(charData.getCharacterCode());
                    newChar.setLevel(nvl(charData.getLevel(), 1));
                    newChar.setHpUpgrade(nvl(charData.getHpUpgrade()));
                    newChar.setAtkUpgrade(nvl(charData.getAtkUpgrade()));
                    newChar.setDefUpgrade(nvl(charData.getDefUpgrade()));
                    newChar.setSpeedUpgrade(nvl(charData.getSpeedUpgrade()));
                    newChar.setCombatPower(nvl(charData.getCombatPower()));
                    newChar.setIsSelected(0);
                    newChar.setAcquiredAt(LocalDateTime.now());
                    newChar.setUpdatedAt(LocalDateTime.now());
                    userCharacterMapper.insert(newChar);
                }
            }
        }

        // 3. 地图进度（字段已对齐 t_user_map_progress）
        if (data.getMapProgress() != null) {
            for (SyncUploadDTO.MapProgressData mapData : data.getMapProgress()) {
                LambdaQueryWrapper<UserMapProgress> wrapper = new LambdaQueryWrapper<>();
                wrapper.eq(UserMapProgress::getUserId, userId)
                        .eq(UserMapProgress::getMapCode, mapData.getMapCode());
                UserMapProgress existing = userMapProgressMapper.selectOne(wrapper);

                if (existing != null) {
                    existing.setIsUnlocked(Math.max(nvl(existing.getIsUnlocked()), nvl(mapData.getIsUnlocked())));
                    existing.setBestScore(Math.max(nvl(existing.getBestScore()), nvl(mapData.getBestScore())));
                    existing.setBestWave(Math.max(nvl(existing.getBestWave()), nvl(mapData.getBestWave())));
                    existing.setClearCount(Math.max(nvl(existing.getClearCount()), nvl(mapData.getClearCount())));
                    existing.setUpdatedAt(LocalDateTime.now());
                    userMapProgressMapper.updateById(existing);
                } else {
                    UserMapProgress newMap = new UserMapProgress();
                    newMap.setUserId(userId);
                    newMap.setMapCode(mapData.getMapCode());
                    newMap.setIsUnlocked(nvl(mapData.getIsUnlocked()));
                    newMap.setBestScore(nvl(mapData.getBestScore()));
                    newMap.setBestWave(nvl(mapData.getBestWave()));
                    newMap.setClearCount(nvl(mapData.getClearCount()));
                    newMap.setCreatedAt(LocalDateTime.now());
                    newMap.setUpdatedAt(LocalDateTime.now());
                    userMapProgressMapper.insert(newMap);
                }
            }
        }

        // 4. 成就
        if (data.getAchievements() != null) {
            for (SyncUploadDTO.AchievementData achData : data.getAchievements()) {
                LambdaQueryWrapper<UserAchievement> wrapper = new LambdaQueryWrapper<>();
                wrapper.eq(UserAchievement::getUserId, userId)
                        .eq(UserAchievement::getAchievementCode, achData.getAchievementCode());
                UserAchievement existing = userAchievementMapper.selectOne(wrapper);

                if (existing != null) {
                    existing.setProgress(Math.max(nvl(existing.getProgress()), nvl(achData.getProgress())));
                    if (achData.getUnlocked() != null && achData.getUnlocked() == 1) {
                        existing.setIsCompleted(1);
                    }
                    existing.setUpdatedAt(LocalDateTime.now());
                    userAchievementMapper.updateById(existing);
                } else {
                    UserAchievement newAch = new UserAchievement();
                    newAch.setUserId(userId);
                    newAch.setAchievementCode(achData.getAchievementCode());
                    newAch.setProgress(nvl(achData.getProgress()));
                    newAch.setIsCompleted(achData.getUnlocked() != null ? achData.getUnlocked() : 0);
                    newAch.setIsRewarded(0);
                    newAch.setCreatedAt(LocalDateTime.now());
                    newAch.setUpdatedAt(LocalDateTime.now());
                    userAchievementMapper.insert(newAch);
                }
            }
        }

        // 5. 游戏统计（字段已对齐 t_user_game_stats）
        if (data.getGameStats() != null) {
            LambdaQueryWrapper<UserGameStats> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(UserGameStats::getUserId, userId);
            UserGameStats existing = userGameStatsMapper.selectOne(wrapper);
            SyncUploadDTO.GameStatsData stats = data.getGameStats();

            if (existing != null) {
                existing.setTotalKills(Math.max(nvl(existing.getTotalKills()), nvl(stats.getTotalKills())));
                existing.setTotalGames(Math.max(nvl(existing.getTotalGames()), nvl(stats.getTotalGames())));
                existing.setTotalWins(Math.max(nvl(existing.getTotalWins()), nvl(stats.getTotalWins())));
                existing.setTotalCoins(Math.max(nvl(existing.getTotalCoins()), nvl(stats.getTotalCoins())));
                // bestTime 取最大值（最长存活时间）
                if (stats.getBestTime() != null) {
                    double newTime = stats.getBestTime();
                    if (existing.getBestTime() == null || newTime > existing.getBestTime()) {
                        existing.setBestTime(newTime);
                    }
                }
                existing.setUpdatedAt(LocalDateTime.now());
                userGameStatsMapper.updateById(existing);
            } else {
                UserGameStats newStats = new UserGameStats();
                newStats.setUserId(userId);
                newStats.setTotalKills(nvl(stats.getTotalKills()));
                newStats.setTotalGames(nvl(stats.getTotalGames()));
                newStats.setTotalWins(nvl(stats.getTotalWins()));
                newStats.setTotalCoins(nvl(stats.getTotalCoins()));
                newStats.setBestTime(stats.getBestTime());
                newStats.setCreatedAt(LocalDateTime.now());
                newStats.setUpdatedAt(LocalDateTime.now());
                userGameStatsMapper.insert(newStats);
            }
        }

        redisTemplate.delete("user:info:" + userId);
    }

    @Override
    public SyncDownloadVO download(Long userId) {
        User user = userService.getById(userId);
        if (user == null) throw new BusinessException(ResultCode.USER_NOT_FOUND);

        SyncDownloadVO vo = new SyncDownloadVO();
        vo.setCoins(user.getGameCoin());
        vo.setDiamonds(user.getDiamond());
        vo.setLevel(user.getLevel());
        vo.setExp(user.getExp());

        // 角色
        List<UserCharacter> characters = userCharacterMapper.selectList(
                new LambdaQueryWrapper<UserCharacter>().eq(UserCharacter::getUserId, userId));
        List<SyncDownloadVO.CharacterData> charList = new ArrayList<>();
        for (UserCharacter uc : characters) {
            SyncDownloadVO.CharacterData cd = new SyncDownloadVO.CharacterData();
            cd.setCharacterCode(uc.getCharacterCode());
            cd.setLevel(uc.getLevel());
            cd.setHpUpgrade(uc.getHpUpgrade());
            cd.setAtkUpgrade(uc.getAtkUpgrade());
            cd.setDefUpgrade(uc.getDefUpgrade());
            cd.setSpeedUpgrade(uc.getSpeedUpgrade());
            cd.setCombatPower(uc.getCombatPower());
            charList.add(cd);
        }
        vo.setCharacters(charList);

        // 地图进度
        List<UserMapProgress> maps = userMapProgressMapper.selectList(
                new LambdaQueryWrapper<UserMapProgress>().eq(UserMapProgress::getUserId, userId));
        List<SyncDownloadVO.MapProgressData> mapList = new ArrayList<>();
        for (UserMapProgress ump : maps) {
            SyncDownloadVO.MapProgressData md = new SyncDownloadVO.MapProgressData();
            md.setMapCode(ump.getMapCode());
            md.setIsUnlocked(ump.getIsUnlocked());
            md.setBestScore(ump.getBestScore());
            md.setBestWave(ump.getBestWave());
            md.setClearCount(ump.getClearCount());
            mapList.add(md);
        }
        vo.setMapProgress(mapList);

        // 成就
        List<UserAchievement> achievements = userAchievementMapper.selectList(
                new LambdaQueryWrapper<UserAchievement>().eq(UserAchievement::getUserId, userId));
        List<SyncDownloadVO.AchievementData> achList = new ArrayList<>();
        for (UserAchievement ua : achievements) {
            SyncDownloadVO.AchievementData ad = new SyncDownloadVO.AchievementData();
            ad.setAchievementCode(ua.getAchievementCode());
            ad.setUnlocked(ua.getIsCompleted());
            ad.setProgress(ua.getProgress());
            achList.add(ad);
        }
        vo.setAchievements(achList);

        // 游戏统计
        UserGameStats stats = userGameStatsMapper.selectOne(
                new LambdaQueryWrapper<UserGameStats>().eq(UserGameStats::getUserId, userId));
        if (stats != null) {
            SyncDownloadVO.GameStatsData gs = new SyncDownloadVO.GameStatsData();
            gs.setTotalKills(stats.getTotalKills());
            gs.setTotalGames(stats.getTotalGames());
            gs.setTotalWins(stats.getTotalWins());
            gs.setTotalCoins(stats.getTotalCoins());
            gs.setBestTime(stats.getBestTime());
            vo.setGameStats(gs);
        }

        return vo;
    }

    // ───── 辅助方法 ─────
    private int nvl(Integer val) { return val == null ? 0 : val; }
    private int nvl(Integer val, int defaultVal) { return val == null ? defaultVal : val; }
}