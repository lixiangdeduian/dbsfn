import React, { useEffect, useState } from 'react'
import { Form, Input, Select, DatePicker, Button, Card, message, Row, Col, Space } from 'antd'
import { useNavigate, useParams } from 'react-router-dom'
import { patientAPI } from '../utils/api'
import dayjs from 'dayjs'

const { Option } = Select

function PatientForm() {
  const navigate = useNavigate()
  const { id } = useParams()
  const [form] = Form.useForm()
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (id) {
      fetchPatient()
    }
  }, [id])

  const fetchPatient = async () => {
    try {
      const data = await patientAPI.getDetail(id)
      form.setFieldsValue({
        ...data,
        birth_date: data.birth_date ? dayjs(data.birth_date) : null,
      })
    } catch (error) {
      console.error('Failed to fetch patient:', error)
    }
  }

  const handleSubmit = async (values) => {
    try {
      setLoading(true)
      const formData = {
        ...values,
        birth_date: values.birth_date ? values.birth_date.format('YYYY-MM-DD') : null,
      }

      if (id) {
        await patientAPI.update(id, formData)
        message.success('更新成功')
      } else {
        await patientAPI.create(formData)
        message.success('创建成功')
      }
      navigate('/patients')
    } catch (error) {
      console.error('Failed to save patient:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">{id ? '编辑患者信息' : '新建患者档案'}</h1>
      </div>

      <Card 
        title={
          <span style={{ fontSize: '16px', fontWeight: 600, color: '#1e3a8a' }}>
            {id ? '📝 编辑患者基本信息' : '➕ 填写患者基本信息'}
          </span>
        }
        style={{ maxWidth: 900, margin: '0 auto' }}
      >
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSubmit}
          initialValues={{
            gender: 'U',
            blood_type: 'U',
          }}
          size="large"
        >
          <div style={{
            background: '#f8fafb',
            padding: '20px',
            borderRadius: '8px',
            marginBottom: '24px',
            border: '1px solid #e0e7ff'
          }}>
            <h3 style={{ 
              marginBottom: '16px', 
              color: '#1e3a8a',
              fontSize: '15px',
              fontWeight: 600
            }}>
              👤 基本信息
            </h3>
            <Row gutter={16}>
              <Col span={12}>
                <Form.Item
                  name="patient_name"
                  label="姓名"
                  rules={[{ required: true, message: '请输入患者姓名' }]}
                >
                  <Input placeholder="请输入患者姓名" />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item name="gender" label="性别" rules={[{ required: true }]}>
                  <Select>
                    <Option value="M">男</Option>
                    <Option value="F">女</Option>
                    <Option value="U">未知</Option>
                  </Select>
                </Form.Item>
              </Col>
            </Row>

            <Row gutter={16}>
              <Col span={12}>
                <Form.Item name="birth_date" label="出生日期">
                  <DatePicker style={{ width: '100%' }} placeholder="选择出生日期" />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item name="blood_type" label="血型">
                  <Select>
                    <Option value="A">A型</Option>
                    <Option value="B">B型</Option>
                    <Option value="AB">AB型</Option>
                    <Option value="O">O型</Option>
                    <Option value="U">未知</Option>
                  </Select>
                </Form.Item>
              </Col>
            </Row>
          </div>

          <div style={{
            background: '#f0f9ff',
            padding: '20px',
            borderRadius: '8px',
            marginBottom: '24px',
            border: '1px solid #bae6fd'
          }}>
            <h3 style={{ 
              marginBottom: '16px', 
              color: '#1e3a8a',
              fontSize: '15px',
              fontWeight: 600
            }}>
              📞 联系方式
            </h3>
            <Row gutter={16}>
              <Col span={12}>
                <Form.Item name="id_card_no" label="身份证号">
                  <Input placeholder="请输入身份证号" />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item name="phone" label="联系电话">
                  <Input placeholder="请输入联系电话" />
                </Form.Item>
              </Col>
            </Row>

            <Form.Item name="address" label="联系地址">
              <Input.TextArea placeholder="请输入联系地址" rows={2} />
            </Form.Item>
          </div>

          <div style={{
            background: '#fef3c7',
            padding: '20px',
            borderRadius: '8px',
            marginBottom: '24px',
            border: '1px solid #fcd34d'
          }}>
            <h3 style={{ 
              marginBottom: '16px', 
              color: '#92400e',
              fontSize: '15px',
              fontWeight: 600
            }}>
              🚨 紧急联系人
            </h3>
            <Row gutter={16}>
              <Col span={12}>
                <Form.Item name="emergency_contact_name" label="紧急联系人姓名">
                  <Input placeholder="请输入紧急联系人姓名" />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item name="emergency_contact_phone" label="紧急联系人电话">
                  <Input placeholder="请输入紧急联系人电话" />
                </Form.Item>
              </Col>
            </Row>
          </div>

          <div style={{
            background: '#fee2e2',
            padding: '20px',
            borderRadius: '8px',
            marginBottom: '24px',
            border: '1px solid #fca5a5'
          }}>
            <h3 style={{ 
              marginBottom: '16px', 
              color: '#991b1b',
              fontSize: '15px',
              fontWeight: 600
            }}>
              ⚕️ 医疗信息
            </h3>
            <Form.Item name="allergy_history" label="过敏史">
              <Input.TextArea 
                placeholder="请输入过敏史，如：青霉素过敏、海鲜过敏等" 
                rows={3} 
              />
            </Form.Item>
          </div>

          <Form.Item style={{ marginTop: '32px', textAlign: 'center' }}>
            <Space size="middle">
              <Button 
                type="primary" 
                htmlType="submit" 
                loading={loading}
                size="large"
                style={{
                  minWidth: '120px',
                  height: '44px',
                  fontSize: '16px'
                }}
              >
                {id ? '💾 保存修改' : '✅ 创建患者'}
              </Button>
              <Button 
                onClick={() => navigate('/patients')}
                size="large"
                style={{
                  minWidth: '120px',
                  height: '44px',
                  fontSize: '16px'
                }}
              >
                取消
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Card>
    </div>
  )
}

export default PatientForm

