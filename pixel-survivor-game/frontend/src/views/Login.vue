<template>
  <div class="login-container">
    <!-- 黑洞动画背景 -->
    <canvas ref="canvasRef" class="blackhole-canvas"></canvas>
    
    <!-- 登录表单 -->
    <div class="login-card" :class="{ 'card-visible': cardVisible }">
      <div class="login-header">
        <div class="pixel-icon">⚔️</div>
        <h1 class="login-title">PIXEL SURVIVOR</h1>
        <p class="login-subtitle">管理员控制台</p>
      </div>
      
      <el-form
        ref="formRef"
        :model="loginForm"
        :rules="rules"
        class="login-form"
        @keyup.enter="handleLogin"
      >
        <el-form-item prop="username">
          <el-input
            v-model="loginForm.username"
            placeholder="请输入用户名"
            prefix-icon="User"
            size="large"
            class="pixel-input"
          />
        </el-form-item>
        
        <el-form-item prop="password">
          <el-input
            v-model="loginForm.password"
            type="password"
            placeholder="请输入密码"
            prefix-icon="Lock"
            size="large"
            show-password
            class="pixel-input"
          />
        </el-form-item>
        
        <el-form-item>
          <el-button
            type="primary"
            size="large"
            class="login-btn"
            :loading="loading"
            @click="handleLogin"
          >
            {{ loading ? '登录中...' : '登 录' }}
          </el-button>
        </el-form-item>
      </el-form>
      
      <div class="login-footer">
        <span class="pixel-text">🎮 Pixel Survivor Admin v1.0</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { login } from '../api/admin'
import { useAdminStore } from '../stores/admin'

const router = useRouter()
const adminStore = useAdminStore()
const formRef = ref(null)
const canvasRef = ref(null)
const loading = ref(false)
const cardVisible = ref(false)

const loginForm = reactive({
  username: '',
  password: ''
})

const rules = {
  username: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
}

const handleLogin = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  
  loading.value = true
  try {
    const res = await login(loginForm)

    if (res.code === 200) {
      adminStore.setLoginInfo(res.data)
      ElMessage.success('登录成功')
      router.push('/dashboard')
    } else {
      ElMessage.error(res.message || '登录失败')
    }
  } catch (err) {
    ElMessage.error(err.response?.data?.message || '登录失败，请检查网络')
  } finally {
    loading.value = false
  }
}

// ==================== 黑洞动画 ====================
let animationId = null

onMounted(() => {
  cardVisible.value = true
  initBlackhole()
})

onUnmounted(() => {
  if (animationId) cancelAnimationFrame(animationId)
})

