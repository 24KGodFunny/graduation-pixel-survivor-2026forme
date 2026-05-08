package com.pixelsurvivor.dto;

import lombok.Data;

/**
 * 数据同步下载响应VO
 * <p>直接返回存档JSON字符串，前端 GlobalSave.from_dict() 解析</p>
 */
@Data
public class SyncDownloadVO {

    /**
     * 存档JSON数据（前端 GlobalSave 的完整字典）
     */
    private Object saveData;
}