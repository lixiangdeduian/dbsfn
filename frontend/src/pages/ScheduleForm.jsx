import React, { useEffect, useState } from 'react'
import { Form, Select, DatePicker, TimePicker, InputNumber, Button, Card, message } from 'antd'
import { useNavigate, useParams } from 'react-router-dom'
import { scheduleAPI, staffAPI, departmentAPI } from '../utils/api'
import dayjs from 'dayjs'

function ScheduleForm() {
  const navigate = useNavigate()
  const { id } = useParams()
  const [form] = Form.useForm()
  const [loading, setLoading] = useState(false)
  const [doctors, setDoctors] = useState([])
  const [departments, setDepartments] = useState([])

  useEffect(() => {
    fetchDoctors()
    fetchDepartments()
    if (id) {
      fetchSchedule()
    }
  }, [id])

  const fetchDoctors = async () => {
    try {
      const result = await staffAPI.getList({ per_page: 100 })
      setDoctors(result.staff)
    } catch (error) {
      console.error('Failed to fetch doctors:', error)
    }
  }

  const fetchDepartments = async () => {
    try {
      const result = await departmentAPI.getList({ is_active: 1 })
      setDepartments(result.departments)
    } catch (error) {
      console.error('Failed to fetch departments:', error)
    }
  }

  const fetchSchedule = async () => {
    try {
      const data = await scheduleAPI.getDetail(id)
      form.setFieldsValue({
        doctor_id: data.doctor_id,
        department_id: data.department_id,
        schedule_date: data.schedule_date ? dayjs(data.schedule_date) : null,
        start_time: data.start_time ? dayjs(data.start_time, 'HH:mm:ss') : null,
        end_time: data.end_time ? dayjs(data.end_time, 'HH:mm:ss') : null,
        quota: data.quota,
        registration_fee: data.registration_fee,
      })
    } catch (error) {
      console.error('Failed to fetch schedule:', error)
    }
  }

  const handleSubmit = async (values) => {
    try {
      setLoading(true)
      const formData = {
        ...values,
        schedule_date: values.schedule_date.format('YYYY-MM-DD'),
        start_time: values.start_time.format('HH:mm:ss'),
        end_time: values.end_time.format('HH:mm:ss'),
      }

      if (id) {
        await scheduleAPI.update(id, formData)
        message.success('更新成功')
      } else {
        await scheduleAPI.create(formData)
        message.success('创建成功')
      }
      navigate('/schedules')
    } catch (error) {
      console.error('Failed to save schedule:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">{id ? '编辑排班' : '新建排班'}</h1>
      </div>

      <Card>
        <Form form={form} layout="vertical" onFinish={handleSubmit}>
          <Form.Item
            name="doctor_id"
            label="医生"
            rules={[{ required: true, message: '请选择医生' }]}
          >
            <Select placeholder="请选择医生" showSearch optionFilterProp="children">
              {doctors.map((doctor) => (
                <Select.Option key={doctor.staff_id} value={doctor.staff_id}>
                  {doctor.staff_name} - {doctor.title}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>

          <Form.Item
            name="department_id"
            label="科室"
            rules={[{ required: true, message: '请选择科室' }]}
          >
            <Select placeholder="请选择科室">
              {departments.map((dept) => (
                <Select.Option key={dept.department_id} value={dept.department_id}>
                  {dept.department_name}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>

          <Form.Item
            name="schedule_date"
            label="排班日期"
            rules={[{ required: true, message: '请选择排班日期' }]}
          >
            <DatePicker style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item
            name="start_time"
            label="开始时间"
            rules={[{ required: true, message: '请选择开始时间' }]}
          >
            <TimePicker style={{ width: '100%' }} format="HH:mm:ss" />
          </Form.Item>

          <Form.Item
            name="end_time"
            label="结束时间"
            rules={[{ required: true, message: '请选择结束时间' }]}
          >
            <TimePicker style={{ width: '100%' }} format="HH:mm:ss" />
          </Form.Item>

          <Form.Item
            name="quota"
            label="号源数量"
            rules={[{ required: true, message: '请输入号源数量' }]}
          >
            <InputNumber min={1} max={100} style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item name="registration_fee" label="挂号费" initialValue={0}>
            <InputNumber min={0} precision={2} style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item>
            <Button type="primary" htmlType="submit" loading={loading} style={{ marginRight: 8 }}>
              提交
            </Button>
            <Button onClick={() => navigate('/schedules')}>取消</Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  )
}

export default ScheduleForm

