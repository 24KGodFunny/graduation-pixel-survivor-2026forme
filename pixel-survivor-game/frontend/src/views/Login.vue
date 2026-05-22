<template>
  <div class="login-container">
    <!-- 黑洞动画背景 Canvas -->
    <canvas ref="canvasRef" class="blackhole-canvas"></canvas>

    <!-- 登录表单卡片：初始隐藏，通过 cardVisible 控制淡入动画 -->
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
          <!-- 登录按钮：loading 状态时显示"登录中..."并禁用 -->
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
/* 控制登录卡片淡入动画：页面挂载后设置为 true，触发 CSS transition */
const cardVisible = ref(false)

const loginForm = reactive({
  username: '',
  password: ''
})

const rules = {
  username: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
}

/**
 * 处理登录表单提交
 * 流程：表单校验 -> 调用登录 API -> 存储 token/用户信息到 Pinia + localStorage -> 跳转仪表盘
 * 错误处理：区分业务错误（res.code !== 200）和网络错误（catch）
 */
const handleLogin = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  loading.value = true
  try {
    const res = await login(loginForm)

    if (res.code === 200) {
      // 登录成功：将 token、用户名、角色写入 Pinia store（自动同步 localStorage）
      adminStore.setLoginInfo(res.data)
      ElMessage.success('登录成功')
      router.push('/dashboard')
    } else {
      ElMessage.error(res.message || '登录失败')
    }
  } catch (err) {
    // 网络异常或 HTTP 错误（如 401），优先显示后端返回的错误信息
    ElMessage.error(err.response?.data?.message || '登录失败，请检查网络')
  } finally {
    loading.value = false
  }
}

// ==================== 黑洞动画（Canvas 2D） ====================

let animationId = null

onMounted(() => {
  cardVisible.value = true  // 触发登录卡片淡入过渡动画
  initBlackhole()           // 启动黑洞 Canvas 动画
})

onUnmounted(() => {
  // 组件销毁时取消动画帧，防止内存泄漏
  if (animationId) cancelAnimationFrame(animationId)
})

/**
 * 初始化并启动黑洞粒子动画
 *
 * 整体动画架构：
 * 1. 800 颗背景星星 —— 分布在画布各处，受"引力透镜"效果影响发生位置偏移
 * 2. 200 个吸积盘粒子 —— 围绕黑洞中心做椭圆轨道运动
 * 3. 事件视界光晕 —— 多层径向渐变模拟黑洞周围的发光效果
 * 4. 黑洞核心 —— 纯黑渐变核心 + 光子球边缘脉冲描边
 * 5. 随机光点闪烁 —— 模拟吸积盘中的高能粒子闪光
 *
 * 每一帧执行顺序：半透明黑色覆盖（拖尾效果）-> 吸积盘 -> 光晕 -> 核心 -> 光子球 -> 星星 -> 闪光 -> requestAnimationFrame 递归
 */
