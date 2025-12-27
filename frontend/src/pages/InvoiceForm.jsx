import React, { useState } from 'react'
import { Form, Select, InputNumber, Input, Button, Card, message } from 'antd'
import { useNavigate, useLocation } from 'react-router-dom'
import { invoiceAPI, patientAPI, encounterAPI } from '../utils/api'

function InvoiceForm() {
  const navigate = useNavigate()
  const location = useLocation()
  const encounter = location.state?.encounter
  const [form] = Form.useForm()
  const [loading, setLoading] = useState(false)
  const [patients, setPatients] = React.useState([])
  const [encounters, setEncounters] = React.useState([])

  React.useEffect(() => {
    fetchPatients()
    fetchEncounters()

    // 如果从就诊页面跳转过来，预填充信息
    if (encounter) {
      form.setFieldsValue({
        patient_id: encounter.patient_id,
        encounter_id: encounter.encounter_id,
      })
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

  const fetchEncounters = async () => {
    try {
      const result = await encounterAPI.getList({ per_page: 100, status: 'OPEN' })
      setEncounters(result.encounters)
    } catch (error) {
      console.error('Failed to fetch encounters:', error)
    }
  }

  const handleSubmit = async (values) => {
    try {
      setLoading(true)
      await invoiceAPI.create(values)
      message.success('开票成功')
      navigate('/invoices')
    } catch (error) {
      console.error('Failed to create invoice:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">开具账单</h1>
      </div>

      <Card>
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

          <Form.Item name="encounter_id" label="关联就诊">
            <Select
              placeholder="请选择就诊记录（可选）"
              allowClear
              showSearch
              optionFilterProp="children"
            >
              {encounters.map((enc) => (
                <Select.Option key={enc.encounter_id} value={enc.encounter_id}>
                  {enc.encounter_no} - {enc.patient_name} - {enc.department_name}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>

          <Form.Item
            name="total_amount"
            label="总金额"
            rules={[{ required: true, message: '请输入总金额' }]}
          >
            <InputNumber
              min={0}
              precision={2}
              style={{ width: '100%' }}
              placeholder="请输入总金额"
            />
          </Form.Item>

          <Form.Item name="note" label="备注">
            <Input.TextArea placeholder="请输入备注" rows={3} />
          </Form.Item>

          <Form.Item>
            <Button type="primary" htmlType="submit" loading={loading} style={{ marginRight: 8 }}>
              开具账单
            </Button>
            <Button onClick={() => navigate('/invoices')}>取消</Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  )
}

export default InvoiceForm

