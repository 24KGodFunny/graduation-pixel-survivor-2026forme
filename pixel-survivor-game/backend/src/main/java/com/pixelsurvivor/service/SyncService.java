package com.pixelsurvivor.service;

import com.pixelsurvivor.dto.SyncDownloadVO;
import com.pixelsurvivor.dto.SyncUploadDTO;

/**
 * 数据同步服务接口
 */
public interface SyncService {

    /**
     * 上传本地数据到服务器
     */
    void upload(Long userId, SyncUploadDTO data);

    /**
     * 从服务器下载数据
     */
    SyncDownloadVO download(Long userId);
}