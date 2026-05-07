<template>
  <div class="profile">
    <div class="profile-card">
      <div class="profile-header">
        <div class="avatar">🛡️</div>
        <h2>{{ adminStore.adminInfo?.username || '管理员' }}</h2>
        <p class="role">系统管理员</p>
      </div>

      <el-divider />

      <div class="password-section">
        <h3>🔑 修改密码</h3>
        <el-form
          ref="formRef"
          :model="form"
          :rules="rules"
          label-width="100px"
          class="password-form"
        >
          <el-form-item label="旧密码" prop="oldPassword">
            <el-input
              v-model="form.oldPassword"
              type="password"
              show-password
              placeholder="请输入旧密码"
            />
          </el-form-item>
          <el-form-item label="新密码" prop="newPassword">
            <el-input
              v-model="form.newPassword"
              type="password"
              show-password
              placeholder="请输入新密码（至少6位）"
            />
          </el-form-item>
          <el-form-item label="确认密码" prop="confirmPassword">
            <el-input
              v-model="form.confirmPassword"
              type="password"
              show-password
              placeholder="请再次输入新密码"
            />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" :loading="loading" @click="handleSubmit">
              确认修改
            </el-button>
          </el-form-item>
        </el-form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import { changePassword } from '../api/admin'
import { useAdminStore } from '../stores/admin'

const adminStore = useAdminStore()
const formRef = ref(null)
const loading = ref(false)

const form = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const validateConfirm = (rule, value, callback) => {
  if (value !== form.newPassword) {
    callback(new Error('两次输入的密码不一致'))
  } else {
    callback()
  }
}

const rules = {
  oldPassword: [{ required: true, message: '请输入旧密码', trigger: 'blur' }],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, message: '密码至少6位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认新密码', trigger: 'blur' },
    { validator: validateConfirm, trigger: 'blur' }
  ]
}

async function handleSubmit() {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  loading.value = true
  try {
    const res = await changePassword({
      oldPassword: form.oldPassword,
      newPassword: form.newPassword
    })
    if (res.code === 200) {
      ElMessage.success('密码修改成功，请重新登录')
      adminStore.logout()
    } else {
      ElMessage.error(res.message || '修改失败')
    }
  } catch (e) {
    ElMessage.error(e.response?.data?.message || '修改失败')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.profile {
  display: flex;
  justify-content: center;
  padding: 20px 0;
}

.profile-card {
  width: 500px;
  background: rgba(20, 16, 50, 0.6);
  border: 1px solid rgba(100, 80, 200, 0.15);
  border-radius: 12px;
  padding: 40px;
}

.profile-header {
  text-align: center;
}

.avatar {
  font-size: 64px;
  margin-bottom: 12px;
}

.profile-header h2 {
  color: #d4d0e8;
  margin: 0;
  font-size: 22px;
}

.role {
  color: #8a80a8;
  font-size: 13px;
  margin-top: 4px;
}

.password-section h3 {
  color: #d4d0e8;
  font-size: 16px;
  margin-bottom: 20px;
}

.password-form :deep(.el-form-item__label) {
  color: #a098b8;
}

.password-form :deep(.el-input__wrapper) {
  background: rgba(15, 12, 40, 0.6);
  border: 1px solid rgba(100, 80, 200, 0.2);
  border-radius: 8px;
  box-shadow: none;
}

.password-form :deep(.el-input__inner) {
  color: #d4d0e8;
}

:deep(.el-divider) {
  border-color: rgba(100, 80, 200, 0.15);
}
</style>