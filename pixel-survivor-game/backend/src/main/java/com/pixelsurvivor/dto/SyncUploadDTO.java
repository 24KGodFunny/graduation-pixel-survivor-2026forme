package com.pixelsurvivor.dto;

import lombok.Data;

import java.util.Map;

/**
 * 数据同步上传请求DTO
 * <p>前端将 GlobalSave 的全部数据序列化为 JSON 传入</p>
 */
@Data
public class SyncUploadDTO {

    /**
     * 存档数据（前端 GlobalSave.to_dict() 的完整 JSON）
     */
    private Map<String, Object> saveData;
}