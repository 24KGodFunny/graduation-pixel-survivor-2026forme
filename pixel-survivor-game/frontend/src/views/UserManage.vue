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
      <el-table-column prop="gold" label="金币" width="80" />
      <el-table-column prop="level" label="等级" width="60" />
      <el-table-column prop="status" label="状态" width="80">
        <template #default="{ row }">
          <el-tag :type="row.status === 0 ? 'success' : 'danger'">{{ row.status === 0 ? '正常' : '封禁' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="createTime" label="注册时间" width="170" />
      <el-table-column label="操作" width="120">
        <template #default="{ row }">
          <el-button v-if="row.status === 0" size="small" type="danger" @click="handleBan(row.id)">封禁</el-button>
          <el-button v-else size="small" type="success" @click="handleUnban(row.id)">解封</el-button>
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
import { getUsers, banUser, unbanUser } from '../api/admin'

const users = ref([])
const page = ref(1)
const size = 20
const total = ref(0)
const keyword = ref('')

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
