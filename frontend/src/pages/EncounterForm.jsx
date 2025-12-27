import React, { useEffect, useState } from 'react'
import { Form, Select, Input, Button, Card, message } from 'antd'
import { useNavigate, useLocation } from 'react-router-dom'
import { encounterAPI, patientAPI, departmentAPI, staffAPI } from '../utils/api'

function EncounterForm() {
  const navigate = useNavigate()
  const location = useLocation()
  const registration = location.state?.registration
  const [form] = Form.useForm()
  const [loading, setLoading] = useState(false)
  const [patients, setPatients] = useState([])
  const [departments, setDepartments] = useState([])
  const [doctors, setDoctors] = useState([])

  useEffect(() => {
    fetchPatients()
    fetchDepartments()
    fetchDoctors()

    // 如果是从挂号页面跳转过来的，预填充信息
    if (registration) {
      form.setFieldsValue({
        patient_id: registration.patient_id,
        registration_id: registration.registration_id,
      })
      // 根据挂号信息获取科室和医生
      if (registration.schedule_id) {
        // 这里可以从schedule获取department_id和doctor_id
      }
    }
  }, [])

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

  const fetchDoctors = async () => {
    try {
      const result = await staffAPI.getList({ per_page: 100 })
      setDoctors(result.staff)
    } catch (error) {
      console.error('Failed to fetch doctors:', error)
    }
  }

  const handleSubmit = async (values) => {
    try {
      setLoading(true)
      await encounterAPI.create(values)
      message.success('登记成功')
      navigate('/encounters')
    } catch (error) {
      console.error('Failed to create encounter:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">到院登记</h1>
      </div>

      <Card>
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSubmit}
          initialValues={{
            encounter_type: 'OUTPATIENT',
          }}
        >
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

          <Form.Item
            name="department_id"
            label="就诊科室"
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
            name="doctor_id"
            label="接诊医生"
            rules={[{ required: true, message: '请选择医生' }]}
          >
            <Select
              placeholder="请选择医生"
              showSearch
              optionFilterProp="children"
              filterOption={(input, option) =>
                option.children.toLowerCase().indexOf(input.toLowerCase()) >= 0
              }
            >
              {doctors.map((doctor) => (
                <Select.Option key={doctor.staff_id} value={doctor.staff_id}>
                  {doctor.staff_name} - {doctor.title}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>

          <Form.Item name="registration_id" label="关联挂号ID" hidden>
            <Input />
          </Form.Item>

          <Form.Item name="encounter_type" label="就诊类型">
            <Select>
              <Select.Option value="OUTPATIENT">门诊</Select.Option>
              <Select.Option value="INPATIENT">住院</Select.Option>
            </Select>
          </Form.Item>

          <Form.Item name="note" label="备注">
            <Input.TextArea placeholder="请输入备注" rows={3} />
          </Form.Item>

          <Form.Item>
            <Button type="primary" htmlType="submit" loading={loading} style={{ marginRight: 8 }}>
              提交登记
            </Button>
            <Button onClick={() => navigate('/encounters')}>取消</Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  )
}

export default EncounterForm

