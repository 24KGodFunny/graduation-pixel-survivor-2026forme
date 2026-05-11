<template>
  <div class="dashboard">
    <!-- 统计卡片 -->
    <el-row :gutter="20" class="stat-cards">
      <el-col :span="12">
        <div class="stat-card card-users">
          <div class="stat-icon">👥</div>
          <div class="stat-info">
            <div class="stat-value">{{ stats.totalUsers || 0 }}</div>
            <div class="stat-label">总用户数</div>
          </div>
        </div>
      </el-col>
      <el-col :span="12">
        <div class="stat-card card-today">
          <div class="stat-icon">📅</div>
          <div class="stat-info">
            <div class="stat-value">{{ stats.todayNewUsers || 0 }}</div>
            <div class="stat-label">今日新增用户</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 图表区域 -->
    <el-row :gutter="20" class="chart-row">
      <el-col :span="24">
        <div class="chart-card">
          <div class="chart-header">
            <h3>📈 每日数据趋势</h3>
            <el-radio-group v-model="chartDays" size="small" @change="loadDailyStats">
              <el-radio-button value="7d">近7天</el-radio-button>
              <el-radio-button value="30d">近30天</el-radio-button>
              <el-radio-button value="3m">近3月</el-radio-button>
            </el-radio-group>
          </div>
          <div ref="trendChartRef" class="chart-container"></div>
        </div>
      </el-col>
    </el-row>

  </div>
</template>

<script setup>
import { ref, reactive, onMounted, onUnmounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import { getDashboardStats, getDailyStats } from '../api/admin'

const stats = reactive({
  totalUsers: 0,
  todayNewUsers: 0
})

const chartDays = ref('7d')
const trendChartRef = ref(null)

let trendChart = null

onMounted(async () => {
  await loadStats()
  await loadDailyStats()
})

onUnmounted(() => {
  trendChart?.dispose()
})

async function loadStats() {
  try {
    const res = await getDashboardStats()
    if (res.code === 200) {
      Object.assign(stats, res.data)
    }
  } catch (e) {
    console.error('加载统计数据失败', e)
  }
}

async function loadDailyStats() {
  try {
    const res = await getDailyStats(chartDays.value)
    if (res.code === 200) {
      await nextTick()
      initTrendChart(res.data || [])
    }
  } catch (e) {
    console.error('加载每日统计失败', e)
  }
}

function initTrendChart(data) {
  if (!trendChartRef.value) return
  if (trendChart) trendChart.dispose()
  
  trendChart = echarts.init(trendChartRef.value)
  
  const dates = data.map(d => d.date)
  const users = data.map(d => d.newUsers || 0)
  const orders = data.map(d => d.newOrders || 0)
  
  trendChart.setOption({
    tooltip: {
      trigger: 'axis',
      backgroundColor: 'rgba(15, 12, 40, 0.9)',
      borderColor: 'rgba(100, 80, 200, 0.3)',
      textStyle: { color: '#d4d0e8' }
    },
    legend: {
      data: ['新增用户', '新增订单'],
      textStyle: { color: '#a098b8' },
      top: 5
    },
    grid: {
      left: 50,
      right: 20,
      top: 45,
      bottom: 30
    },
    xAxis: {
      type: 'category',
      data: dates,
      axisLine: { lineStyle: { color: 'rgba(100, 80, 200, 0.2)' } },
      axisLabel: { color: '#8a80a8', fontSize: 11 }
    },
    yAxis: {
      type: 'value',
      name: '数量',
      axisLine: { show: false },
      splitLine: { lineStyle: { color: 'rgba(100, 80, 200, 0.08)' } },
      axisLabel: { color: '#8a80a8' }
    },
    series: [
      {
        name: '新增用户',
        type: 'bar',
        data: users,
        itemStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: '#818cf8' },
            { offset: 1, color: '#6366f1' }
          ]),
          borderRadius: [4, 4, 0, 0]
        },
        barWidth: '25%'
      },
      {
        name: '新增订单',
        type: 'bar',
        data: orders,
        itemStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: '#34d399' },
            { offset: 1, color: '#10b981' }
          ]),
          borderRadius: [4, 4, 0, 0]
        },
        barWidth: '25%'
      }
    ]
  })
}

// 窗口resize
window.addEventListener('resize', () => {
  trendChart?.resize()
})
</script>

<style scoped>
.dashboard {
  padding: 0;
}

.stat-cards {
  margin-bottom: 20px;
}

.stat-card {
  display: flex;
  align-items: center;
  padding: 24px 20px;
  border-radius: 12px;
  background: rgba(20, 16, 50, 0.6);
  border: 1px solid rgba(100, 80, 200, 0.15);
  transition: all 0.3s ease;
}

.stat-card:hover {
  transform: translateY(-2px);
  border-color: rgba(100, 80, 200, 0.3);
  box-shadow: 0 4px 20px rgba(80, 50, 200, 0.1);
}

.stat-icon {
  font-size: 36px;
  margin-right: 16px;
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
  font-family: 'Courier New', monospace;
  background: linear-gradient(135deg, #a78bfa, #60a5fa);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.stat-label {
  font-size: 13px;
  color: #8a80a8;
  margin-top: 4px;
}

.chart-row {
  margin-bottom: 20px;
}

.chart-card {
  background: rgba(20, 16, 50, 0.6);
  border: 1px solid rgba(100, 80, 200, 0.15);
  border-radius: 12px;
  padding: 20px;
}

.chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.chart-header h3 {
  margin: 0;
  font-size: 15px;
  color: #d4d0e8;
  font-weight: 600;
}

.chart-container {
  width: 100%;
  height: 320px;
}

</style>