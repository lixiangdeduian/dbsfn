import React, { useState, useEffect } from 'react'
import { Table, Button, Card, message, Tag, Space, Modal } from 'antd'
import { MedicineBoxOutlined, CheckOutlined } from '@ant-design/icons'
import axios from 'axios'

function PharmacyList() {
  const [prescriptions, setPrescriptions] = useState([])
  const [loading, setLoading] = useState(false)

  const fetchPrescriptions = async () => {
    setLoading(true)
    try {
      // 获取待发药处方队列
      const response = await axios.get('/api/pharmacy/queue')
      setPrescriptions(response.data.data || [])
    } catch (error) {
      message.error('获取待发药列表失败')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchPrescriptions()
  }, [])

  const handleDispense = async (prescriptionId) => {
    Modal.confirm({
      title: '确认发药',
      content: '确定要发放此处方吗？',
      onOk: async () => {
        try {
          await axios.post('/api/procedures/dispense/create', {
            prescription_id: prescriptionId
          })
          message.success('发药成功')
          fetchPrescriptions()
        } catch (error) {
          message.error(error.response?.data?.error || '发药失败')
        }
      }
    })
  }

  const columns = [
    {
      title: '处方编号',
      dataIndex: 'prescription_no',
      key: 'prescription_no',
    },
    {
      title: '就诊编号',
      dataIndex: 'encounter_no',
      key: 'encounter_no',
    },
    {
      title: '患者姓名',
      dataIndex: 'patient_name',
      key: 'patient_name',
    },
    {
      title: '开方医生',
      dataIndex: 'doctor_name',
      key: 'doctor_name',
    },
    {
      title: '开方时间',
      dataIndex: 'issued_at',
      key: 'issued_at',
      render: (text) => text ? new Date(text).toLocaleString() : '-'
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      render: (status) => {
        const statusMap = {
          'ISSUED': { color: 'blue', text: '待发药' },
          'DISPENSED': { color: 'green', text: '已发药' },
          'CANCELLED': { color: 'red', text: '已取消' }
        }
        const s = statusMap[status] || { color: 'default', text: status }
        return <Tag color={s.color}>{s.text}</Tag>
      }
    },
    {
      title: '金额',
      dataIndex: 'total_amount',
      key: 'total_amount',
      render: (amount) => `¥${(amount || 0).toFixed(2)}`
    },
    {
      title: '操作',
      key: 'action',
      render: (_, record) => (
        <Space>
          {record.status === 'ISSUED' && (
            <Button 
              type="primary"
              size="small"
              icon={<CheckOutlined />}
              onClick={() => handleDispense(record.prescription_id)}
            >
              发药
            </Button>
          )}
        </Space>
      )
    }
  ]

  return (
    <div style={{ padding: '24px' }}>
      <Card 
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <MedicineBoxOutlined style={{ fontSize: '20px', color: '#1890ff' }} />
            <span>药房管理 - 待发药队列</span>
          </div>
        }
        extra={
          <Button onClick={fetchPrescriptions}>刷新</Button>
        }
      >
        <Table 
          columns={columns}
          dataSource={prescriptions}
          rowKey="prescription_id"
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

export default PharmacyList

