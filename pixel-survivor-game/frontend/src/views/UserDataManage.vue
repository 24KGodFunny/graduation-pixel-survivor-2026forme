<template>
  <div class="user-data-manage">
    <!-- 搜索栏 -->
    <el-card class="search-card">
      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="用户名">
          <el-input v-model="searchForm.username" placeholder="请输入用户名" clearable />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 用户信息卡片 -->
    <el-card v-if="userData" class="user-card">
      <template #header>
        <div class="card-header">
          <span>用户信息</span>
          <div>
            <el-button type="primary" size="small" @click="handleEditUser">编辑基本信息</el-button>
            <el-button type="success" size="small" @click="handleEditSaveData">编辑存档数据</el-button>
            <el-button type="danger" size="small" @click="handleDeleteUser">删除用户</el-button>
          </div>
        </div>
      </template>

      <!-- 基本信息 -->
      <el-descriptions :column="3" border class="user-info">
        <el-descriptions-item label="用户ID">{{ userData.user.id }}</el-descriptions-item>
        <el-descriptions-item label="用户名">{{ userData.user.username }}</el-descriptions-item>
        <el-descriptions-item label="昵称">{{ userData.user.nickname || '-' }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="userData.user.status === 1 ? 'danger' : 'success'">
            {{ userData.user.status === 1 ? '封禁' : '正常' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="注册时间">{{ userData.user.createdAt }}</el-descriptions-item>
        <el-descriptions-item label="最后登录">{{ userData.user.lastLoginAt || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <!-- 存档数据卡片 -->
    <el-card v-if="userData && userData.saveData" class="save-data-card">
      <template #header>
        <div class="card-header">
          <span>存档数据</span>
        </div>
      </template>

      <!-- 货币信息 -->
      <h4 class="section-title">💰 货币</h4>
      <el-descriptions :column="2" border class="section-content">
        <el-descriptions-item label="金币">
          <el-tag type="warning">{{ userData.saveData.coins ?? 0 }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="钻石">
          <el-tag type="primary">💎 {{ userData.saveData.diamonds ?? 0 }}</el-tag>
        </el-descriptions-item>
      </el-descriptions>

      <!-- 角色信息 -->
      <h4 class="section-title">👤 角色</h4>
      <el-table :data="characterTableData" border class="section-content">
        <el-table-column prop="charCode" label="角色编码" width="120" />
        <el-table-column prop="charName" label="角色名称" width="120" />
        <el-table-column label="解锁状态" width="120">
          <template #default="{ row }">
            <el-tag :type="row.unlocked ? 'success' : 'info'">
              {{ row.unlocked ? '已解锁' : '未解锁' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="等级" width="120">
          <template #default="{ row }">
            <span>{{ row.level || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="unlockCost" label="解锁费用" width="120">
          <template #default="{ row }">
            <span>{{ row.unlockCost > 0 ? row.unlockCost + ' 金币' : '免费' }}</span>
          </template>
        </el-table-column>
      </el-table>

      <!-- 地图信息 -->
      <h4 class="section-title">🗺️ 地图</h4>
      <el-table :data="mapTableData" border class="section-content">
        <el-table-column prop="mapCode" label="地图编码" width="180" />
        <el-table-column prop="mapName" label="地图名称" width="180" />
        <el-table-column label="章节" width="100">
          <template #default="{ row }">
            <span>第{{ row.chapter }}章</span>
          </template>
        </el-table-column>
        <el-table-column label="解锁状态" width="120">
          <template #default="{ row }">
            <el-tag :type="row.unlocked ? 'success' : 'info'">
              {{ row.unlocked ? '已解锁' : '未解锁' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="通关状态" width="120">
          <template #default="{ row }">
            <el-tag :type="row.completed ? 'success' : 'warning'">
              {{ row.completed ? '已通关' : '未通关' }}
            </el-tag>
          </template>
        </el-table-column>
      </el-table>

      <!-- 成就信息 -->
      <h4 class="section-title">🏆 成就</h4>
      <div class="section-content">
        <el-tag
          v-for="achievement in (userData.saveData.unlocked_achievements || [])"
          :key="achievement"
          class="achievement-tag"
          type="warning"
        >
          {{ achievement }}
        </el-tag>
        <el-empty
          v-if="!userData.saveData.unlocked_achievements || userData.saveData.unlocked_achievements.length === 0"
          description="暂无成就"
          :image-size="60"
        />
      </div>
    </el-card>

    <!-- 未搜索时的提示 -->
    <el-card v-if="!userData" class="empty-card">
      <el-empty description="请输入用户名查询用户数据" />
    </el-card>

    <!-- 编辑基本信息对话框 -->
    <el-dialog v-model="userDialogVisible" title="编辑用户基本信息" width="500px">
      <el-form :model="userForm" label-width="80px">
        <el-form-item label="昵称">
          <el-input v-model="userForm.nickname" placeholder="请输入昵称" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="userDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitUserForm">确定</el-button>
      </template>
    </el-dialog>

    <!-- 编辑存档数据对话框 -->
    <el-dialog v-model="saveDataDialogVisible" title="编辑存档数据" width="700px">
      <el-form :model="saveDataForm" label-width="100px">
        <!-- 货币 -->
        <el-divider content-position="left">💰 货币</el-divider>
        <el-form-item label="金币">
          <el-input-number v-model="saveDataForm.coins" :min="0" :max="999999999" />
        </el-form-item>
        <el-form-item label="钻石">
          <el-input-number v-model="saveDataForm.diamonds" :min="0" :max="999999999" />
        </el-form-item>

        <!-- 角色 -->
        <el-divider content-position="left">👤 角色解锁</el-divider>
        <el-form-item
          v-for="char in editCharacters"
          :key="char.code"
          :label="char.charName || char.code"
        >
          <el-switch v-model="char.unlocked" active-text="已解锁" inactive-text="未解锁" style="margin-right: 16px;" />
          <el-input-number
            v-if="char.unlocked"
            v-model="char.level"
            :min="1"
            :max="999"
            size="small"
            placeholder="等级"
          />
        </el-form-item>

        <!-- 地图 -->
        <el-divider content-position="left">🗺️ 地图状态</el-divider>
        <el-form-item
          v-for="map in editMaps"
          :key="map.mapCode"
          :label="map.mapName || map.mapCode"
        >
          <el-switch v-model="map.unlocked" active-text="已解锁" inactive-text="未解锁" style="margin-right: 16px;" />
          <el-switch v-model="map.completed" active-text="已通关" inactive-text="未通关" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="saveDataDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submitSaveDataForm">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getUserDetailByUsername, updateUser, updateSaveData, deleteUser } from '../api/admin'

// ==================== 搜索 ====================
const searchForm = reactive({
  username: ''
})

const userData = ref(null)

const handleSearch = async () => {
  if (!searchForm.username) {
    ElMessage.warning('请输入用户名')
    return
  }
  try {
    const res = await getUserDetailByUsername(searchForm.username)
    if (res.code === 200) {
      userData.value = res.data
      buildCharacterTable()
      buildMapTable()
    } else {
      ElMessage.error(res.message || '查询失败')
    }
  } catch (error) {
    ElMessage.error('查询失败：' + (error.message || '未知错误'))
  }
}

const handleReset = () => {
  searchForm.username = ''
  userData.value = null
}

// ==================== 角色表格数据（展示用） ====================
const characterTableData = ref([])

const buildCharacterTable = () => {
  if (!userData.value || !userData.value.saveData) {
    characterTableData.value = []
    return
  }
  const saveData = userData.value.saveData
  const unlocked = saveData.unlocked_characters || []
  const levels = saveData.character_levels || {}
  const charDefs = saveData.characterDefinitions || []
  // 以角色定义表为基准，展示所有角色
  characterTableData.value = charDefs.map(def => ({
    charCode: def.charCode,
    charName: def.charName,
    unlocked: unlocked.includes(def.charCode),
    level: levels[def.charCode] || null,
    unlockCost: def.unlockCost || 0
  }))
}

// ==================== 地图表格数据（展示用） ====================
const mapTableData = ref([])

const buildMapTable = () => {
  if (!userData.value || !userData.value.saveData) {
    mapTableData.value = []
    return
  }
  const saveData = userData.value.saveData
  const unlocked = saveData.unlocked_maps || []
  const completed = saveData.completed_maps || []
  const mapDefs = saveData.mapDefinitions || []
  mapTableData.value = mapDefs.map(def => ({
    mapCode: def.mapCode,
    mapName: def.mapName,
    chapter: def.chapter,
    unlocked: unlocked.includes(def.mapCode),
    completed: completed.includes(def.mapCode)
  }))
}

// ==================== 编辑对话框专用数据 ====================
const editCharacters = ref([])
const editMaps = ref([])

// ==================== 编辑用户基本信息 ====================
const userDialogVisible = ref(false)
const userForm = reactive({
  nickname: ''
})

const handleEditUser = () => {
  userForm.nickname = userData.value.user.nickname || ''
  userDialogVisible.value = true
}

const submitUserForm = async () => {
  try {
    const res = await updateUser(userData.value.user.id, {
      nickname: userForm.nickname
    })
    if (res.code === 200) {
      ElMessage.success('更新成功')
      userDialogVisible.value = false
      handleSearch() // 刷新数据
    } else {
      ElMessage.error(res.message || '更新失败')
    }
  } catch (error) {
    ElMessage.error('更新失败：' + (error.message || '未知错误'))
  }
}

// ==================== 编辑存档数据 ====================
const saveDataDialogVisible = ref(false)
const saveDataForm = reactive({
  coins: 0,
  diamonds: 0
})

const handleEditSaveData = () => {
  const saveData = userData.value.saveData
  saveDataForm.coins = saveData.coins ?? 0
  saveDataForm.diamonds = saveData.diamonds ?? 0

  // 从角色定义表创建编辑用的独立数组（包含所有角色）
  const charDefs = saveData.characterDefinitions || []
  const unlocked = saveData.unlocked_characters || []
  const levels = saveData.character_levels || {}
  editCharacters.value = charDefs.map(def => ({
    code: def.charCode,
    charName: def.charName,
    unlocked: unlocked.includes(def.charCode),
    level: levels[def.charCode] || 1
  }))
  editMaps.value = mapTableData.value.map(m => ({
    mapCode: m.mapCode,
    mapName: m.mapName,
    chapter: m.chapter,
    unlocked: m.unlocked,
    completed: m.completed
  }))

  saveDataDialogVisible.value = true
}

const submitSaveDataForm = async () => {
  try {
    // 从编辑对话框的独立数据源收集
    const unlockedCharacters = editCharacters.value
      .filter(c => c.unlocked)
      .map(c => c.code)

    const characterLevels = {}
    editCharacters.value
      .filter(c => c.unlocked)
      .forEach(c => { characterLevels[c.code] = c.level || 1 })

    const unlockedMaps = editMaps.value
      .filter(m => m.unlocked)
      .map(m => m.mapCode)

    const completedMaps = editMaps.value
      .filter(m => m.completed)
      .map(m => m.mapCode)

    const res = await updateSaveData(userData.value.user.id, {
      coins: saveDataForm.coins,
      diamonds: saveDataForm.diamonds,
      unlocked_characters: unlockedCharacters,
      character_levels: characterLevels,
      unlocked_maps: unlockedMaps,
      completed_maps: completedMaps
    })

    if (res.code === 200) {
      ElMessage.success('存档数据更新成功')
      saveDataDialogVisible.value = false
      handleSearch() // 刷新数据
    } else {
      ElMessage.error(res.message || '更新失败')
    }
  } catch (error) {
    ElMessage.error('更新失败：' + (error.message || '未知错误'))
  }
}

// ==================== 删除用户 ====================
const handleDeleteUser = async () => {
  try {
    await ElMessageBox.confirm(
      `确定要删除用户 "${userData.value.user.username}" 吗？此操作不可恢复！`,
      '警告',
      { confirmButtonText: '确定删除', cancelButtonText: '取消', type: 'warning' }
    )
    const res = await deleteUser(userData.value.user.id)
    if (res.code === 200) {
      ElMessage.success('用户已删除')
      userData.value = null
    } else {
      ElMessage.error(res.message || '删除失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败：' + (error.message || '未知错误'))
    }
  }
}
</script>

<style scoped>
.user-data-manage {
  padding: 20px;
}

.search-card {
  margin-bottom: 20px;
}

.search-form {
  display: flex;
  align-items: center;
}

.user-card,
.save-data-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.user-info {
  margin-top: 10px;
}

.section-title {
  margin: 20px 0 10px 0;
  font-size: 16px;
  color: #303133;
}

.section-content {
  margin-bottom: 10px;
}

.achievement-tag {
  margin-right: 8px;
  margin-bottom: 8px;
}

.empty-card {
  margin-top: 20px;
}
</style>