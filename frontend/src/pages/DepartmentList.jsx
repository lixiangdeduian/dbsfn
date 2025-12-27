import React, { useEffect, useState } from 'react'
import { Table, Button, Space, message, Popconfirm, Form, Input, Modal } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { departmentAPI } from '../utils/api'

function DepartmentList() {
  const [loading, setLoading] = useState(false)
  const [data, setData] = useState([])
  const [modalVisible, setModalVisible] = useState(false)
  const [editingId, setEditingId] = useState(null)
  const [form] = Form.useForm()

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      setLoading(true)
      const result = await departmentAPI.getList()
      setData(result.departments)
    } catch (error) {
      console.error('Failed to fetch departments:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleAdd = () => {
    form.resetFields()
    setEditingId(null)
    setModalVisible(true)
  }

  const handleEdit = (record) => {
    form.setFieldsValue(record)
    setEditingId(record.department_id)
    setModalVisible(true)
  }

  const handleDelete = async (id) => {
    try {
      await departmentAPI.delete(id)
      message.success('删除成功')
      fetchData()
    } catch (error) {
      console.error('Failed to delete department:', error)
    }
  }

  const handleSubmit = async () => {
    try {
      const values = await form.validateFields()
      if (editingId) {
        await departmentAPI.update(editingId, values)
        message.success('更新成功')
      } else {
        await departmentAPI.create(values)
        message.success('创建成功')
      }
      setModalVisible(false)
      fetchData()
    } catch (error) {
      console.error('Failed to save department:', error)
    }
  }

  const columns = [
    {
      title: '科室编码',
      dataIndex: 'department_code',
      key: 'department_code',
    },
    {
      title: '科室名称',
      dataIndex: 'department_name',
      key: 'department_name',
    },
    {
      title: '状态',
      dataIndex: 'is_active',
      key: 'is_active',
      render: (isActive) => (isActive ? '启用' : '停用'),
    },
    {
      title: '操作',
      key: 'action',
      render: (_, record) => (
        <Space>
          <Button type="link" icon={<EditOutlined />} onClick={() => handleEdit(record)}>
            编辑
          </Button>
          <Popconfirm
            title="确定要删除这个科室吗?"
            onConfirm={() => handleDelete(record.department_id)}
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
        <h1 className="page-title">科室管理</h1>
      </div>

      <div className="search-form">
        <Button type="primary" icon={<PlusOutlined />} onClick={handleAdd}>
          新建科室
        </Button>
      </div>

      <Table columns={columns} dataSource={data} rowKey="department_id" loading={loading} />

      <Modal
        title={editingId ? '编辑科室' : '新建科室'}
        open={modalVisible}
        onOk={handleSubmit}
        onCancel={() => setModalVisible(false)}
      >
        <Form form={form} layout="vertical">
          <Form.Item
            name="department_code"
            label="科室编码"
            rules={[{ required: true, message: '请输入科室编码' }]}
          >
            <Input placeholder="请输入科室编码" />
          </Form.Item>

          <Form.Item
            name="department_name"
            label="科室名称"
            rules={[{ required: true, message: '请输入科室名称' }]}
          >
            <Input placeholder="请输入科室名称" />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  )
}

export default DepartmentList

