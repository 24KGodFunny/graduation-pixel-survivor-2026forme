<template>
  <div class="dashboard">
    <!-- 顶部统计卡片行 -->
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
            <!-- 时间范围切换：通过 v-model 绑定 chartDays，change 事件触发重新请求数据 -->
            <el-radio-group v-model="chartDays" size="small" @change="loadDailyStats">
              <el-radio-button value="7d">近7天</el-radio-button>
              <el-radio-button value="30d">近30天</el-radio-button>
              <el-radio-button value="3m">近3月</el-radio-button>
            </el-radio-group>
          </div>
          <!-- ECharts 图表的挂载容器 -->
          <div ref="trendChartRef" class="chart-container"></div>
        </div>
      </el-col>
    </el-row>

    <!-- DAU 折线图 -->
    <el-row :gutter="20" class="chart-row">
      <el-col :span="24">
        <div class="chart-card">
          <div class="chart-header">
            <h3>📊 每日活跃用户 (DAU)</h3>
            <el-radio-group v-model="dauDays" size="small" @change="loadDauStats">
              <el-radio-button value="7d">近7天</el-radio-button>
              <el-radio-button value="30d">近30天</el-radio-button>
            </el-radio-group>
          </div>
          <div ref="dauChartRef" class="chart-container"></div>
        </div>
      </el-col>
    </el-row>

  </div>
</template>

<script setup>
import { ref, reactive, onMounted, onUnmounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import { getDashboardStats, getDailyStats, getDauStats } from '../api/admin'

// 概览统计数据（总用户数、今日新增）
const stats = reactive({
  totalUsers: 0,
  todayNewUsers: 0
})

// 当前选中的图表时间范围，默认近 7 天
const chartDays = ref('7d')
const trendChartRef = ref(null)

// ECharts 实例引用，用于后续 resize/dispose
let trendChart = null

// DAU 图表相关
const dauDays = ref('7d')
const dauChartRef = ref(null)
let dauChart = null

/**
 * 页面挂载时的初始化流程：
 * 1. 先加载概览统计数据（卡片）
 * 2. 再加载每日趋势数据（图表）
 */
onMounted(async () => {
  await loadStats()
  await loadDailyStats()
  await loadDauStats()
})

// 组件卸载时销毁 ECharts 实例，释放资源
onUnmounted(() => {
  trendChart?.dispose()
  dauChart?.dispose()
})

/**
 * 加载仪表盘概览统计数据
 * 从后端获取 totalUsers 和 todayNewUsers，合并到 stats 响应式对象中
 */
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

/**
 * 加载每日趋势数据并初始化/更新图表
 * 先请求后端数据，再通过 nextTick 等待 DOM 渲染完成后初始化 ECharts
 */
async function loadDailyStats() {
  try {
    const res = await getDailyStats(chartDays.value)
    if (res.code === 200) {
      // nextTick 确保 trendChartRef 对应的 DOM 元素已挂载
      await nextTick()
      initTrendChart(res.data || [])
    }
  } catch (e) {
    console.error('加载每日统计失败', e)
  }
}

/**
 * 加载 DAU 统计数据并渲染折线图
 */
async function loadDauStats() {
  try {
    const res = await getDauStats(dauDays.value)
    if (res.code === 200) {
      await nextTick()
      initDauChart(res.data || [])
    }
  } catch (e) {
    console.error('加载DAU统计失败', e)
  }
}

/**
 * 初始化 DAU 折线图
 */
function initDauChart(data) {
  if (!dauChartRef.value) return
  if (dauChart) dauChart.dispose()

  dauChart = echarts.init(dauChartRef.value)

  const dates = data.map(d => d.date)
  const dau = data.map(d => d.dau || 0)

  dauChart.setOption({
    tooltip: {
      trigger: 'axis',
      backgroundColor: 'rgba(15, 12, 40, 0.9)',
      borderColor: 'rgba(100, 80, 200, 0.3)',
      textStyle: { color: '#d4d0e8' }
    },
    legend: {
      data: ['DAU'],
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
      name: '活跃用户',
      axisLine: { show: false },
      splitLine: { lineStyle: { color: 'rgba(100, 80, 200, 0.08)' } },
      axisLabel: { color: '#8a80a8' }
    },
    series: [
      {
        name: 'DAU',
        type: 'line',
        data: dau,
        smooth: true,
        lineStyle: {
          color: '#818cf8',
          width: 3
        },
        itemStyle: {
          color: '#a78bfa'
        },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(129, 140, 248, 0.4)' },
            { offset: 1, color: 'rgba(129, 140, 248, 0.02)' }
          ])
        }
      }
    ]
  })
}

