import React, { useEffect, useState } from 'react'
import { Table, Button, Input, Space, message, Popconfirm } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined } from '@ant-design/icons'
import { useNavigate } from 'react-router-dom'
import { staffAPI } from '../utils/api'

function StaffList() {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [data, setData] = useState([])
  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 20,
    total: 0,
  })
  const [searchText, setSearchText] = useState('')

  useEffect(() => {
    fetchData()
  }, [pagination.current, pagination.pageSize])

  const fetchData = async () => {
    try {
      setLoading(true)
      const result = await staffAPI.getList({
        page: pagination.current,
        per_page: pagination.pageSize,
        search: searchText,
      })
      setData(result.staff)
      setPagination({
        ...pagination,
        total: result.total,
      })
    } catch (error) {
      console.error('Failed to fetch staff:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleSearch = () => {
    setPagination({ ...pagination, current: 1 })
    fetchData()
  }

  const handleDelete = async (id) => {
    try {
      await staffAPI.delete(id)
      message.success('删除成功')
      fetchData()
    } catch (error) {
      console.error('Failed to delete staff:', error)
    }
  }

  const columns = [
    {
      title: '工号',
      dataIndex: 'staff_no',
      key: 'staff_no',
    },
    {
      title: '姓名',
      dataIndex: 'staff_name',
      key: 'staff_name',
    },
    {
      title: '性别',
      dataIndex: 'gender',
      key: 'gender',
      render: (gender) => {
        const genderMap = { M: '男', F: '女', U: '未知' }
        return genderMap[gender] || gender
      },
    },
    {
      title: '职称',
      dataIndex: 'title',
      key: 'title',
    },
    {
      title: '联系电话',
      dataIndex: 'phone',
      key: 'phone',
    },
    {
      title: '所属科室',
      dataIndex: 'departments',
      key: 'departments',
      render: (departments) =>
        departments?.map((dept) => dept.department_name).join(', ') || '-',
    },
    {
      title: '操作',
      key: 'action',
      render: (_, record) => (
        <Space>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => navigate(`/staff/${record.staff_id}/edit`)}
          >
            编辑
          </Button>
          <Popconfirm
            title="确定要删除这个员工吗?"
            onConfirm={() => handleDelete(record.staff_id)}
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
        <h1 className="page-title">员工管理</h1>
      </div>

      <div className="search-form">
        <Space>
          <Input
            placeholder="搜索员工姓名、工号、电话"
            style={{ width: 300 }}
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            onPressEnter={handleSearch}
          />
          <Button icon={<SearchOutlined />} onClick={handleSearch}>
            搜索
          </Button>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => navigate('/staff/new')}>
            新建员工
          </Button>
        </Space>
      </div>

      <Table
        columns={columns}
        dataSource={data}
        rowKey="staff_id"
        loading={loading}
        pagination={pagination}
        onChange={(newPagination) => setPagination(newPagination)}
      />
    </div>
  )
}

export default StaffList