function initBlackhole() {
  const canvas = canvasRef.value
  if (!canvas) return
  const ctx = canvas.getContext('2d')
  
  let width = canvas.width = window.innerWidth
  let height = canvas.height = window.innerHeight
  
  const centerX = width * 0.3
  const centerY = height / 2
  
  // 星星粒子
  const stars = []
  const STAR_COUNT = 800
  
  for (let i = 0; i < STAR_COUNT; i++) {
    const angle = Math.random() * Math.PI * 2
    const distance = Math.random() * Math.max(width, height)
    stars.push({
      x: centerX + Math.cos(angle) * distance,
      y: centerY + Math.sin(angle) * distance,
      originX: centerX + Math.cos(angle) * distance,
      originY: centerY + Math.sin(angle) * distance,
      size: Math.random() * 2 + 0.5,
      speed: Math.random() * 0.5 + 0.1,
      angle: angle,
      distance: distance,
      opacity: Math.random() * 0.8 + 0.2,
      color: Math.random() > 0.7 
        ? `hsl(${200 + Math.random() * 60}, 80%, ${60 + Math.random() * 30}%)`
        : `hsl(${Math.random() * 360}, ${20 + Math.random() * 30}%, ${70 + Math.random() * 30}%)`
    })
  }
  
  // 吸积盘粒子
  const accretionParticles = []
  const ACCRETION_COUNT = 200
  
  for (let i = 0; i < ACCRETION_COUNT; i++) {
    const angle = Math.random() * Math.PI * 2
    const radius = 60 + Math.random() * 120
    accretionParticles.push({
      angle: angle,
      radius: radius,
      speed: (0.005 + Math.random() * 0.015) * (radius < 100 ? 1.5 : 0.8),
      size: Math.random() * 2.5 + 0.5,
      opacity: Math.random() * 0.6 + 0.2,
      hue: 200 + Math.random() * 80
    })
  }
  
  let time = 0
  const eventHorizonRadius = 50
  const schwarzschildRadius = 30
  
  function drawBlackhole() {
    ctx.fillStyle = 'rgba(0, 0, 0, 0.15)'
    ctx.fillRect(0, 0, width, height)
    
    time += 0.01
    
    // 绘制吸积盘
    for (const p of accretionParticles) {
      p.angle += p.speed
      const wobble = Math.sin(time * 2 + p.angle * 3) * 5
      const r = p.radius + wobble
      const x = centerX + Math.cos(p.angle) * r
      const y = centerY + Math.sin(p.angle) * r * 0.3 // 椭圆透视
      
      const distToCenter = Math.sqrt((x - centerX) ** 2 + (y - centerY) ** 2)
      const fadeFactor = Math.max(0, 1 - distToCenter / (eventHorizonRadius * 3))
      
      const gradient = ctx.createRadialGradient(x, y, 0, x, y, p.size * 2)
      gradient.addColorStop(0, `hsla(${p.hue}, 80%, 70%, ${p.opacity * fadeFactor})`)
      gradient.addColorStop(1, `hsla(${p.hue}, 80%, 50%, 0)`)
      
      ctx.beginPath()
      ctx.arc(x, y, p.size * 2, 0, Math.PI * 2)
      ctx.fillStyle = gradient
      ctx.fill()
    }
    
    // 绘制事件视界光晕
    const glowSize = eventHorizonRadius * 3 + Math.sin(time * 3) * 10
    const outerGlow = ctx.createRadialGradient(
      centerX, centerY, schwarzschildRadius,
      centerX, centerY, glowSize
    )
    outerGlow.addColorStop(0, 'rgba(100, 50, 200, 0.3)')
    outerGlow.addColorStop(0.3, 'rgba(50, 100, 255, 0.15)')
    outerGlow.addColorStop(0.6, 'rgba(255, 100, 50, 0.05)')
    outerGlow.addColorStop(1, 'rgba(0, 0, 0, 0)')
    
    ctx.beginPath()
    ctx.arc(centerX, centerY, glowSize, 0, Math.PI * 2)
    ctx.fillStyle = outerGlow
    ctx.fill()
    
    // 绘制黑洞核心（纯黑）
    const coreGradient = ctx.createRadialGradient(
      centerX, centerY, 0,
      centerX, centerY, eventHorizonRadius
    )
    coreGradient.addColorStop(0, 'rgba(0, 0, 0, 1)')
    coreGradient.addColorStop(0.7, 'rgba(0, 0, 0, 0.98)')
    coreGradient.addColorStop(1, 'rgba(10, 5, 30, 0.9)')
    
    ctx.beginPath()
    ctx.arc(centerX, centerY, eventHorizonRadius, 0, Math.PI * 2)
    ctx.fillStyle = coreGradient
    ctx.fill()
    
    // 绘制光子球边缘
    ctx.beginPath()
    ctx.arc(centerX, centerY, eventHorizonRadius + 2, 0, Math.PI * 2)
    ctx.strokeStyle = `hsla(260, 80%, 60%, ${0.3 + Math.sin(time * 4) * 0.15})`
    ctx.lineWidth = 2
    ctx.stroke()
    
    // 绘制背景星星（引力透镜效果）
    for (const star of stars) {
      const dx = star.x - centerX
      const dy = star.y - centerY
      const dist = Math.sqrt(dx * dx + dy * dy)
      
      // 引力透镜弯曲
      const bendFactor = Math.min(1, (eventHorizonRadius * 4) / Math.max(dist, 1))
      const bendAngle = bendFactor * 0.5
      
      const newAngle = Math.atan2(dy, dx) + bendAngle
      const newDist = dist * (1 - bendFactor * 0.1)
      
      const drawX = centerX + Math.cos(newAngle) * newDist
      const drawY = centerY + Math.sin(newAngle) * newDist
      
      // 被黑洞吞噬的星星不绘制
      if (dist < eventHorizonRadius * 1.5) continue
      
      // 星星拖尾（靠近黑洞的星星有蓝色拖尾）
      if (dist < eventHorizonRadius * 5) {
        const tailLength = (1 - dist / (eventHorizonRadius * 5)) * 8
        ctx.beginPath()
        ctx.moveTo(drawX, drawY)
        ctx.lineTo(
          drawX - Math.cos(newAngle) * tailLength,
          drawY - Math.sin(newAngle) * tailLength
        )
        ctx.strokeStyle = `hsla(220, 80%, 70%, ${star.opacity * 0.3})`
        ctx.lineWidth = star.size * 0.5
        ctx.stroke()
      }
      
      // 绘制星星
      ctx.beginPath()
      ctx.arc(drawX, drawY, star.size, 0, Math.PI * 2)
      ctx.fillStyle = star.color.replace(')', `, ${star.opacity})`).replace('hsl', 'hsla')
      ctx.fill()
    }
    
    // 偶尔闪烁的光点
    if (Math.random() < 0.02) {
      const flashAngle = Math.random() * Math.PI * 2
      const flashDist = eventHorizonRadius * 2 + Math.random() * 30
      const fx = centerX + Math.cos(flashAngle) * flashDist
      const fy = centerY + Math.sin(flashAngle) * flashDist
      
      const flashGrad = ctx.createRadialGradient(fx, fy, 0, fx, fy, 8)
      flashGrad.addColorStop(0, 'rgba(180, 150, 255, 0.8)')
      flashGrad.addColorStop(1, 'rgba(180, 150, 255, 0)')
      ctx.beginPath()
      ctx.arc(fx, fy, 8, 0, Math.PI * 2)
      ctx.fillStyle = flashGrad
      ctx.fill()
    }
    
    animationId = requestAnimationFrame(drawBlackhole)
  }
  
  drawBlackhole()
  
  window.addEventListener('resize', () => {
    width = canvas.width = window.innerWidth
    height = canvas.height = window.innerHeight
  })
}
</script>

