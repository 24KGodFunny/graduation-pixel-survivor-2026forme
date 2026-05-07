package com.pixelsurvivor.dto;

import lombok.Data;

import java.util.List;

/**
 * 数据同步下载响应VO
 */
@Data
public class SyncDownloadVO {

    private Long coins;
    private Long diamonds;
    private Integer level;
    private Integer exp;
    private List<CharacterData> characters;
    private List<MapProgressData> mapProgress;
    private List<AchievementData> achievements;
    private GameStatsData gameStats;

    @Data
    public static class CharacterData {
        private String characterCode;
        private Integer level;
        private Integer hpUpgrade;
        private Integer atkUpgrade;
        private Integer defUpgrade;
        private Integer speedUpgrade;
        private Integer combatPower;
    }

    @Data
    public static class MapProgressData {
        private String mapCode;
        private Integer isUnlocked;
        private Integer bestScore;
        private Integer bestWave;
        private Integer clearCount;
    }

    @Data
    public static class AchievementData {
        private String achievementCode;
        private Integer unlocked;
        private Integer progress;
    }

    @Data
    public static class GameStatsData {
        private Integer totalKills;
        private Integer totalGames;
        private Integer totalWins;
        private Integer totalCoins;
        private Double bestTime;
    }
}