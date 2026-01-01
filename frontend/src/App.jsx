import React, { useState, useEffect } from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { Layout, Menu, Select, Space, Tag, message } from 'antd'
import {
  DashboardOutlined,
  UserOutlined,
  TeamOutlined,
  CalendarOutlined,
  FileTextOutlined,
  DollarOutlined,
  ApartmentOutlined,
  BarChartOutlined,
  UserSwitchOutlined
} from '@ant-design/icons'
import { Link, useLocation } from 'react-router-dom'
import axios from 'axios'

// 页面组件
import Dashboard from './pages/Dashboard'
import PatientList from './pages/PatientList'
import PatientForm from './pages/PatientForm'
import ScheduleList from './pages/ScheduleList'
import ScheduleForm from './pages/ScheduleForm'
import RegistrationList from './pages/RegistrationList'
import RegistrationForm from './pages/RegistrationForm'
import EncounterList from './pages/EncounterList'
import EncounterForm from './pages/EncounterForm'
import InvoiceList from './pages/InvoiceList'
import InvoiceForm from './pages/InvoiceForm'
import PaymentForm from './pages/PaymentForm'
import StaffList from './pages/StaffList'
import StaffForm from './pages/StaffForm'
import DepartmentList from './pages/DepartmentList'
import Statistics from './pages/Statistics'
import PharmacyList from './pages/PharmacyList'
import LabList from './pages/LabList'
import InpatientList from './pages/InpatientList'
import PatientPortal from './pages/PatientPortal'

const { Header, Sider, Content } = Layout
const { Option } = Select

