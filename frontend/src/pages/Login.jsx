import React, { useState } from 'react'
import { Form, Input, Button, Card, Select, message } from 'antd'
import { UserOutlined, LockOutlined } from '@ant-design/icons'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'

const { Option } = Select

function Login({ onLogin }) {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [form] = Form.useForm()

  const roles = [
    { key: 'admin', name: '超级管理员', color: '#f5222d' },
    { key: 'doctor', name: '医生', color: '#1890ff' },
    { key: 'nurse', name: '护士', color: '#52c41a' },
    { key: 'pharmacist', name: '药剂师', color: '#13c2c2' },
    { key: 'lab_tech', name: '检验技师', color: '#722ed1' },
    { key: 'cashier', name: '收费员', color: '#fa8c16' },
    { key: 'reception', name: '前台接待', color: '#eb2f96' },
    { key: 'patient', name: '患者', color: '#faad14' }
  ]

  const handleSubmit = async (values) => {
    try {
      setLoading(true)
      const response = await axios.post('/api/auth/login', values)
      
      const { token, user } = response.data
      
      // 保存token和用户信息
      localStorage.setItem('token', token)
      localStorage.setItem('user', JSON.stringify(user))
      
      message.success(`登录成功！欢迎您，${user.role_name}`)
      
      // 通知父组件登录成功
      if (onLogin) {
        onLogin(user)
      }
      
      navigate('/')
    } catch (error) {
      message.error(error.response?.data?.error || '登录失败')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg,rgba(4, 168, 250, 0.27) 0%,rgb(109, 178, 219) 100%)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '20px'
    }}>
      <Card
        style={{
          width: '100%',
          maxWidth: '1000px',
          borderRadius: '16px',
          boxShadow: '0 20px 60px rgba(0, 0, 0, 0.3)'
        }}
      >
        <div style={{ textAlign: 'center', marginBottom: '32px' }}>
          <div style={{ fontSize: '48px', marginBottom: '16px' }}>🏥</div>
          <h1 style={{
            fontSize: '40px',
            fontWeight: 700,
            background: 'linear-gradient(135deg,rgb(30, 114, 76) 0%,rgb(42, 152, 73) 100%)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            marginBottom: '8px'
          }}>
            社区医院门诊管理系统
          </h1>
          <p style={{ color: '#64748b', fontSize: '14px' }}>
            Community Hospital Management System
          </p>
        </div>

        <Form
          form={form}
          onFinish={handleSubmit}
          layout="vertical"
          size="large"
          initialValues={{
            role: 'reception'
          }}
        >
          <Form.Item
            name="username"
            label="用户名"
            rules={[{ required: true, message: '请输入用户名' }]}
          >
            <Input 
              prefix={<UserOutlined />} 
              placeholder="请输入用户名" 
            />
          </Form.Item>

          <Form.Item
            name="password"
            label="密码"
            rules={[
              { required: true, message: '请输入密码' },
              { min: 6, message: '密码至少6位' }
            ]}
          >
            <Input.Password 
              prefix={<LockOutlined />} 
              placeholder="请输入密码" 
            />
          </Form.Item>

          <Form.Item
            name="role"
            label="选择角色"
            rules={[{ required: true, message: '请选择登录角色' }]}
          >
            <Select placeholder="请选择您的角色">
              {roles.map(role => (
                <Option key={role.key} value={role.key}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <div style={{
                      width: '8px',
                      height: '8px',
                      borderRadius: '50%',
                      background: role.color
                    }} />
                    <span>{role.name}</span>
                  </div>
                </Option>
              ))}
            </Select>
          </Form.Item>

          <Form.Item>
            <Button 
              type="primary" 
              htmlType="submit" 
              loading={loading}
              block
              style={{
                height: '48px',
                fontSize: '16px',
                fontWeight: 600,
                marginTop: '16px',
                background: 'linear-gradient(135deg,rgba(30, 114, 58, 0.51) 0%,rgb(42, 152, 143) 100%)',
                border: 'none'
              }}
            >
              登录系统
            </Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  )
}

export default Login