function initBlackhole() {
  const canvas = canvasRef.value
  if (!canvas) return
  const ctx = canvas.getContext('2d')

  // Canvas 尺寸设为窗口大小，实现全屏背景
  let width = canvas.width = window.innerWidth
  let height = canvas.height = window.innerHeight

  // 黑洞中心位置：水平偏左 30%，垂直居中，为右侧登录表单留出空间
  const centerX = width * 0.3
  const centerY = height / 2

  // ==================== 1. 背景星星粒子系统 ====================
  const stars = []
  const STAR_COUNT = 800  // 星星总数，越多视觉效果越密集

  for (let i = 0; i < STAR_COUNT; i++) {
    // 随机角度和距离，以黑洞中心为原点呈圆形分布
    const angle = Math.random() * Math.PI * 2
    const distance = Math.random() * Math.max(width, height)
    stars.push({
      // 当前绘制坐标（会被引力透镜效果修改）
      x: centerX + Math.cos(angle) * distance,
      y: centerY + Math.sin(angle) * distance,
      // 原始坐标（用于计算引力透镜偏移量）
      originX: centerX + Math.cos(angle) * distance,
      originY: centerY + Math.sin(angle) * distance,
      size: Math.random() * 2 + 0.5,       // 星星半径 0.5~2.5px
      speed: Math.random() * 0.5 + 0.1,    // 未使用的保留字段
      angle: angle,
      distance: distance,
      opacity: Math.random() * 0.8 + 0.2,   // 透明度 0.2~1.0
      color: Math.random() > 0.7
        // 约 30% 的星星使用蓝紫色调（色相 200~260），靠近黑洞时更显科技感
        ? `hsl(${200 + Math.random() * 60}, 80%, ${60 + Math.random() * 30}%)`
        // 其余 70% 使用随机色相，增加星空丰富度
        : `hsl(${Math.random() * 360}, ${20 + Math.random() * 30}%, ${70 + Math.random() * 30}%)`
    })
  }

  // ==================== 2. 吸积盘粒子系统 ====================
  const accretionParticles = []
  const ACCRETION_COUNT = 200  // 吸积盘粒子数量

  for (let i = 0; i < ACCRETION_COUNT; i++) {
    const angle = Math.random() * Math.PI * 2
    // 吸积盘半径范围：60~180px（事件视界半径 50px 的外围）
    const radius = 60 + Math.random() * 120
    accretionParticles.push({
      angle: angle,       // 当前轨道角度（弧度）
      radius: radius,     // 轨道半径
      // 内圈粒子（radius < 100）转速更快，模拟开普勒定律——越靠近黑洞公转越快
      speed: (0.005 + Math.random() * 0.015) * (radius < 100 ? 1.5 : 0.8),
      size: Math.random() * 2.5 + 0.5,  // 粒子半径 0.5~3.0px
      opacity: Math.random() * 0.6 + 0.2, // 透明度 0.2~0.8
      hue: 200 + Math.random() * 80       // 色相 200~280（蓝-紫色范围），形成蓝紫色吸积盘
    })
  }

  let time = 0  // 全局时间计数器，驱动周期性动画效果
  const eventHorizonRadius = 50   // 事件视界半径（黑洞可见边缘）
  const schwarzschildRadius = 30  // 史瓦西半径（用于光晕最内层渐变起点）

  /**
   * 每帧绘制函数（通过 requestAnimationFrame 循环调用）
   */
  function drawBlackhole() {
    // ---- 残影/拖尾效果 ----
    // 每帧用半透明黑色覆盖整个画布，使上一帧内容逐渐变暗消失
    // 透明度 0.15 控制拖尾长度：值越小拖尾越长，值越大画面越"干净"
    ctx.fillStyle = 'rgba(0, 0, 0, 0.15)'
    ctx.fillRect(0, 0, width, height)

    time += 0.01

    // ---- 绘制吸积盘粒子 ----
    for (const p of accretionParticles) {
      // 粒子沿轨道旋转
      p.angle += p.speed
      // 添加正弦扰动（wobble）：模拟吸积盘的不规则湍流
      const wobble = Math.sin(time * 2 + p.angle * 3) * 5
      const r = p.radius + wobble
      // 计算绘制坐标：Y 轴乘以 0.3 实现椭圆透视效果
      // 让吸积盘看起来是从侧面倾斜观察的，而非正上方俯视
      const x = centerX + Math.cos(p.angle) * r
      const y = centerY + Math.sin(p.angle) * r * 0.3 // 椭圆透视（压扁 Y 轴）

      // 根据粒子到黑洞中心的距离计算淡出系数
      // 越靠近事件视界越亮，远处粒子逐渐消失
      const distToCenter = Math.sqrt((x - centerX) ** 2 + (y - centerY) ** 2)
      const fadeFactor = Math.max(0, 1 - distToCenter / (eventHorizonRadius * 3))

      // 每个粒子使用径向渐变绘制光晕，而非实心圆
      const gradient = ctx.createRadialGradient(x, y, 0, x, y, p.size * 2)
      gradient.addColorStop(0, `hsla(${p.hue}, 80%, 70%, ${p.opacity * fadeFactor})`)
      gradient.addColorStop(1, `hsla(${p.hue}, 80%, 50%, 0)`)

      ctx.beginPath()
      ctx.arc(x, y, p.size * 2, 0, Math.PI * 2)
      ctx.fillStyle = gradient
      ctx.fill()
    }

    // ---- 绘制事件视界外层光晕 ----
    // 三层径向渐变，从内到外：紫色 -> 蓝色 -> 橙红色 -> 透明
    // glowSize 随时间正弦波动（±10px），营造"呼吸"感
    const glowSize = eventHorizonRadius * 3 + Math.sin(time * 3) * 10
    const outerGlow = ctx.createRadialGradient(
      centerX, centerY, schwarzschildRadius,  // 内圈起点：史瓦西半径处
      centerX, centerY, glowSize              // 外圈终点：波动的事件视界 3 倍半径
    )
    outerGlow.addColorStop(0, 'rgba(100, 50, 200, 0.3)')    // 内圈紫色
    outerGlow.addColorStop(0.3, 'rgba(50, 100, 255, 0.15)') // 中间蓝色
    outerGlow.addColorStop(0.6, 'rgba(255, 100, 50, 0.05)') // 外围橙红（极稀薄）
    outerGlow.addColorStop(1, 'rgba(0, 0, 0, 0)')           // 完全透明

    ctx.beginPath()
    ctx.arc(centerX, centerY, glowSize, 0, Math.PI * 2)
    ctx.fillStyle = outerGlow
    ctx.fill()

    // ---- 绘制黑洞核心（纯黑球体） ----
    // 事件视界内部：从完全黑色渐变到深紫色边缘
    const coreGradient = ctx.createRadialGradient(
      centerX, centerY, 0,                    // 圆心：完全不透明黑色
      centerX, centerY, eventHorizonRadius     // 边缘：带紫色调的半透明深色
    )
    coreGradient.addColorStop(0, 'rgba(0, 0, 0, 1)')        // 核心纯黑
    coreGradient.addColorStop(0.7, 'rgba(0, 0, 0, 0.98)')  // 过渡区几乎全黑
    coreGradient.addColorStop(1, 'rgba(10, 5, 30, 0.9)')   // 事件视界边缘带暗紫色光晕

    ctx.beginPath()
    ctx.arc(centerX, centerY, eventHorizonRadius, 0, Math.PI * 2)
    ctx.fillStyle = coreGradient
    ctx.fill()

    // ---- 绘制光子球边缘（事件视界外的亮环） ----
    // 在事件视界外 2px 处画一圈脉冲亮度描边
    // 透明度随时间正弦波动，模拟光子球的能量振荡
    ctx.beginPath()
    ctx.arc(centerX, centerY, eventHorizonRadius + 2, 0, Math.PI * 2)
    ctx.strokeStyle = `hsla(260, 80%, 60%, ${0.3 + Math.sin(time * 4) * 0.15})`
    ctx.lineWidth = 2
    ctx.stroke()

    // ---- 绘制背景星星（带引力透镜效果） ----
    for (const star of stars) {
      const dx = star.x - centerX
      const dy = star.y - centerY
      const dist = Math.sqrt(dx * dx + dy * dy)

      // 引力透镜弯曲计算：
      // bendFactor 表示光线弯曲程度，靠近黑洞时接近 1，远离时为 0
      // 公式：min(1, 4倍事件视界半径 / 当前距离)
      // 即距离小于 4 倍事件视界半径时开始产生明显弯曲
      const bendFactor = Math.min(1, (eventHorizonRadius * 4) / Math.max(dist, 1))
      // 弯曲角度：最大弯曲 0.5 弧度（约 28.6 度）
      const bendAngle = bendFactor * 0.5

      // 计算弯曲后的新角度和距离
      // 光线向黑洞方向偏折，所以角度增大；距离被轻微"拉伸"
      const newAngle = Math.atan2(dy, dx) + bendAngle
      const newDist = dist * (1 - bendFactor * 0.1)

      // 使用弯曲后的坐标绘制星星
      const drawX = centerX + Math.cos(newAngle) * newDist
      const drawY = centerY + Math.sin(newAngle) * newDist

      // 位于事件视界 1.5 倍半径内的星星被黑洞"吞噬"，不绘制
      // 这模拟了事件视界后的星星不可见
      if (dist < eventHorizonRadius * 1.5) continue

      // 靠近黑洞的星星绘制蓝色拖尾（吸积盘物质发光效果）
      if (dist < eventHorizonRadius * 5) {
        // 拖尾长度：离黑洞越近拖尾越长（0~8px）
        const tailLength = (1 - dist / (eventHorizonRadius * 5)) * 8
        ctx.beginPath()
        ctx.moveTo(drawX, drawY)
        // 拖尾方向：与弯曲角度方向相反（指向远离黑洞的方向）
        ctx.lineTo(
          drawX - Math.cos(newAngle) * tailLength,
          drawY - Math.sin(newAngle) * tailLength
        )
        ctx.strokeStyle = `hsla(220, 80%, 70%, ${star.opacity * 0.3})`
        ctx.lineWidth = star.size * 0.5
        ctx.stroke()
      }

      // 绘制星星本体
      // 将 HSL 颜色字符串转换为 HSLA 格式以支持透明度
      ctx.beginPath()
      ctx.arc(drawX, drawY, star.size, 0, Math.PI * 2)
      ctx.fillStyle = star.color.replace(')', `, ${star.opacity})`).replace('hsl', 'hsla')
      ctx.fill()
    }

    // ---- 随机光点闪烁效果 ----
    // 每帧有 2% 概率在事件视界附近生成一个随机闪光点
    // 模拟吸积盘中高能粒子碰撞产生的瞬时光亮
    if (Math.random() < 0.02) {
      const flashAngle = Math.random() * Math.PI * 2
      const flashDist = eventHorizonRadius * 2 + Math.random() * 30  // 距离黑洞中心 100~130px
      const fx = centerX + Math.cos(flashAngle) * flashDist
      const fy = centerY + Math.sin(flashAngle) * flashDist

      // 用径向渐变绘制，中心白紫色、边缘透明
      const flashGrad = ctx.createRadialGradient(fx, fy, 0, fx, fy, 8)
      flashGrad.addColorStop(0, 'rgba(180, 150, 255, 0.8)')
      flashGrad.addColorStop(1, 'rgba(180, 150, 255, 0)')
      ctx.beginPath()
      ctx.arc(fx, fy, 8, 0, Math.PI * 2)
      ctx.fillStyle = flashGrad
      ctx.fill()
    }

    // 递归调用自身，形成无限动画循环
    // requestAnimationFrame 会自动以显示器刷新率（通常 60fps）调度
    animationId = requestAnimationFrame(drawBlackhole)
  }

  // 启动动画循环
  drawBlackhole()

  // 监听窗口尺寸变化，同步更新 Canvas 大小
  window.addEventListener('resize', () => {
    width = canvas.width = window.innerWidth
    height = canvas.height = window.innerHeight
  })
}
</script>

