package com.pixelsurvivor.common.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * JWT令牌工具类
 * <p>负责游戏端和管理端Token的生成、解析与验证，
 * 使用HMAC-SHA256算法签名，游戏端和管理端Token过期时间独立配置</p>
 *
 * @author PixelSurvivor
 */
@Component
public class JwtUtil {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.game-token-expire}")
    private long gameTokenExpire;

    @Value("${jwt.admin-token-expire}")
    private long adminTokenExpire;

    /**
     * 根据配置的密钥字符串生成 HMAC-SHA256 签名密钥
     * 面试重点：JWT 签名使用 HMAC-SHA256 算法，攻击者不知道 secret 就无法伪造签名。
     * 即使修改了 Payload 重新 Base64 编码，服务端验签时会发现签名不匹配而拒绝。
     */
    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    /**
     * 生成游戏端Token
     */
    public String generateGameToken(Long userId, String username) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", userId);
        claims.put("username", username);
        claims.put("type", "game");
        return createToken(claims, gameTokenExpire);
    }

    /**
     * 生成管理端Token
     */
    public String generateAdminToken(Long adminId, String username, String role) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("adminId", adminId);
        claims.put("username", username);
        claims.put("role", role);
        claims.put("type", "admin");
        return createToken(claims, adminTokenExpire);
    }

    private String createToken(Map<String, Object> claims, long expireSeconds) {
        Date now = new Date();
        Date expiration = new Date(now.getTime() + expireSeconds * 1000);
        return Jwts.builder()
                .claims(claims)
                .issuedAt(now)
                .expiration(expiration)
                .signWith(getSigningKey())
                .compact();
    }

    /**
     * 解析Token
     */
    public Claims parseToken(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    /**
     * 验证Token是否有效
     */
    public boolean validateToken(String token) {
        try {
            Claims claims = parseToken(token);
            return !claims.getExpiration().before(new Date());
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 从Token获取用户ID
     */
    public Long getUserId(String token) {
        Claims claims = parseToken(token);
        return claims.get("userId", Long.class);
    }

    /**
     * 从Token获取管理员ID
     */
    public Long getAdminId(String token) {
        Claims claims = parseToken(token);
        return claims.get("adminId", Long.class);
    }

    /**
     * 获取Token类型 (game/admin)
     */
    public String getTokenType(String token) {
        Claims claims = parseToken(token);
        return claims.get("type", String.class);
    }

    /**
     * 获取Token过期时间(秒)
     */
    public long getGameTokenExpire() {
        return gameTokenExpire;
    }

    public long getAdminTokenExpire() {
        return adminTokenExpire;
    }
}