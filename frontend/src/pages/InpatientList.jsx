import React, { useState, useEffect } from 'react'
import { Table, Button, Card, message, Tag, Space } from 'antd'
import { HomeOutlined, UserAddOutlined } from '@ant-design/icons'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'

function InpatientList() {
  const [inpatients, setInpatients] = useState([])
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()

  const fetchInpatients = async () => {
    setLoading(true)
    try {
      const response = await axios.get('/api/inpatients')
      setInpatients(response.data.data || [])
    } catch (error) {
      message.error('获取住院患者列表失败')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchInpatients()
  }, [])

  const columns = [
    {
      title: '住院号',
      dataIndex: 'admission_no',
      key: 'admission_no',
    },
    {
      title: '患者编号',
      dataIndex: 'patient_no',
      key: 'patient_no',
    },
    {
      title: '患者姓名',
      dataIndex: 'patient_name',
      key: 'patient_name',
    },
    {
      title: '科室',
      dataIndex: 'department_name',
      key: 'department_name',
    },
    {
      title: '主治医生',
      dataIndex: 'attending_doctor_name',
      key: 'attending_doctor_name',
    },
    {
      title: '床位',
      dataIndex: 'bed_no',
      key: 'bed_no',
      render: (text, record) => 
        text ? `${record.ward_name || ''} - ${text}` : '未分配'
    },
    {
      title: '入院时间',
      dataIndex: 'admitted_at',
      key: 'admitted_at',
      render: (text) => text ? new Date(text).toLocaleString() : '-'
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      render: (status) => {
        const statusMap = {
          'ADMITTED': { color: 'green', text: '在院' },
          'DISCHARGED': { color: 'blue', text: '已出院' },
          'TRANSFERRED': { color: 'orange', text: '已转院' }
        }
        const s = statusMap[status] || { color: 'default', text: status }
        return <Tag color={s.color}>{s.text}</Tag>
      }
    }
  ]

  return (
    <div style={{ padding: '24px' }}>
      <Card 
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <HomeOutlined style={{ fontSize: '20px', color: '#1890ff' }} />
            <span>住院管理</span>
          </div>
        }
        extra={
          <Space>
            <Button 
              type="primary" 
              icon={<UserAddOutlined />}
              onClick={() => navigate('/inpatients/new')}
            >
              办理入院
            </Button>
            <Button onClick={fetchInpatients}>刷新</Button>
          </Space>
        }
      >
        <Table 
          columns={columns}
          dataSource={inpatients}
          rowKey="admission_id"
          loading={loading}
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            showTotal: (total) => `共 ${total} 条记录`
          }}
        />
      </Card>
    </div>
  )
}

export default InpatientList

