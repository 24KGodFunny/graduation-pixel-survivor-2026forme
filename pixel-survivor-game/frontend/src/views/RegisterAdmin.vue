<template>
  <div>
    <h2 style="margin-bottom: 20px">注册管理员</h2>
    <el-card style="max-width: 500px">
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
  role: 'ADMIN'
})

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
    form.username = ''
    form.password = ''
    form.confirmPassword = ''
    form.role = 'ADMIN'
  } catch (e) {
    // error handled by interceptor
  } finally {
    loading.value = false
  }
}
</script>