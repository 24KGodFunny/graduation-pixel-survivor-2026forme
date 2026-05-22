<template>
  <div>
    <h2 style="margin-bottom: 20px">注册管理员</h2>
    <el-card style="max-width: 500px">
      <!-- @submit.prevent 阻止表单默认提交行为 -->
      <el-form :model="form" @submit.prevent="handleRegister" label-width="80px">
        <el-form-item label="用户名">
          <el-input v-model="form.username" placeholder="请输入用户名" />
        </el-form-item>
        <el-form-item label="密码">
          <el-input v-model="form.password" type="password" placeholder="请输入密码" show-password />
        </el-form-item>
        <el-form-item label="确认密码">
          <el-input v-model="form.confirmPassword" type="password" placeholder="请再次输入密码" show-password />
        </el-form-item>
        <el-form-item label="角色">
          <el-select v-model="form.role" style="width: 100%">
            <el-option label="普通管理员" value="ADMIN" />
            <el-option label="超级管理员" value="SUPER_ADMIN" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <!-- native-type="submit" 配合 @submit.prevent 处理回车提交 -->
          <el-button type="primary" style="width: 100%" :loading="loading" native-type="submit">注 册</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { registerAdmin } from '../api/admin'

const loading = ref(false)
const form = reactive({
  username: '',
  password: '',
  confirmPassword: '',
  role: 'ADMIN'  // 默认注册为普通管理员
})

/**
 * 注册新管理员
 *
 * 前端校验三步（与 AdminManage.vue 的对话框注册逻辑一致）：
 * 1. 用户名和密码非空
 * 2. 两次密码一致
 * 3. 密码长度 >= 6
 *
 * 成功后清空表单允许继续注册
 * 注意：这是独立的注册页面，与 AdminManage.vue 对话框中的注册功能是平行的入口
 */
async function handleRegister() {
  if (!form.username || !form.password) {
    ElMessage.warning('请输入用户名和密码')
    return
  }
  if (form.password !== form.confirmPassword) {
    ElMessage.warning('两次输入的密码不一致')
    return
  }
  if (form.password.length < 6) {
    ElMessage.warning('密码长度不能少于6位')
    return
  }
  loading.value = true
  try {
    await registerAdmin({
      username: form.username,
      password: form.password,
      role: form.role
    })
    ElMessage.success('管理员注册成功')
    // 清空表单，方便连续注册
    form.username = ''
    form.password = ''
    form.confirmPassword = ''
    form.role = 'ADMIN'
  } catch (e) {
    // 错误由 request.js 响应拦截器统一处理（ElMessage + 401 跳转），此处无需额外处理
  } finally {
    loading.value = false
  }
}
</script>