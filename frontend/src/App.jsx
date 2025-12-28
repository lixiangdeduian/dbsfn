import React, { useState, useEffect } from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { Layout, Menu, Button, Dropdown, message } from 'antd'
import {
  DashboardOutlined,
  UserOutlined,
  CalendarOutlined,
  FileTextOutlined,
  DollarOutlined,
  TeamOutlined,
  ApartmentOutlined,
  BarChartOutlined,
  LogoutOutlined,
  UserSwitchOutlined,
} from '@ant-design/icons'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import Login from './pages/Login'
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

const { Header, Sider, Content } = Layout

function App() {
  const location = useLocation()
  const navigate = useNavigate()
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  // 配置axios默认请求头
  useEffect(() => {
    const token = localStorage.getItem('token')
    if (token) {
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`
      const savedUser = localStorage.getItem('user')
      if (savedUser) {
        setUser(JSON.parse(savedUser))
      }
    }
    setLoading(false)
  }, [])

  const handleLogin = (userData) => {
    setUser(userData)
    axios.defaults.headers.common['Authorization'] = `Bearer ${localStorage.getItem('token')}`
  }

  const handleLogout = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    delete axios.defaults.headers.common['Authorization']
    setUser(null)
    message.success('已退出登录')
    navigate('/login')
  }

  // 根据角色获取菜单项
  const getAllMenuItems = () => [
    {
      key: '/',
      icon: <DashboardOutlined />,
      label: <Link to="/">仪表盘</Link>,
      roles: ['admin', 'doctor', 'nurse', 'pharmacist', 'lab_tech', 'cashier', 'reception']
    },
    {
      key: '/patients',
      icon: <UserOutlined />,
      label: <Link to="/patients">患者管理</Link>,
      roles: ['admin', 'doctor', 'nurse', 'reception']
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
      roles: ['admin', 'doctor', 'reception']
    },
    {
      key: '/encounters',
      icon: <FileTextOutlined />,
      label: <Link to="/encounters">就诊管理</Link>,
      roles: ['admin', 'doctor', 'nurse']
    },
    {
      key: '/invoices',
      icon: <DollarOutlined />,
      label: <Link to="/invoices">收费管理</Link>,
      roles: ['admin', 'cashier']
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
  ]

  const getFilteredMenuItems = () => {
    if (!user) return []
    const allMenus = getAllMenuItems()
    return allMenus.filter(item => item.roles.includes(user.role))
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
    return '/'
  }

  if (loading) {
    return <div style={{ textAlign: 'center', padding: '50px' }}>加载中...</div>
  }

  // 登录页面
  if (location.pathname === '/login' || !user) {
    return (
      <Routes>
        <Route path="/login" element={<Login onLogin={handleLogin} />} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    )
  }

  // 用户下拉菜单
  const userMenu = {
    items: [
      {
        key: 'role',
        label: <div><strong>当前角色：</strong>{user.role_name}</div>,
        disabled: true
      },
      {
        type: 'divider'
      },
      {
        key: 'switch',
        icon: <UserSwitchOutlined />,
        label: '切换角色',
        onClick: () => {
          handleLogout()
          navigate('/login')
        }
      },
      {
        key: 'logout',
        icon: <LogoutOutlined />,
        label: '退出登录',
        onClick: handleLogout
      }
    ]
  }

  return (
    <Layout className="app-layout">
      <Header className="app-header">
        <div className="app-logo">社区医院门诊管理系统</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
          <div style={{ color: 'rgba(255, 255, 255, 0.85)', fontSize: '14px' }}>
            欢迎您，{user.role_name}
          </div>
          <Dropdown menu={userMenu} placement="bottomRight">
            <Button 
              type="text" 
              style={{ 
                color: 'white',
                display: 'flex',
                alignItems: 'center',
                gap: '8px'
              }}
            >
              <UserOutlined style={{ fontSize: '18px' }} />
              {user.username}
            </Button>
          </Dropdown>
        </div>
      </Header>
      <Layout>
        <Sider 
          width={240} 
          theme="light"
          style={{
            background: 'white',
            boxShadow: '2px 0 8px rgba(0, 0, 0, 0.06)',
            overflow: 'auto',
            height: '100vh',
            position: 'sticky',
            top: 0,
            left: 0
          }}
        >
          <div style={{
            padding: '24px 16px',
            borderBottom: '2px solid #e8f4f8',
            textAlign: 'center',
            fontSize: '16px',
            fontWeight: 600,
            color: '#1e3a8a'
          }}>
            功能导航
          </div>
          <Menu
            mode="inline"
            selectedKeys={[getSelectedKey()]}
            style={{ 
              height: 'calc(100% - 80px)', 
              borderRight: 0,
              padding: '12px 8px'
            }}
            items={menuItems}
          />
        </Sider>
        <Layout style={{ padding: '0' }}>
          <Content className="app-content">
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
            </Routes>
          </Content>
        </Layout>
      </Layout>
    </Layout>
  )
}

export default App

