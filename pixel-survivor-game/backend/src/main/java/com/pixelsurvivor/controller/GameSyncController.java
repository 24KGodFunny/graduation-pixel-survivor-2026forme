package com.pixelsurvivor.controller;

import com.pixelsurvivor.common.result.Result;
import com.pixelsurvivor.dto.SyncDownloadVO;
import com.pixelsurvivor.dto.SyncUploadDTO;
import com.pixelsurvivor.service.SyncService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 游戏端 - 数据同步控制器
 */
@RestController
@RequestMapping("/api/game/sync")
@RequiredArgsConstructor
public class GameSyncController {

    private final SyncService syncService;

    /**
     * 上传本地数据到服务器
     */
    @PostMapping("/upload")
    public Result<?> upload(@RequestAttribute Long userId, @RequestBody SyncUploadDTO data) {
        syncService.upload(userId, data);
        return Result.success("数据上传成功");
    }

    /**
     * 从服务器下载数据
     */
    @PostMapping("/download")
    public Result<SyncDownloadVO> download(@RequestAttribute Long userId) {
        SyncDownloadVO data = syncService.download(userId);
        return Result.success(data);
    }
}