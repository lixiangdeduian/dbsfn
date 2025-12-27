import React, { useEffect, useState } from 'react'
import { Table, Button, Space, message, Tag, Select } from 'antd'
import { PlusOutlined } from '@ant-design/icons'
import { useNavigate, useLocation } from 'react-router-dom'
import { invoiceAPI } from '../utils/api'

function InvoiceList() {
  const navigate = useNavigate()
  const location = useLocation()
  const [loading, setLoading] = useState(false)
  const [data, setData] = useState([])
  const [statusFilter, setStatusFilter] = useState(null)
  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 20,
    total: 0,
  })

  useEffect(() => {
    // 如果从就诊页面跳转过来，带有encounter_id过滤
    if (location.state?.encounter_id) {
      fetchData(location.state.encounter_id)
    } else {
      fetchData()
    }
  }, [pagination.current, pagination.pageSize, statusFilter])

  const fetchData = async (encounterId = null) => {
    try {
      setLoading(true)
      const params = {
        page: pagination.current,
        per_page: pagination.pageSize,
        status: statusFilter,
      }
      if (encounterId) {
        params.encounter_id = encounterId
      }
      const result = await invoiceAPI.getList(params)
      setData(result.invoices)
      setPagination({
        ...pagination,
        total: result.total,
      })
    } catch (error) {
      console.error('Failed to fetch invoices:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleVoid = async (id) => {
    try {
      await invoiceAPI.void(id)
      message.success('作废成功')
      fetchData()
    } catch (error) {
      console.error('Failed to void invoice:', error)
    }
  }

  const getStatusTag = (status) => {
    const statusConfig = {
      OPEN: { color: 'orange', text: '未结清' },
      PARTIALLY_PAID: { color: 'blue', text: '部分已付' },
      PAID: { color: 'green', text: '已付清' },
      VOID: { color: 'red', text: '已作废' },
    }
    const config = statusConfig[status] || { color: 'default', text: status }
    return <Tag color={config.color}>{config.text}</Tag>
  }

  const columns = [
    {
      title: '发票号',
      dataIndex: 'invoice_no',
      key: 'invoice_no',
    },
    {
      title: '患者姓名',
      dataIndex: 'patient_name',
      key: 'patient_name',
    },
    {
      title: '开票时间',
      dataIndex: 'issued_at',
      key: 'issued_at',
    },
    {
      title: '总金额',
      dataIndex: 'total_amount',
      key: 'total_amount',
      render: (amount) => `¥${amount.toFixed(2)}`,
    },
    {
      title: '已付金额',
      dataIndex: 'paid_amount',
      key: 'paid_amount',
      render: (amount) => `¥${amount.toFixed(2)}`,
    },
    {
      title: '剩余金额',
      dataIndex: 'remaining_amount',
      key: 'remaining_amount',
      render: (amount) => `¥${amount.toFixed(2)}`,
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
          {(record.status === 'OPEN' || record.status === 'PARTIALLY_PAID') && (
            <>
              <Button
                type="link"
                onClick={() =>
                  navigate('/payments/new', {
                    state: { invoice: record },
                  })
                }
              >
                收款
              </Button>
              <Button type="link" danger onClick={() => handleVoid(record.invoice_id)}>
                作废
              </Button>
            </>
          )}
        </Space>
      ),
    },
  ]

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">收费管理</h1>
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
            <Select.Option value="OPEN">未结清</Select.Option>
            <Select.Option value="PARTIALLY_PAID">部分已付</Select.Option>
            <Select.Option value="PAID">已付清</Select.Option>
            <Select.Option value="VOID">已作废</Select.Option>
          </Select>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => navigate('/invoices/new')}>
            开账单
          </Button>
        </Space>
      </div>

      <Table
        columns={columns}
        dataSource={data}
        rowKey="invoice_id"
        loading={loading}
        pagination={pagination}
        onChange={(newPagination) => setPagination(newPagination)}
      />
    </div>
  )
}

export default InvoiceList

