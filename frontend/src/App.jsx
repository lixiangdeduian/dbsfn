import React from 'react'
import { Routes, Route } from 'react-router-dom'
import { Layout, Menu, Typography } from 'antd'
import {
  DashboardOutlined,
  UserOutlined,
  CalendarOutlined,
  FileTextOutlined,
  DollarOutlined,
  TeamOutlined,
  ApartmentOutlined,
  BarChartOutlined,
} from '@ant-design/icons'
import { Link, useLocation } from 'react-router-dom'

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

const { Header, Sider, Content } = Layout
const { Title } = Typography

function App() {
  const location = useLocation()

  const menuItems = [
    {
      key: '/',
      icon: <DashboardOutlined />,
      label: <Link to="/">仪表盘</Link>,
    },
    {
      key: '/patients',
      icon: <UserOutlined />,
      label: <Link to="/patients">患者管理</Link>,
    },
    {
      key: '/schedules',
      icon: <CalendarOutlined />,
      label: <Link to="/schedules">排班管理</Link>,
    },
    {
      key: '/registrations',
      icon: <FileTextOutlined />,
      label: <Link to="/registrations">挂号管理</Link>,
    },
    {
      key: '/encounters',
      icon: <FileTextOutlined />,
      label: <Link to="/encounters">就诊管理</Link>,
    },
    {
      key: '/invoices',
      icon: <DollarOutlined />,
      label: <Link to="/invoices">收费管理</Link>,
    },
    {
      key: '/staff',
      icon: <TeamOutlined />,
      label: <Link to="/staff">员工管理</Link>,
    },
    {
      key: '/departments',
      icon: <ApartmentOutlined />,
      label: <Link to="/departments">科室管理</Link>,
    },
    {
      key: '/statistics',
      icon: <BarChartOutlined />,
      label: <Link to="/statistics">统计报表</Link>,
    },
  ]

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

  return (
    <Layout className="app-layout">
      <Header className="app-header">
        <div className="app-logo">社区医院门诊管理系统</div>
        <div style={{ color: 'rgba(255, 255, 255, 0.85)', fontSize: '14px' }}>
          欢迎使用 · 现代化医疗信息管理平台
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
            </Routes>
          </Content>
        </Layout>
      </Layout>
    </Layout>
  )
}

export default App

