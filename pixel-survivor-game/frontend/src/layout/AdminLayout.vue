<template>
  <el-container class="layout-container">
    <el-aside width="220px" class="layout-aside">
      <div class="logo-area">
        <div class="logo-icon">🎮</div>
        <h3>像素幸存者</h3>
        <p>管理后台</p>
      </div>
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
    <el-container>
      <el-header class="layout-header">
        <h4>{{ route.meta.title }}</h4>
        <div class="header-right">
          <span class="admin-name">🛡️ {{ adminStore.username }}</span>
          <el-button type="danger" size="small" @click="handleLogout">退出登录</el-button>
        </div>
      </el-header>
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

function handleLogout() {
  adminStore.logout()
  router.push('/login')
}
</script>

<style scoped>
.layout-container {
  height: 100vh;
  background: #0a0820;
}

.layout-aside {
  background: linear-gradient(180deg, #12102a 0%, #0e0c22 100%);
  border-right: 1px solid rgba(100, 80, 200, 0.1);
  overflow-y: auto;
}

.logo-area {
  padding: 24px 16px 16px;
  text-align: center;
  border-bottom: 1px solid rgba(100, 80, 200, 0.1);
}

.logo-icon {
  font-size: 40px;
  margin-bottom: 8px;
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

.aside-menu {
  border-right: none;
  background: transparent;
  padding: 8px 0;
}

.aside-menu :deep(.el-menu-item) {
  color: #8a80a8;
  height: 48px;
  line-height: 48px;
  margin: 2px 8px;
  border-radius: 8px;
  transition: all 0.2s;
}

.aside-menu :deep(.el-menu-item:hover) {
  background: rgba(100, 80, 200, 0.1);
  color: #d4d0e8;
}

.aside-menu :deep(.el-menu-item.is-active) {
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.2), rgba(139, 92, 246, 0.2));
  color: #a78bfa;
  font-weight: 600;
}

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

.layout-main {
  background: #0a0820;
  padding: 20px;
  overflow-y: auto;
}
</style>