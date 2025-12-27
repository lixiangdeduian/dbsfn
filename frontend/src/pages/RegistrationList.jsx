import React, { useEffect, useState } from 'react'
import { Table, Button, Space, message, Popconfirm, Select, Tag } from 'antd'
import { PlusOutlined } from '@ant-design/icons'
import { useNavigate } from 'react-router-dom'
import { registrationAPI } from '../utils/api'

function RegistrationList() {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [data, setData] = useState([])
  const [statusFilter, setStatusFilter] = useState(null)
  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 20,
    total: 0,
  })

  useEffect(() => {
    fetchData()
  }, [pagination.current, pagination.pageSize, statusFilter])

  const fetchData = async () => {
    try {
      setLoading(true)
      const result = await registrationAPI.getList({
        page: pagination.current,
        per_page: pagination.pageSize,
        status: statusFilter,
      })
      setData(result.registrations)
      setPagination({
        ...pagination,
        total: result.total,
      })
    } catch (error) {
      console.error('Failed to fetch registrations:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleCancel = async (id) => {
    try {
      await registrationAPI.cancel(id)
      message.success('取消成功')
      fetchData()
    } catch (error) {
      console.error('Failed to cancel registration:', error)
    }
  }

  const getStatusTag = (status) => {
    const statusConfig = {
      CONFIRMED: { color: 'green', text: '已确认' },
      CANCELLED: { color: 'red', text: '已取消' },
      COMPLETED: { color: 'blue', text: '已完成' },
    }
    const config = statusConfig[status] || { color: 'default', text: status }
    return <Tag color={config.color}>{config.text}</Tag>
  }

  const columns = [
    {
      title: '挂号单号',
      dataIndex: 'registration_no',
      key: 'registration_no',
    },
    {
      title: '患者姓名',
      dataIndex: 'patient_name',
      key: 'patient_name',
    },
    {
      title: '联系电话',
      dataIndex: 'patient_phone',
      key: 'patient_phone',
    },
    {
      title: '科室',
      dataIndex: 'department_name',
      key: 'department_name',
    },
    {
      title: '医生',
      dataIndex: 'doctor_name',
      key: 'doctor_name',
    },
    {
      title: '就诊日期',
      dataIndex: 'schedule_date',
      key: 'schedule_date',
    },
    {
      title: '就诊时间',
      dataIndex: 'start_time',
      key: 'start_time',
    },
    {
      title: '挂号时间',
      dataIndex: 'registered_at',
      key: 'registered_at',
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      render: (status) => getStatusTag(status),
    },
    {
      title: '操作',
      key: 'action',
      render: (_, record) => (
        <Space>
          {record.status === 'CONFIRMED' && (
            <>
              <Button
                type="link"
                onClick={() =>
                  navigate('/encounters/new', {
                    state: { registration: record },
                  })
                }
              >
                到院登记
              </Button>
              <Popconfirm
                title="确定要取消这个挂号吗?"
                onConfirm={() => handleCancel(record.registration_id)}
                okText="确定"
                cancelText="取消"
              >
                <Button type="link" danger>
                  取消挂号
                </Button>
              </Popconfirm>
            </>
          )}
        </Space>
      ),
    },
  ]

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">挂号管理</h1>
      </div>

      <div className="search-form">
        <Space>
          <Select
            placeholder="状态筛选"
            style={{ width: 120 }}
            allowClear
            value={statusFilter}
            onChange={setStatusFilter}
          >
            <Select.Option value="CONFIRMED">已确认</Select.Option>
            <Select.Option value="CANCELLED">已取消</Select.Option>
            <Select.Option value="COMPLETED">已完成</Select.Option>
          </Select>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => navigate('/registrations/new')}
          >
            预约挂号
          </Button>
        </Space>
      </div>

      <Table
        columns={columns}
        dataSource={data}
        rowKey="registration_id"
        loading={loading}
        pagination={pagination}
        onChange={(newPagination) => setPagination(newPagination)}
      />
    </div>
  )
}

export default RegistrationList

