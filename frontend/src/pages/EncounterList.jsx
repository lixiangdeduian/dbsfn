import React, { useEffect, useState } from 'react'
import { Table, Button, Space, message, Tag, Select } from 'antd'
import { PlusOutlined } from '@ant-design/icons'
import { useNavigate } from 'react-router-dom'
import { encounterAPI } from '../utils/api'

function EncounterList() {
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
      const result = await encounterAPI.getList({
        page: pagination.current,
        per_page: pagination.pageSize,
        status: statusFilter,
      })
      setData(result.encounters)
      setPagination({
        ...pagination,
        total: result.total,
      })
    } catch (error) {
      console.error('Failed to fetch encounters:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleClose = async (id) => {
    try {
      await encounterAPI.close(id)
      message.success('结束就诊成功')
      fetchData()
    } catch (error) {
      console.error('Failed to close encounter:', error)
    }
  }

  const getStatusTag = (status) => {
    const statusConfig = {
      OPEN: { color: 'green', text: '进行中' },
      CLOSED: { color: 'blue', text: '已结束' },
      CANCELLED: { color: 'red', text: '已取消' },
    }
    const config = statusConfig[status] || { color: 'default', text: status }
    return <Tag color={config.color}>{config.text}</Tag>
  }

  const columns = [
    {
      title: '就诊号',
      dataIndex: 'encounter_no',
      key: 'encounter_no',
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
      title: '医生',
      dataIndex: 'doctor_name',
      key: 'doctor_name',
    },
    {
      title: '就诊类型',
      dataIndex: 'encounter_type',
      key: 'encounter_type',
      render: (type) => (type === 'OUTPATIENT' ? '门诊' : '住院'),
    },
    {
      title: '开始时间',
      dataIndex: 'started_at',
      key: 'started_at',
    },
    {
      title: '结束时间',
      dataIndex: 'ended_at',
      key: 'ended_at',
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
          {record.status === 'OPEN' && (
            <>
              <Button
                type="link"
                onClick={() =>
                  navigate('/invoices/new', {
                    state: { encounter: record },
                  })
                }
              >
                开账单
              </Button>
              <Button type="link" onClick={() => handleClose(record.encounter_id)}>
                结束就诊
              </Button>
            </>
          )}
          {record.status === 'CLOSED' && (
            <Button
              type="link"
              onClick={() =>
                navigate('/invoices', {
                  state: { encounter_id: record.encounter_id },
                })
              }
            >
              查看账单
            </Button>
          )}
        </Space>
      ),
    },
  ]

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">就诊管理</h1>
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
            <Select.Option value="OPEN">进行中</Select.Option>
            <Select.Option value="CLOSED">已结束</Select.Option>
            <Select.Option value="CANCELLED">已取消</Select.Option>
          </Select>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => navigate('/encounters/new')}>
            到院登记
          </Button>
        </Space>
      </div>

      <Table
        columns={columns}
        dataSource={data}
        rowKey="encounter_id"
        loading={loading}
        pagination={pagination}
        onChange={(newPagination) => setPagination(newPagination)}
      />
    </div>
  )
}

export default EncounterList

