package com.pixelsurvivor.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.pixelsurvivor.entity.UserDailyTask;
import org.apache.ibatis.annotations.Mapper;

/**
 * 用户每日任务Mapper
 */
@Mapper
public interface UserDailyTaskMapper extends BaseMapper<UserDailyTask> {
}