function App() {
  const location = useLocation()
  const [currentRole, setCurrentRole] = useState('admin')
  const [roles, setRoles] = useState([])
  const [loading, setLoading] = useState(true)

  // 加载角色列表
  useEffect(() => {
    loadRoles()
  }, [])

  // 加载本地保存的角色
  useEffect(() => {
    const savedRole = localStorage.getItem('currentRole')
    if (savedRole) {
      setCurrentRole(savedRole)
      // 设置 axios 默认请求头
      axios.defaults.headers.common['X-Role'] = savedRole
    }
  }, [])

  const loadRoles = async () => {
    try {
      const response = await axios.get('/api/auth/roles')
      setRoles(response.data.data || [])
    } catch (error) {
      console.error('加载角色列表失败:', error)
      message.error('加载角色列表失败')
    } finally {
      setLoading(false)
    }
  }

  // 定义所有菜单项
  const getAllMenuItems = () => [
    {
      key: '/',
      icon: <DashboardOutlined />,
      label: <Link to="/">仪表盘</Link>,
      roles: ['admin', 'doctor', 'nurse', 'pharmacist', 'lab_tech', 'cashier', 'reception', 'patient']
    },
    {
      key: '/patient-portal',
      icon: <UserOutlined />,
      label: <Link to="/patient-portal">我的门户</Link>,
      roles: ['patient']
    },
    {
      key: '/patients',
      icon: <UserOutlined />,
      label: <Link to="/patients">患者管理</Link>,
      roles: ['admin', 'doctor', 'nurse', 'reception', 'lab_tech']
    },
    {
      key: '/schedules',
      icon: <CalendarOutlined />,
      label: <Link to="/schedules">排班管理</Link>,
      roles: ['admin', 'doctor', 'reception']
    },
    {
      key: '/registrations',
      icon: <FileTextOutlined />,
      label: <Link to="/registrations">挂号管理</Link>,
      roles: ['admin', 'reception']  // 只有 reception 可以创建挂号
    },
    {
      key: '/encounters',
      icon: <FileTextOutlined />,
      label: <Link to="/encounters">就诊管理</Link>,
      roles: ['admin', 'doctor', 'nurse']  // 护士可以查看就诊
    },
    {
      key: '/invoices',
      icon: <DollarOutlined />,
      label: <Link to="/invoices">收费管理</Link>,
      roles: ['admin', 'cashier']
    },
    {
      key: '/pharmacy',
      icon: <FileTextOutlined />,
      label: <Link to="/pharmacy">药房管理</Link>,
      roles: ['admin', 'pharmacist']
    },
    {
      key: '/lab',
      icon: <FileTextOutlined />,
      label: <Link to="/lab">检验管理</Link>,
      roles: ['admin', 'lab_tech']
    },
    {
      key: '/inpatients',
      icon: <FileTextOutlined />,
      label: <Link to="/inpatients">住院管理</Link>,
      roles: ['admin', 'nurse']
    },
    {
      key: '/staff',
      icon: <TeamOutlined />,
      label: <Link to="/staff">员工管理</Link>,
      roles: ['admin']
    },
    {
      key: '/departments',
      icon: <ApartmentOutlined />,
      label: <Link to="/departments">科室管理</Link>,
      roles: ['admin']
    },
    {
      key: '/statistics',
      icon: <BarChartOutlined />,
      label: <Link to="/statistics">统计报表</Link>,
      roles: ['admin', 'cashier']
    }
  ]

  // 根据当前角色过滤菜单
  const getFilteredMenuItems = () => {
    const allMenus = getAllMenuItems()
    return allMenus.filter(item => item.roles.includes(currentRole))
  }

  const menuItems = getFilteredMenuItems()

  // 获取当前路由的基础路径用于高亮菜单
  const getSelectedKey = () => {
    const path = location.pathname
    if (path.startsWith('/patients')) return '/patients'
    if (path.startsWith('/schedules')) return '/schedules'
    if (path.startsWith('/registrations')) return '/registrations'
    if (path.startsWith('/encounters')) return '/encounters'
    if (path.startsWith('/invoices')) return '/invoices'
    if (path.startsWith('/payments')) return '/invoices'
    if (path.startsWith('/staff')) return '/staff'
    if (path.startsWith('/departments')) return '/departments'
    if (path.startsWith('/statistics')) return '/statistics'
    if (path.startsWith('/pharmacy')) return '/pharmacy'
    if (path.startsWith('/lab')) return '/lab'
    if (path.startsWith('/inpatients')) return '/inpatients'
    return '/'
  }

  const handleRoleChange = async (value) => {
    try {
      const response = await axios.post('/api/auth/switch-role', { role: value })
      if (response.data.success) {
        setCurrentRole(value)
        // 保存到本地存储
        localStorage.setItem('currentRole', value)
        // 更新 axios 默认请求头
        axios.defaults.headers.common['X-Role'] = value
        message.success(`已切换到：${response.data.data.role_name}`)
      }
    } catch (error) {
      message.error('切换角色失败')
      console.error('切换角色失败:', error)
    }
  }

  const getCurrentRoleInfo = () => {
    return roles.find(r => r.key === currentRole) || { name: '管理员', color: '#f50' }
  }

  const roleInfo = getCurrentRoleInfo()

  if (loading) {
    return <div style={{ textAlign: 'center', padding: '50px' }}>加载中...</div>
  }

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Header style={{
        background: 'linear-gradient(135deg, rgba(4, 168, 250, 0.27) 0%, rgb(109, 178, 219) 100%)',
        padding: '0 24px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div style={{ fontSize: '32px' }}>🏥</div>
          <div style={{ 
            fontSize: '24px',
            fontWeight: 700,
            color: 'white',
            textShadow: '2px 2px 4px rgba(0,0,0,0.3)'
          }}>
            社区医院门诊管理系统
          </div>
        </div>

        <Space size="large">
          <Space align="center">
            <UserSwitchOutlined style={{ fontSize: '18px', color: 'white' }} />
            <span style={{ color: 'white', fontSize: '14px' }}>切换角色：</span>
            <Select
              value={currentRole}
              onChange={handleRoleChange}
              style={{ width: 160 }}
              size="large"
            >
              {roles.map(role => (
                <Option key={role.key} value={role.key}>
                  <Tag color={role.color} style={{ marginRight: 4 }}>
                    {role.name}
                  </Tag>
                </Option>
              ))}
            </Select>
          </Space>
          <Tag 
            color={roleInfo.color} 
            style={{ 
              fontSize: '14px', 
              padding: '6px 16px',
              borderRadius: '20px',
              fontWeight: 600
            }}
          >
            当前：{roleInfo.name}
          </Tag>
        </Space>
      </Header>

      <Layout>
        <Sider 
          width={240}
          theme="light"
          style={{
            background: 'white',
            boxShadow: '2px 0 8px rgba(0, 0, 0, 0.06)',
            overflow: 'auto',
            height: 'calc(100vh - 64px)',
            position: 'fixed',
            left: 0,
            top: 64
          }}
        >
          <div style={{
            padding: '24px 16px',
            borderBottom: '2px solid #e8f4f8',
            textAlign: 'center',
            fontSize: '16px',
            fontWeight: 600,
            color: '#1e3a8a',
            background: 'linear-gradient(135deg, rgba(4, 168, 250, 0.1) 0%, rgba(109, 178, 219, 0.1) 100%)'
          }}>
            功能导航
          </div>

          <Menu
            mode="inline"
            selectedKeys={[getSelectedKey()]}
            items={menuItems}
            style={{ 
              borderRight: 0,
              padding: '12px 8px',
              fontSize: '15px'
            }}
          />
        </Sider>

        <Layout style={{ marginLeft: 240 }}>
          <Content style={{
            margin: '24px',
            minHeight: 'calc(100vh - 112px)',
            background: '#f0f2f5'
          }}>
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/patients" element={<PatientList />} />
              <Route path="/patients/new" element={<PatientForm />} />
              <Route path="/patients/:id/edit" element={<PatientForm />} />
              <Route path="/schedules" element={<ScheduleList />} />
              <Route path="/schedules/new" element={<ScheduleForm />} />
              <Route path="/schedules/:id/edit" element={<ScheduleForm />} />
              <Route path="/registrations" element={<RegistrationList />} />
              <Route path="/registrations/new" element={<RegistrationForm />} />
              <Route path="/encounters" element={<EncounterList />} />
              <Route path="/encounters/new" element={<EncounterForm />} />
              <Route path="/invoices" element={<InvoiceList />} />
              <Route path="/invoices/new" element={<InvoiceForm />} />
              <Route path="/payments/new" element={<PaymentForm />} />
              <Route path="/staff" element={<StaffList />} />
              <Route path="/staff/new" element={<StaffForm />} />
              <Route path="/staff/:id/edit" element={<StaffForm />} />
              <Route path="/departments" element={<DepartmentList />} />
              <Route path="/statistics" element={<Statistics />} />
              <Route path="/pharmacy" element={<PharmacyList />} />
              <Route path="/lab" element={<LabList />} />
              <Route path="/inpatients" element={<InpatientList />} />
              <Route path="/patient-portal" element={<PatientPortal />} />
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </Content>
        </Layout>
      </Layout>
    </Layout>
  )
}

export default App
