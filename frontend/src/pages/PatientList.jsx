import React, { useEffect, useState } from 'react'
import { Table, Button, Input, Space, message, Popconfirm } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined } from '@ant-design/icons'
import { useNavigate } from 'react-router-dom'
import { patientAPI } from '../utils/api'

function PatientList() {
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
      const result = await patientAPI.getList({
        page: pagination.current,
        per_page: pagination.pageSize,
        search: searchText,
      })
      setData(result.patients)
      setPagination({
        ...pagination,
        total: result.total,
      })
    } catch (error) {
      console.error('Failed to fetch patients:', error)
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
      await patientAPI.delete(id)
      message.success('删除成功')
      fetchData()
    } catch (error) {
      console.error('Failed to delete patient:', error)
    }
  }

  const columns = [
    {
      title: '患者编号',
      dataIndex: 'patient_no',
      key: 'patient_no',
    },
    {
      title: '姓名',
      dataIndex: 'patient_name',
      key: 'patient_name',
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
      title: '联系电话',
      dataIndex: 'phone',
      key: 'phone',
    },
    {
      title: '身份证号',
      dataIndex: 'id_card_no',
      key: 'id_card_no',
    },
    {
      title: '血型',
      dataIndex: 'blood_type',
      key: 'blood_type',
    },
    {
      title: '操作',
      key: 'action',
      render: (_, record) => (
        <Space>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => navigate(`/patients/${record.patient_id}/edit`)}
          >
            编辑
          </Button>
          <Popconfirm
            title="确定要删除这个患者吗?"
            onConfirm={() => handleDelete(record.patient_id)}
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
        <h1 className="page-title">患者管理</h1>
        <Button 
          type="primary" 
          icon={<PlusOutlined />} 
          onClick={() => navigate('/patients/new')}
          size="large"
          style={{ 
            height: '44px',
            fontSize: '15px',
            borderRadius: '8px',
            boxShadow: '0 4px 12px rgba(30, 136, 229, 0.3)'
          }}
        >
          新建患者
        </Button>
      </div>

      <div className="search-form">
        <Space size="middle">
          <Input
            placeholder="🔍 搜索患者姓名、编号、电话、身份证号"
            style={{ 
              width: 400,
              height: '40px',
              fontSize: '14px'
            }}
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            onPressEnter={handleSearch}
            allowClear
          />
          <Button 
            icon={<SearchOutlined />} 
            onClick={handleSearch}
            size="large"
            style={{ height: '40px' }}
          >
            搜索
          </Button>
        </Space>
      </div>

      <Table
        columns={columns}
        dataSource={data}
        rowKey="patient_id"
        loading={loading}
        pagination={{
          ...pagination,
          showSizeChanger: true,
          showTotal: (total) => `共 ${total} 条记录`,
          size: 'default'
        }}
        onChange={(newPagination) => setPagination(newPagination)}
        size="middle"
        style={{
          background: 'white',
          borderRadius: '12px',
          overflow: 'hidden'
        }}
      />
    </div>
  )
}

export default PatientList