<style scoped>
.login-container {
  position: relative;
  width: 100vw;
  height: 100vh;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding-right: 10%;
  overflow: hidden;
  background: #000;
}

.blackhole-canvas {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 1;
}

.login-card {
  position: relative;
  z-index: 10;
  width: 400px;
  padding: 40px;
  background: rgba(10, 8, 30, 0.75);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(100, 80, 200, 0.3);
  border-radius: 16px;
  box-shadow: 
    0 0 40px rgba(80, 50, 200, 0.15),
    0 0 80px rgba(50, 30, 150, 0.1),
    inset 0 0 30px rgba(80, 50, 200, 0.05);
  opacity: 0;
  transform: translateY(30px) scale(0.95);
  transition: all 0.8s cubic-bezier(0.16, 1, 0.3, 1);
}

.card-visible {
  opacity: 1;
  transform: translateY(0) scale(1);
}

.login-header {
  text-align: center;
  margin-bottom: 36px;
}

.pixel-icon {
  font-size: 48px;
  margin-bottom: 12px;
  filter: drop-shadow(0 0 10px rgba(150, 100, 255, 0.5));
}

.login-title {
  font-family: 'Courier New', monospace;
  font-size: 28px;
  font-weight: 900;
  letter-spacing: 4px;
  background: linear-gradient(135deg, #a78bfa, #60a5fa, #c084fc);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  text-shadow: none;
  margin: 0;
}

.login-subtitle {
  color: rgba(160, 150, 200, 0.7);
  font-size: 13px;
  margin-top: 8px;
  letter-spacing: 2px;
}

.login-form {
  margin-top: 20px;
}

.login-form :deep(.el-input__wrapper) {
  background: rgba(20, 15, 50, 0.6);
  border: 1px solid rgba(100, 80, 200, 0.2);
  border-radius: 8px;
  box-shadow: none;
  transition: all 0.3s ease;
}

.login-form :deep(.el-input__wrapper:hover),
.login-form :deep(.el-input__wrapper.is-focus) {
  border-color: rgba(120, 100, 220, 0.5);
  box-shadow: 0 0 15px rgba(100, 80, 200, 0.15);
}

.login-form :deep(.el-input__inner) {
  color: #d4d0e8;
  font-size: 14px;
}

.login-form :deep(.el-input__inner::placeholder) {
  color: rgba(140, 130, 180, 0.5);
}

.login-form :deep(.el-input__prefix .el-icon) {
  color: rgba(140, 120, 220, 0.6);
}

.login-btn {
  width: 100%;
  height: 44px;
  font-size: 15px;
  font-weight: 600;
  letter-spacing: 4px;
  border: none;
  border-radius: 8px;
  background: linear-gradient(135deg, #6d28d9, #4f46e5, #2563eb);
  transition: all 0.3s ease;
}

.login-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 20px rgba(99, 60, 220, 0.4);
}

.login-btn:active {
  transform: translateY(0);
}

.login-footer {
  text-align: center;
  margin-top: 24px;
}

.pixel-text {
  font-family: 'Courier New', monospace;
  font-size: 11px;
  color: rgba(120, 110, 170, 0.5);
  letter-spacing: 1px;
}

/* 像素风边框装饰 */
.login-card::before {
  content: '';
  position: absolute;
  top: -1px;
  left: 20px;
  right: 20px;
  height: 2px;
  background: linear-gradient(90deg, transparent, rgba(160, 120, 255, 0.6), transparent);
}

.login-card::after {
  content: '';
  position: absolute;
  bottom: -1px;
  left: 20px;
  right: 20px;
  height: 2px;
  background: linear-gradient(90deg, transparent, rgba(100, 150, 255, 0.4), transparent);
}
</style>