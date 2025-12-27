import React, { useEffect, useState } from 'react'
import { Form, Select, Input, Button, Card, message, DatePicker, Table } from 'antd'
import { useNavigate } from 'react-router-dom'
import { registrationAPI, patientAPI, scheduleAPI, departmentAPI } from '../utils/api'
import dayjs from 'dayjs'

function RegistrationForm() {
  const navigate = useNavigate()
  const [form] = Form.useForm()
  const [loading, setLoading] = useState(false)
  const [patients, setPatients] = useState([])
  const [departments, setDepartments] = useState([])
  const [schedules, setSchedules] = useState([])
  const [selectedDate, setSelectedDate] = useState(dayjs())
  const [selectedDepartment, setSelectedDepartment] = useState(null)

  useEffect(() => {
    fetchPatients()
    fetchDepartments()
  }, [])

  useEffect(() => {
    if (selectedDate && selectedDepartment) {
      fetchSchedules()
    }
  }, [selectedDate, selectedDepartment])

  const fetchPatients = async () => {
    try {
      const result = await patientAPI.getList({ per_page: 100 })
      setPatients(result.patients)
    } catch (error) {
      console.error('Failed to fetch patients:', error)
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

  const fetchSchedules = async () => {
    try {
      const result = await scheduleAPI.getList({
        start_date: selectedDate.format('YYYY-MM-DD'),
        end_date: selectedDate.format('YYYY-MM-DD'),
        department_id: selectedDepartment,
        per_page: 100,
      })
      setSchedules(result.schedules)
    } catch (error) {
      console.error('Failed to fetch schedules:', error)
    }
  }

  const handleSubmit = async (values) => {
    try {
      setLoading(true)
      await registrationAPI.create(values)
      message.success('预约成功')
      navigate('/registrations')
    } catch (error) {
      console.error('Failed to create registration:', error)
    } finally {
      setLoading(false)
    }
  }

  const scheduleColumns = [
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
      title: '时间',
      key: 'time',
      render: (_, record) => `${record.start_time} - ${record.end_time}`,
    },
    {
      title: '剩余号源',
      key: 'available',
      render: (_, record) => `${record.available_quota || 0} / ${record.quota}`,
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
        <Button
          type="primary"
          size="small"
          disabled={!record.available_quota || record.available_quota <= 0}
          onClick={() => form.setFieldsValue({ schedule_id: record.schedule_id })}
        >
          选择
        </Button>
      ),
    },
  ]

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">预约挂号</h1>
      </div>

      <Card style={{ marginBottom: 16 }}>
        <Form form={form} layout="vertical" onFinish={handleSubmit}>
          <Form.Item
            name="patient_id"
            label="患者"
            rules={[{ required: true, message: '请选择患者' }]}
          >
            <Select
              placeholder="请选择患者"
              showSearch
              optionFilterProp="children"
              filterOption={(input, option) =>
                option.children.toLowerCase().indexOf(input.toLowerCase()) >= 0
              }
            >
              {patients.map((patient) => (
                <Select.Option key={patient.patient_id} value={patient.patient_id}>
                  {patient.patient_name} - {patient.phone}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>

          <Form.Item label="就诊日期">
            <DatePicker
              value={selectedDate}
              onChange={setSelectedDate}
              style={{ width: '100%' }}
            />
          </Form.Item>

          <Form.Item label="科室">
            <Select
              placeholder="请选择科室"
              value={selectedDepartment}
              onChange={setSelectedDepartment}
            >
              {departments.map((dept) => (
                <Select.Option key={dept.department_id} value={dept.department_id}>
                  {dept.department_name}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>

          {selectedDate && selectedDepartment && (
            <Card title="可预约排班" style={{ marginBottom: 16 }}>
              <Table
                columns={scheduleColumns}
                dataSource={schedules}
                rowKey="schedule_id"
                pagination={false}
              />
            </Card>
          )}

          <Form.Item
            name="schedule_id"
            label="选中排班"
            rules={[{ required: true, message: '请选择排班' }]}
          >
            <Input placeholder="点击上方排班表格的选择按钮" disabled />
          </Form.Item>

          <Form.Item name="chief_complaint" label="主诉">
            <Input.TextArea placeholder="请输入主诉" rows={3} />
          </Form.Item>

          <Form.Item>
            <Button type="primary" htmlType="submit" loading={loading} style={{ marginRight: 8 }}>
              提交预约
            </Button>
            <Button onClick={() => navigate('/registrations')}>取消</Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  )
}

export default RegistrationForm

