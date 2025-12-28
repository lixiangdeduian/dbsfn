import React, { useState, useEffect } from 'react'
import { Table, Button, Card, message, Tag, Space, Modal, Form, Input, Select } from 'antd'
import { ExperimentOutlined, FileAddOutlined } from '@ant-design/icons'
import axios from 'axios'

const { TextArea } = Input
const { Option } = Select

function LabList() {
  const [labOrders, setLabOrders] = useState([])
  const [loading, setLoading] = useState(false)
  const [modalVisible, setModalVisible] = useState(false)
  const [currentItem, setCurrentItem] = useState(null)
  const [form] = Form.useForm()

  const fetchLabOrders = async () => {
    setLoading(true)
    try {
      const response = await axios.get('/api/lab/worklist')
      setLabOrders(response.data.data || [])
    } catch (error) {
      message.error('获取检验工作列表失败')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchLabOrders()
  }, [])

  const handleInputResult = (item) => {
    setCurrentItem(item)
    form.setFieldsValue({
      result_value: item.result_value || '',
      result_text: item.result_text || '',
      result_flag: item.result_flag || 'NORMAL'
    })
    setModalVisible(true)
  }

  const handleSubmitResult = async (values) => {
    try {
      await axios.post('/api/procedures/lab/result-upsert', {
        lab_order_item_id: currentItem.lab_order_item_id,
        result_value: values.result_value,
        result_text: values.result_text,
        result_flag: values.result_flag
      })
      message.success('检验结果录入成功')
      setModalVisible(false)
      fetchLabOrders()
    } catch (error) {
      message.error(error.response?.data?.error || '录入失败')
    }
  }

  const columns = [
    {
      title: '检验单号',
      dataIndex: 'lab_order_no',
      key: 'lab_order_no',
    },
    {
      title: '检验项目',
      dataIndex: 'test_name',
      key: 'test_name',
    },
    {
      title: '患者姓名',
      dataIndex: 'patient_name',
      key: 'patient_name',
    },
    {
      title: '开单医生',
      dataIndex: 'doctor_name',
      key: 'doctor_name',
    },
    {
      title: '开单时间',
      dataIndex: 'ordered_at',
      key: 'ordered_at',
      render: (text) => text ? new Date(text).toLocaleString() : '-'
    },
    {
      title: '状态',
      dataIndex: 'lab_order_status',
      key: 'lab_order_status',
      render: (status) => {
        const statusMap = {
          'ORDERED': { color: 'orange', text: '已开单' },
          'COLLECTED': { color: 'blue', text: '已采样' },
          'REPORTED': { color: 'green', text: '已出报告' },
          'CANCELLED': { color: 'red', text: '已取消' }
        }
        const s = statusMap[status] || { color: 'default', text: status }
        return <Tag color={s.color}>{s.text}</Tag>
      }
    },
    {
      title: '结果标志',
      dataIndex: 'result_flag',
      key: 'result_flag',
      render: (flag) => {
        if (!flag || flag === 'UNKNOWN') return '-'
        const flagMap = {
          'NORMAL': { color: 'green', text: '正常' },
          'HIGH': { color: 'red', text: '偏高' },
          'LOW': { color: 'blue', text: '偏低' },
          'POSITIVE': { color: 'red', text: '阳性' },
          'NEGATIVE': { color: 'green', text: '阴性' },
          'ABNORMAL': { color: 'orange', text: '异常' }
        }
        const f = flagMap[flag] || { color: 'default', text: flag }
        return <Tag color={f.color}>{f.text}</Tag>
      }
    },
    {
      title: '操作',
      key: 'action',
      render: (_, record) => (
        <Space>
          {(!record.result_at || record.lab_order_status !== 'REPORTED') && (
            <Button 
              type="primary"
              size="small"
              icon={<FileAddOutlined />}
              onClick={() => handleInputResult(record)}
            >
              录入结果
            </Button>
          )}
        </Space>
      )
    }
  ]

  return (
    <div style={{ padding: '24px' }}>
      <Card 
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <ExperimentOutlined style={{ fontSize: '20px', color: '#1890ff' }} />
            <span>检验管理 - 工作台</span>
          </div>
        }
        extra={
          <Button onClick={fetchLabOrders}>刷新</Button>
        }
      >
        <Table 
          columns={columns}
          dataSource={labOrders}
          rowKey="lab_order_item_id"
          loading={loading}
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            showTotal: (total) => `共 ${total} 条记录`
          }}
        />
      </Card>

      <Modal
        title="录入检验结果"
        open={modalVisible}
        onCancel={() => setModalVisible(false)}
        footer={null}
        width={600}
      >
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSubmitResult}
        >
          <Form.Item name="result_value" label="结果值">
            <Input placeholder="请输入检验结果数值" />
          </Form.Item>

          <Form.Item name="result_text" label="结果描述">
            <TextArea 
              rows={4}
              placeholder="请输入详细检验结果描述"
            />
          </Form.Item>

          <Form.Item name="result_flag" label="结果标志" rules={[{ required: true }]}>
            <Select>
              <Option value="NORMAL">正常</Option>
              <Option value="HIGH">偏高</Option>
              <Option value="LOW">偏低</Option>
              <Option value="POSITIVE">阳性</Option>
              <Option value="NEGATIVE">阴性</Option>
              <Option value="ABNORMAL">异常</Option>
            </Select>
          </Form.Item>

          <Form.Item>
            <Space style={{ width: '100%', justifyContent: 'flex-end' }}>
              <Button onClick={() => setModalVisible(false)}>取消</Button>
              <Button type="primary" htmlType="submit">提交</Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  )
}

export default LabList

