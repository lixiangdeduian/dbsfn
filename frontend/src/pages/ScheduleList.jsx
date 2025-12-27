import React, { useEffect, useState } from 'react'
import { Table, Button, Space, message, Popconfirm, DatePicker, Select } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { useNavigate } from 'react-router-dom'
import { scheduleAPI, departmentAPI } from '../utils/api'
import dayjs from 'dayjs'

function ScheduleList() {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [data, setData] = useState([])
  const [departments, setDepartments] = useState([])
  const [filters, setFilters] = useState({
    start_date: dayjs().format('YYYY-MM-DD'),
    end_date: dayjs().add(7, 'day').format('YYYY-MM-DD'),
    department_id: null,
  })
  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 20,
    total: 0,
  })

  useEffect(() => {
    fetchDepartments()
  }, [])

  useEffect(() => {
    fetchData()
  }, [pagination.current, pagination.pageSize, filters])

  const fetchDepartments = async () => {
    try {
      const result = await departmentAPI.getList({ is_active: 1 })
      setDepartments(result.departments)
    } catch (error) {
      console.error('Failed to fetch departments:', error)
    }
  }

  const fetchData = async () => {
    try {
      setLoading(true)
      const result = await scheduleAPI.getList({
        page: pagination.current,
        per_page: pagination.pageSize,
        ...filters,
      })
      setData(result.schedules)
      setPagination({
        ...pagination,
        total: result.total,
      })
    } catch (error) {
      console.error('Failed to fetch schedules:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async (id) => {
    try {
      await scheduleAPI.delete(id)
      message.success('删除成功')
      fetchData()
    } catch (error) {
      console.error('Failed to delete schedule:', error)
    }
  }

  const columns = [
    {
      title: '日期',
      dataIndex: 'schedule_date',
      key: 'schedule_date',
    },
    {
      title: '时间',
      key: 'time',
      render: (_, record) => `${record.start_time} - ${record.end_time}`,
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
      title: '职称',
      dataIndex: 'doctor_title',
      key: 'doctor_title',
    },
    {
      title: '号源',
      key: 'quota',
      render: (_, record) => `${record.booked_count || 0} / ${record.quota}`,
    },
    {
      title: '挂号费',
      dataIndex: 'registration_fee',
      key: 'registration_fee',
      render: (fee) => `¥${fee}`,
    },
    {
      title: '操作',
      key: 'action',
      render: (_, record) => (
        <Space>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => navigate(`/schedules/${record.schedule_id}/edit`)}
          >
            编辑
          </Button>
          <Popconfirm
            title="确定要删除这个排班吗?"
            onConfirm={() => handleDelete(record.schedule_id)}
            okText="确定"
            cancelText="取消"
          >
            <Button type="link" danger icon={<DeleteOutlined />}>
              删除
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ]

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">排班管理</h1>
      </div>

      <div className="search-form">
        <Space>
          <DatePicker
            placeholder="开始日期"
            value={filters.start_date ? dayjs(filters.start_date) : null}
            onChange={(date) =>
              setFilters({ ...filters, start_date: date ? date.format('YYYY-MM-DD') : null })
            }
          />
          <DatePicker
            placeholder="结束日期"
            value={filters.end_date ? dayjs(filters.end_date) : null}
            onChange={(date) =>
              setFilters({ ...filters, end_date: date ? date.format('YYYY-MM-DD') : null })
            }
          />
          <Select
            placeholder="选择科室"
            style={{ width: 200 }}
            allowClear
            value={filters.department_id}
            onChange={(value) => setFilters({ ...filters, department_id: value })}
          >
            {departments.map((dept) => (
              <Select.Option key={dept.department_id} value={dept.department_id}>
                {dept.department_name}
              </Select.Option>
            ))}
          </Select>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => navigate('/schedules/new')}>
            新建排班
          </Button>
        </Space>
      </div>

      <Table
        columns={columns}
        dataSource={data}
        rowKey="schedule_id"
        loading={loading}
        pagination={pagination}
        onChange={(newPagination) => setPagination(newPagination)}
      />
    </div>
  )
}

export default ScheduleList

