import React, { useEffect, useState } from 'react'
import { Card, Row, Col, Statistic, Spin } from 'antd'
import {
  UserOutlined,
  FileTextOutlined,
  DollarOutlined,
  CalendarOutlined,
} from '@ant-design/icons'
import { statisticsAPI } from '../utils/api'

function Dashboard() {
  const [loading, setLoading] = useState(true)
  const [data, setData] = useState(null)

  useEffect(() => {
    fetchDashboardData()
  }, [])

  const fetchDashboardData = async () => {
    try {
      setLoading(true)
      const result = await statisticsAPI.getDashboard()
      setData(result)
    } catch (error) {
      console.error('Failed to fetch dashboard data:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '50px' }}>
        <Spin size="large" />
      </div>
    )
  }

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">数据仪表盘</h1>
        <div style={{ 
          fontSize: '14px', 
          color: '#64748b',
          background: '#f0f9ff',
          padding: '8px 16px',
          borderRadius: '8px',
          border: '1px solid #bae6fd'
        }}>
          📊 实时数据统计
        </div>
      </div>

      <div style={{
        background: 'linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%)',
        padding: '24px',
        borderRadius: '12px',
        marginBottom: 24,
        border: '1px solid #bae6fd'
      }}>
        <h3 style={{ 
          marginBottom: 20,
          color: '#1e3a8a',
          fontSize: '18px',
          fontWeight: 600,
          display: 'flex',
          alignItems: 'center',
          gap: '8px'
        }}>
          <span style={{ fontSize: '20px' }}>📈</span>
          今日数据概览
        </h3>
        <Row gutter={[20, 20]}>
          <Col xs={24} sm={12} lg={6}>
            <Card className="stat-card" hoverable>
              <div style={{ 
                fontSize: '48px', 
                marginBottom: '12px',
                background: 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                backgroundClip: 'text'
              }}>
                👥
              </div>
              <Statistic
                title={<span style={{ fontSize: '15px', fontWeight: 500 }}>今日就诊人次</span>}
                value={data?.today?.encounters || 0}
                valueStyle={{ 
                  fontSize: '36px',
                  fontWeight: 700
                }}
                suffix={<span style={{ fontSize: '16px', color: '#64748b' }}>人次</span>}
              />
            </Card>
          </Col>
          <Col xs={24} sm={12} lg={6}>
            <Card className="stat-card" hoverable>
              <div style={{ 
                fontSize: '48px', 
                marginBottom: '12px',
                background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                backgroundClip: 'text'
              }}>
                📅
              </div>
              <Statistic
                title={<span style={{ fontSize: '15px', fontWeight: 500 }}>今日挂号数</span>}
                value={data?.today?.registrations || 0}
                valueStyle={{ 
                  fontSize: '36px',
                  fontWeight: 700
                }}
                suffix={<span style={{ fontSize: '16px', color: '#64748b' }}>个</span>}
              />
            </Card>
          </Col>
          <Col xs={24} sm={12} lg={6}>
            <Card className="stat-card" hoverable>
              <div style={{ 
                fontSize: '48px', 
                marginBottom: '12px',
                background: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                backgroundClip: 'text'
              }}>
                💰
              </div>
              <Statistic
                title={<span style={{ fontSize: '15px', fontWeight: 500 }}>今日收入</span>}
                value={data?.today?.revenue || 0}
                precision={2}
                valueStyle={{ 
                  fontSize: '36px',
                  fontWeight: 700
                }}
                suffix={<span style={{ fontSize: '16px', color: '#64748b' }}>元</span>}
              />
            </Card>
          </Col>
          <Col xs={24} sm={12} lg={6}>
            <Card className="stat-card" hoverable>
              <div style={{ 
                fontSize: '48px', 
                marginBottom: '12px',
                background: 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                backgroundClip: 'text'
              }}>
                📄
              </div>
              <Statistic
                title={<span style={{ fontSize: '15px', fontWeight: 500 }}>待缴费发票</span>}
                value={data?.unpaid_invoices || 0}
                valueStyle={{ 
                  fontSize: '36px',
                  fontWeight: 700
                }}
                suffix={<span style={{ fontSize: '16px', color: '#64748b' }}>张</span>}
              />
            </Card>
          </Col>
        </Row>
      </div>

      <div style={{
        background: 'linear-gradient(135deg, #fef3c7 0%, #fde68a 100%)',
        padding: '24px',
        borderRadius: '12px',
        border: '1px solid #fcd34d'
      }}>
        <h3 style={{ 
          marginBottom: 20,
          color: '#92400e',
          fontSize: '18px',
          fontWeight: 600,
          display: 'flex',
          alignItems: 'center',
          gap: '8px'
        }}>
          <span style={{ fontSize: '20px' }}>📊</span>
          本月数据汇总
        </h3>
        <Row gutter={[20, 20]}>
          <Col xs={24} md={12}>
            <Card 
              className="stat-card" 
              hoverable
              style={{ 
                background: 'white',
                height: '100%'
              }}
            >
              <div style={{ 
                fontSize: '48px', 
                marginBottom: '12px',
                background: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                backgroundClip: 'text'
              }}>
                📊
              </div>
              <Statistic
                title={<span style={{ fontSize: '16px', fontWeight: 500 }}>本月就诊人次</span>}
                value={data?.month?.encounters || 0}
                valueStyle={{ 
                  fontSize: '40px',
                  fontWeight: 700
                }}
                suffix={<span style={{ fontSize: '18px', color: '#64748b' }}>人次</span>}
              />
            </Card>
          </Col>
          <Col xs={24} md={12}>
            <Card 
              className="stat-card" 
              hoverable
              style={{ 
                background: 'white',
                height: '100%'
              }}
            >
              <div style={{ 
                fontSize: '48px', 
                marginBottom: '12px',
                background: 'linear-gradient(135deg, #06b6d4 0%, #0891b2 100%)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                backgroundClip: 'text'
              }}>
                💵
              </div>
              <Statistic
                title={<span style={{ fontSize: '16px', fontWeight: 500 }}>本月总收入</span>}
                value={data?.month?.revenue || 0}
                precision={2}
                valueStyle={{ 
                  fontSize: '40px',
                  fontWeight: 700
                }}
                suffix={<span style={{ fontSize: '18px', color: '#64748b' }}>元</span>}
              />
            </Card>
          </Col>
        </Row>
      </div>
    </div>
  )
}

export default Dashboard

