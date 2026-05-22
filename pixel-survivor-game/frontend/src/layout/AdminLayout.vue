<template>
  <el-container class="layout-container">
    <!-- 左侧导航栏：固定 220px 宽度 -->
    <el-aside width="220px" class="layout-aside">
      <!-- Logo 区域：游戏图标 + 标题 + 浮动动画 -->
      <div class="logo-area">
        <div class="logo-icon">🎮</div>
        <h3>像素幸存者</h3>
        <p>管理后台</p>
      </div>
      <!-- 导航菜单：default-active 绑定当前路由路径实现高亮，router 属性使菜单项自动成为路由链接 -->
      <el-menu
        :default-active="route.path"
        class="aside-menu"
        router
      >
        <el-menu-item index="/dashboard">
          <el-icon><DataAnalysis /></el-icon>
          <span>数据概览</span>
        </el-menu-item>
        <el-menu-item index="/users">
          <el-icon><User /></el-icon>
          <span>用户管理</span>
        </el-menu-item>
        <el-menu-item index="/user-data">
          <el-icon><Box /></el-icon>
          <span>用户数据管理</span>
        </el-menu-item>
        <el-menu-item index="/logs">
          <el-icon><Document /></el-icon>
          <span>操作日志</span>
        </el-menu-item>
        <el-menu-item index="/admins">
          <el-icon><UserFilled /></el-icon>
          <span>管理员管理</span>
        </el-menu-item>
        <el-menu-item index="/profile">
          <el-icon><Setting /></el-icon>
          <span>我的</span>
        </el-menu-item>
      </el-menu>
    </el-aside>

    <!-- 右侧主内容区域 -->
    <el-container>
      <!-- 顶部标题栏：显示当前页面标题 + 用户名 + 退出按钮 -->
      <el-header class="layout-header">
        <h4>{{ route.meta.title }}</h4>
        <div class="header-right">
          <span class="admin-name">🛡️ {{ adminStore.username }}</span>
          <el-button type="danger" size="small" @click="handleLogout">退出登录</el-button>
        </div>
      </el-header>

      <!-- 主内容区：通过 router-view 渲染子路由页面 -->
      <el-main class="layout-main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { useRoute, useRouter } from 'vue-router'
import { useAdminStore } from '../stores/admin'

const route = useRoute()
const router = useRouter()
const adminStore = useAdminStore()

/**
 * 退出登录
 * 流程：调用 store.logout() 清除 token/用户信息（含 localStorage），然后跳转到登录页
 * 注意：不需要调用后端接口，只是前端清除认证状态
 * 路由守卫（router/index.js 的 beforeEach）会检测到无 token 并拦截回 /login
 */
function handleLogout() {
  adminStore.logout()
  router.push('/login')
}
</script>

<style scoped>
/* 全屏布局容器：深色背景 */
.layout-container {
  height: 100vh;
  background: #0a0820;
}

/* 侧边栏：纵向渐变深色背景，右侧细边框分隔 */
.layout-aside {
  background: linear-gradient(180deg, #12102a 0%, #0e0c22 100%);
  border-right: 1px solid rgba(100, 80, 200, 0.1);
  overflow-y: auto;
}

/* Logo 区域样式 */
.logo-area {
  padding: 24px 16px 16px;
  text-align: center;
  border-bottom: 1px solid rgba(100, 80, 200, 0.1);
}

.logo-icon {
  font-size: 40px;
  margin-bottom: 8px;
  /* 浮动动画：3 秒一个周期，永续 */
  animation: float 3s ease-in-out infinite;
}

@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-6px); }
}

.logo-area h3 {
  color: #d4d0e8;
  margin: 0;
  font-size: 16px;
  font-weight: 700;
  letter-spacing: 2px;
}

.logo-area p {
  color: #6b5f8a;
  font-size: 11px;
  margin-top: 4px;
}

/* 菜单容器：透明背景，无右边框 */
.aside-menu {
  border-right: none;
  background: transparent;
  padding: 8px 0;
}

/* 菜单项默认样式 */
.aside-menu :deep(.el-menu-item) {
  color: #8a80a8;
  height: 48px;
  line-height: 48px;
  margin: 2px 8px;
  border-radius: 8px;
  transition: all 0.2s;
}

/* 菜单项 hover 态 */
.aside-menu :deep(.el-menu-item:hover) {
  background: rgba(100, 80, 200, 0.1);
  color: #d4d0e8;
}

/* 菜单项激活态：蓝紫渐变背景 + 亮紫色文字 + 加粗 */
.aside-menu :deep(.el-menu-item.is-active) {
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.2), rgba(139, 92, 246, 0.2));
  color: #a78bfa;
  font-weight: 600;
}

/* 顶部标题栏：flex 两端对齐，固定 56px 高度 */
.layout-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: rgba(18, 16, 42, 0.8);
  border-bottom: 1px solid rgba(100, 80, 200, 0.1);
  padding: 0 24px;
  height: 56px;
}

.layout-header h4 {
  margin: 0;
  color: #d4d0e8;
  font-size: 16px;
  font-weight: 600;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 16px;
}

.admin-name {
  color: #818cf8;
  font-size: 13px;
  font-weight: 500;
}

/* 主内容区：深色背景 + 内边距 + 纵向滚动 */
.layout-main {
  background: #0a0820;
  padding: 20px;
  overflow-y: auto;
}
</style>