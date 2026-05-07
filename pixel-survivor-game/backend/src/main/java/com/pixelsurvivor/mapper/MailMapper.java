package com.pixelsurvivor.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.pixelsurvivor.entity.Mail;
import org.apache.ibatis.annotations.Mapper;

/**
 * 邮件Mapper
 */
@Mapper
public interface MailMapper extends BaseMapper<Mail> {
}