/**
 * 初始化 ECharts 柱状图
 *
 * 数据处理流程：
 * 1. 从原始 data 数组中提取日期、新用户数、新订单数三个数组
 * 2. 如果已有旧实例则先销毁再创建新实例
 * 3. 配置暗色主题风格的柱状图 option
 *
 * ECharts 配置要点：
 * - tooltip：暗色半透明背景，匹配整体暗色 UI
 * - xAxis：类目轴显示日期，轴线和标签为淡紫色
 * - yAxis：数值轴，隐藏轴线，使用极浅分割线营造科技感
 * - series：两组柱状图（用户/订单），均使用 LinearGradient 纵向渐变填充
 *   - 用户柱：蓝紫色渐变（#818cf8 -> #6366f1）
 *   - 订单柱：绿色渐变（#34d399 -> #10b981）
 *   - 顶部圆角 borderRadius: [4, 4, 0, 0]，底部直角
 */
function initTrendChart(data) {
  if (!trendChartRef.value) return
  if (trendChart) trendChart.dispose()

  // 创建 ECharts 实例并绑定到指定 DOM 容器
  trendChart = echarts.init(trendChartRef.value)

  // 从后端返回数据中提取三个数组
  const dates = data.map(d => d.date)
  const users = data.map(d => d.newUsers || 0)
  const orders = data.map(d => d.newOrders || 0)

  trendChart.setOption({
    // 提示框：暗色背景 + 轴触发（同时显示两组数据）
    tooltip: {
      trigger: 'axis',
      backgroundColor: 'rgba(15, 12, 40, 0.9)',
      borderColor: 'rgba(100, 80, 200, 0.3)',
      textStyle: { color: '#d4d0e8' }
    },
    // 图例：置于图表顶部
    legend: {
      data: ['新增用户', '新增订单'],
      textStyle: { color: '#a098b8' },
      top: 5
    },
    // 绘图网格：控制图表在容器中的边距
    grid: {
      left: 50,
      right: 20,
      top: 45,
      bottom: 30
    },
    // X 轴：类目轴，显示日期标签
    xAxis: {
      type: 'category',
      data: dates,
      axisLine: { lineStyle: { color: 'rgba(100, 80, 200, 0.2)' } },
      axisLabel: { color: '#8a80a8', fontSize: 11 }
    },
    // Y 轴：数值轴
    yAxis: {
      type: 'value',
      name: '数量',
      axisLine: { show: false },  // 隐藏轴线，只用分割线区分
      splitLine: { lineStyle: { color: 'rgba(100, 80, 200, 0.08)' } },
      axisLabel: { color: '#8a80a8' }
    },
    // 数据系列
    series: [
      {
        name: '新增用户',
        type: 'bar',
        data: users,
        itemStyle: {
          // ECharts 纵向线性渐变：从顶部 #818cf8（亮蓝紫）到底部 #6366f1（深蓝紫）
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: '#818cf8' },
            { offset: 1, color: '#6366f1' }
          ]),
          borderRadius: [4, 4, 0, 0]   // 柱子顶部圆角
        },
        barWidth: '25%'
      },
      {
        name: '新增订单',
        type: 'bar',
        data: orders,
        itemStyle: {
          // 绿色渐变：从 #34d399 到 #10b981
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

// 监听浏览器窗口 resize 事件，自动重绘图表以适配新尺寸
window.addEventListener('resize', () => {
  trendChart?.resize()
  dauChart?.resize()
})
</script>

<style scoped>
.dashboard {
  padding: 0;
}

.stat-cards {
  margin-bottom: 20px;
}

/* 统计卡片：半透明暗色背景 + 紫色细边框 */
.stat-card {
  display: flex;
  align-items: center;
  padding: 24px 20px;
  border-radius: 12px;
  background: rgba(20, 16, 50, 0.6);
  border: 1px solid rgba(100, 80, 200, 0.15);
  transition: all 0.3s ease;
}

/* hover 时卡片微上移 + 边框变亮 + 投影增强 */
.stat-card:hover {
  transform: translateY(-2px);
  border-color: rgba(100, 80, 200, 0.3);
  box-shadow: 0 4px 20px rgba(80, 50, 200, 0.1);
}

.stat-icon {
  font-size: 36px;
  margin-right: 16px;
}

/* 数值使用渐变色文字 + 等宽字体 */
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

/* 图表卡片：与统计卡片风格一致 */
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