<style scoped>
/* 登录页全屏容器：flex 布局将表单靠右放置 */
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

/* Canvas 覆盖全屏作为背景层（z-index: 1） */
.blackhole-canvas {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 1;
}

/* 登录卡片：半透明深色背景 + 毛玻璃模糊效果 + 紫色边框光晕 */
.login-card {
  position: relative;
  z-index: 10;
  width: 400px;
  padding: 40px;
  background: rgba(10, 8, 30, 0.75);
  /* backdrop-filter 实现毛玻璃效果：对卡片后面的 Canvas 内容做模糊处理 */
  backdrop-filter: blur(20px);
  border: 1px solid rgba(100, 80, 200, 0.3);
  border-radius: 16px;
  /* 多层 box-shadow 模拟外发光和内发光 */
  box-shadow:
    0 0 40px rgba(80, 50, 200, 0.15),
    0 0 80px rgba(50, 30, 150, 0.1),
    inset 0 0 30px rgba(80, 50, 200, 0.05);
  /* 初始状态：透明、下移 30px、缩小 95%，配合 card-visible 实现入场动画 */
  opacity: 0;
  transform: translateY(30px) scale(0.95);
  transition: all 0.8s cubic-bezier(0.16, 1, 0.3, 1);
}

/* card-visible 激活时：淡入 + 上移 + 复原大小 */
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
  /* 给图标添加紫色发光投影 */
  filter: drop-shadow(0 0 10px rgba(150, 100, 255, 0.5));
}

.login-title {
  font-family: 'Courier New', monospace;
  font-size: 28px;
  font-weight: 900;
  letter-spacing: 4px;
  /* 渐变色文字：紫 -> 蓝 -> 紫，使用 background-clip 实现 */
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

/* Element Plus 输入框深度样式定制 */
.login-form :deep(.el-input__wrapper) {
  background: rgba(20, 15, 50, 0.6);
  border: 1px solid rgba(100, 80, 200, 0.2);
  border-radius: 8px;
  box-shadow: none;
  transition: all 0.3s ease;
}

/* 输入框 hover/focus 时边框高亮 + 外发光 */
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

/* 登录按钮：紫色渐变背景 */
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

/* 像素风边框装饰：卡片顶部渐变光线 */
.login-card::before {
  content: '';
  position: absolute;
  top: -1px;
  left: 20px;
  right: 20px;
  height: 2px;
  background: linear-gradient(90deg, transparent, rgba(160, 120, 255, 0.6), transparent);
}

/* 像素风边框装饰：卡片底部渐变光线 */
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