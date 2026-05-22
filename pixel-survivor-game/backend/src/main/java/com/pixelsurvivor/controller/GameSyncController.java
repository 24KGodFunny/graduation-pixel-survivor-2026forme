package com.pixelsurvivor.controller;

import com.pixelsurvivor.common.annotation.RateLimit;
import com.pixelsurvivor.common.result.Result;
import com.pixelsurvivor.dto.SyncDownloadVO;
import com.pixelsurvivor.dto.SyncUploadDTO;
import com.pixelsurvivor.service.SyncService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 游戏端 - 数据同步控制器
 * <p>处理游戏进度的云端上传和下载，实现多设备数据同步。
 * 所有存档数据以 JSON 形式存储在 t_user_save_data 表中，
 * userId 由 GameAuthInterceptor 从 JWT 中解析注入</p>
 *
 * @author PixelSurvivor
 */
@RestController
@RequestMapping("/api/game/sync")
@RequiredArgsConstructor
public class GameSyncController {

    private final SyncService syncService;

    /**
     * 上传本地存档到服务器
     * 将客户端全部游戏进度（角色、地图、成就、货币等）序列化为 JSON 覆盖写入数据库，
     * 使用 Redisson 分布式锁防止同一用户并发上传导致数据损坏
     */
    @RateLimit(maxRequests = 100)
    @PostMapping("/upload")
    public Result<?> upload(@RequestAttribute Long userId, @RequestBody SyncUploadDTO data) {
        syncService.upload(userId, data);
        return Result.success("数据上传成功");
    }

    /**
     * 从服务器下载存档到本地
     * 查询 t_user_save_data 表，将 JSON 反序列化后返回给客户端覆盖本地数据
     */
    @PostMapping("/download")
    public Result<SyncDownloadVO> download(@RequestAttribute Long userId) {
        SyncDownloadVO data = syncService.download(userId);
        return Result.success(data);
    }
}