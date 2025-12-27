import React, { useEffect, useState } from 'react'
import { Form, Input, Select, DatePicker, Button, Card, message } from 'antd'
import { useNavigate, useParams } from 'react-router-dom'
import { staffAPI, departmentAPI } from '../utils/api'
import dayjs from 'dayjs'

const { Option } = Select

function StaffForm() {
  const navigate = useNavigate()
  const { id } = useParams()
  const [form] = Form.useForm()
  const [loading, setLoading] = useState(false)
  const [departments, setDepartments] = useState([])

  useEffect(() => {
    fetchDepartments()
    if (id) {
      fetchStaff()
    }
  }, [id])

  const fetchDepartments = async () => {
    try {
      const result = await departmentAPI.getList({ is_active: 1 })
      setDepartments(result.departments)
    } catch (error) {
      console.error('Failed to fetch departments:', error)
    }
  }

  const fetchStaff = async () => {
    try {
      const data = await staffAPI.getDetail(id)
      const departmentIds = data.departments?.map((d) => d.department_id) || []
      form.setFieldsValue({
        ...data,
        hire_date: data.hire_date ? dayjs(data.hire_date) : null,
        department_ids: departmentIds,
      })
    } catch (error) {
      console.error('Failed to fetch staff:', error)
    }
  }

  const handleSubmit = async (values) => {
    try {
      setLoading(true)
      const formData = {
        ...values,
        hire_date: values.hire_date ? values.hire_date.format('YYYY-MM-DD') : null,
      }

      if (id) {
        await staffAPI.update(id, formData)
        message.success('更新成功')
      } else {
        await staffAPI.create(formData)
        message.success('创建成功')
      }
      navigate('/staff')
    } catch (error) {
      console.error('Failed to save staff:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">{id ? '编辑员工' : '新建员工'}</h1>
      </div>

      <Card>
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSubmit}
          initialValues={{
            gender: 'U',
          }}
        >
          <Form.Item
            name="staff_name"
            label="姓名"
            rules={[{ required: true, message: '请输入员工姓名' }]}
          >
            <Input placeholder="请输入员工姓名" />
          </Form.Item>

          <Form.Item name="gender" label="性别" rules={[{ required: true }]}>
            <Select>
              <Option value="M">男</Option>
              <Option value="F">女</Option>
              <Option value="U">未知</Option>
            </Select>
          </Form.Item>

          <Form.Item name="title" label="职称">
            <Input placeholder="请输入职称" />
          </Form.Item>

          <Form.Item name="phone" label="联系电话">
            <Input placeholder="请输入联系电话" />
          </Form.Item>

          <Form.Item name="email" label="邮箱">
            <Input placeholder="请输入邮箱" />
          </Form.Item>

          <Form.Item name="id_card_no" label="身份证号">
            <Input placeholder="请输入身份证号" />
          </Form.Item>

          <Form.Item name="hire_date" label="入职日期">
            <DatePicker style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item name="department_ids" label="所属科室">
            <Select mode="multiple" placeholder="请选择科室">
              {departments.map((dept) => (
                <Select.Option key={dept.department_id} value={dept.department_id}>
                  {dept.department_name}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>

          <Form.Item>
            <Button type="primary" htmlType="submit" loading={loading} style={{ marginRight: 8 }}>
              提交
            </Button>
            <Button onClick={() => navigate('/staff')}>取消</Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  )
}

export default StaffForm

