package com.pixelsurvivor;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * 密码编码器测试类
 * <p>用于生成 BCrypt 加密后的密码哈希值，
 * 可将生成的哈希值直接插入数据库 t_admin 表中用于测试登录</p>
 *
 * @author PixelSurvivor
 */
@SpringBootTest
public class PasswordEncoderTest {

    @Autowired
    private PasswordEncoder passwordEncoder;

    /**
     * 测试生成管理员密码的 BCrypt 哈希值
     * <p>运行此测试后，将控制台输出的哈希值复制到 SQL 的 INSERT 语句中</p>
     */
    @Test
    public void testEncodePassword() {
        // 测试常用密码
        String[] passwords = {"admin123", "123456", "password"};

        System.out.println("========== BCrypt 密码哈希值 ==========");
        for (String pwd : passwords) {
            String encoded = passwordEncoder.encode(pwd);
            System.out.println("原始密码: " + pwd + " -> BCrypt哈希: " + encoded);
        }
        System.out.println("======================================");

        // 验证匹配
        String adminHash = passwordEncoder.encode("admin123");
        System.out.println("\n验证 admin123 匹配结果: " + passwordEncoder.matches("admin123", adminHash));
    }
}