package com.pixelsurvivor;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * 像素幸存者 - 游戏后端服务启动类
 * <p>Spring Boot应用入口，启用MyBatis Mapper扫描和定时任务调度，
 * 启动后默认监听8080端口，提供游戏端和管理端REST API服务</p>
 *
 * @author PixelSurvivor
 */
@SpringBootApplication
@MapperScan("com.pixelsurvivor.mapper")
@EnableScheduling
public class PixelSurvivorApplication {

    public static void main(String[] args) {
        SpringApplication.run(PixelSurvivorApplication.class, args);
        System.out.println("============================================");
        System.out.println("   Pixel Survivor Backend Started!          ");
        System.out.println("   API Docs: http://localhost:8080/doc.html  ");
        System.out.println("============================================");
    }
}