<template>
  <div>
    <el-input v-model="keyword" placeholder="搜索用户名" clearable style="width: 250px; margin-bottom: 15px" @clear="loadData">
      <template #append>
        <el-button @click="loadData">搜索</el-button>
      </template>
    </el-input>

    <el-table :data="users" border stripe class="pixel-table">
      <el-table-column prop="id" label="ID" width="60" />
      <el-table-column prop="username" label="用户名" />
      <el-table-column prop="nickname" label="昵称" />
      <el-table-column prop="status" label="状态" width="80">
        <template #default="{ row }">
          <el-tag :type="row.status === 0 ? 'success' : 'danger'">{{ row.status === 0 ? '正常' : '封禁' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="createTime" label="注册时间" width="170">
        <template #default="{ row }">
          {{ formatTime(row.createTime) }}
        </template>
      </el-table-column>
      <el-table-column label="操作" width="180">
        <template #default="{ row }">
          <el-button v-if="row.status === 0" size="small" type="danger" @click="handleBan(row.id)">封禁</el-button>
          <el-button v-else size="small" type="success" @click="handleUnban(row.id)">解封</el-button>
          <el-button size="small" type="danger" plain @click="handleDelete(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination style="margin-top: 15px" :current-page="page" :page-size="size" :total="total"
      @current-change="p => { page = p; loadData() }" layout="total, prev, pager, next" />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getUsers, banUser, unbanUser, deleteUser } from '../api/admin'

const users = ref([])
const page = ref(1)
const size = 20
const total = ref(0)
const keyword = ref('')

function formatTime(time) {
  if (!time) return '-'
  if (typeof time === 'string' && time.includes('T')) {
    return time.replace('T', ' ').substring(0, 19)
  }
  return time
}

async function loadData() {
  const res = await getUsers({ page: page.value, size, keyword: keyword.value || undefined })
  users.value = res.data.records
  total.value = res.data.total
}

async function handleBan(id) {
  await ElMessageBox.confirm('确定封禁该用户?', '提示', { type: 'warning' })
  await banUser(id)
  ElMessage.success('封禁成功')
  loadData()
}

async function handleUnban(id) {
  await unbanUser(id)
  ElMessage.success('解封成功')
  loadData()
}

async function handleDelete(row) {
  await ElMessageBox.confirm(
    `确定要删除用户 "${row.username}" 吗？该操作将删除该用户的所有关联数据（背包、地图进度、游戏统计等），且不可恢复！`,
    '警告',
    { type: 'error', confirmButtonText: '确定删除', cancelButtonText: '取消' }
  )
  await deleteUser(row.id)
  ElMessage.success('用户已删除')
  loadData()
}

onMounted(loadData)
</script>

<style scoped>
.pixel-table :deep(.el-table__header th) {
  background: rgba(30, 25, 60, 0.8) !important;
  color: #ffffff;
}

.pixel-table :deep(.el-table__row) {
  background: rgba(40, 35, 70, 0.5) !important;
  color: #ffffff;
}

.pixel-table :deep(.el-table__row td) {
  color: #ffffff;
  border-bottom-color: rgba(100, 80, 200, 0.1);
}

.pixel-table :deep(.el-table__row--striped td) {
  background: rgba(50, 45, 80, 0.5) !important;
  color: #ffffff;
}

.pixel-table :deep(.el-table__row:hover > td) {
  background: rgba(100, 80, 200, 0.15) !important;
}

.pixel-table {
  --el-table-bg-color: transparent;
  --el-table-tr-bg-color: transparent;
  --el-table-header-bg-color: transparent;
  --el-table-row-hover-bg-color: transparent;
  --el-table-border-color: rgba(100, 80, 200, 0.1);
  --el-table-text-color: #ffffff;
  --el-table-header-text-color: #ffffff;
}
</style>