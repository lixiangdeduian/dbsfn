import React, { useState, useEffect } from 'react'
import { Card, Descriptions, Table, Tabs, Tag, message } from 'antd'
import { UserOutlined, FileTextOutlined, ExperimentOutlined, DollarOutlined } from '@ant-design/icons'
import axios from 'axios'

const { TabPane } = Tabs

function PatientPortal() {
  const [myInfo, setMyInfo] = useState(null)
  const [encounters, setEncounters] = useState([])
  const [prescriptions, setPrescriptions] = useState([])
  const [labResults, setLabResults] = useState([])
  const [invoices, setInvoices] = useState([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    fetchMyInfo()
    fetchMyEncounters()
    fetchMyPrescriptions()
    fetchMyLabResults()
    fetchMyInvoices()
  }, [])

  const fetchMyInfo = async () => {
    try {
      const response = await axios.get('/api/patient-portal/my-info')
      setMyInfo(response.data.data)
    } catch (error) {
      message.error('获取个人信息失败')
    }
  }

  const fetchMyEncounters = async () => {
    try {
      const response = await axios.get('/api/patient-portal/my-encounters')
      setEncounters(response.data.data || [])
    } catch (error) {
      message.error('获取就诊记录失败')
    }
  }

  const fetchMyPrescriptions = async () => {
    try {
      const response = await axios.get('/api/patient-portal/my-prescriptions')
      setPrescriptions(response.data.data || [])
    } catch (error) {
      message.error('获取处方记录失败')
    }
  }

  const fetchMyLabResults = async () => {
    try {
      const response = await axios.get('/api/patient-portal/my-lab-results')
      setLabResults(response.data.data || [])
    } catch (error) {
      message.error('获取检验结果失败')
    }
  }

  const fetchMyInvoices = async () => {
    try {
      const response = await axios.get('/api/patient-portal/my-invoices')
      setInvoices(response.data.data || [])
    } catch (error) {
      message.error('获取账单失败')
    }
  }

  const encounterColumns = [
    {
      title: '就诊号',
      dataIndex: 'encounter_no',
      key: 'encounter_no',
    },
    {
      title: '就诊类型',
      dataIndex: 'encounter_type',
      key: 'encounter_type',
      render: (type) => {
        const typeMap = {
          'OUTPATIENT': '门诊',
          'EMERGENCY': '急诊',
          'INPATIENT': '住院'
        }
        return typeMap[type] || type
      }
    },
    {
      title: '科室',
      dataIndex: 'department_name',
      key: 'department_name',
    },
    {
      title: '医生',
      dataIndex: 'doctor_name',
      key: 'doctor_name',
    },
    {
      title: '就诊时间',
      dataIndex: 'started_at',
      key: 'started_at',
      render: (text) => text ? new Date(text).toLocaleString() : '-'
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      render: (status) => {
        const statusMap = {
          'OPEN': { color: 'blue', text: '进行中' },
          'CLOSED': { color: 'green', text: '已完成' },
          'CANCELLED': { color: 'red', text: '已取消' }
        }
        const s = statusMap[status] || { color: 'default', text: status }
        return <Tag color={s.color}>{s.text}</Tag>
      }
    }
  ]

  const prescriptionColumns = [
    {
      title: '处方号',
      dataIndex: 'prescription_no',
      key: 'prescription_no',
    },
    {
      title: '药品名称',
      dataIndex: 'drug_name',
      key: 'drug_name',
    },
    {
      title: '规格',
      dataIndex: 'specification',
      key: 'specification',
    },
    {
      title: '数量',
      dataIndex: 'quantity',
      key: 'quantity',
      render: (qty, record) => `${qty} ${record.unit}`
    },
    {
      title: '用法',
      dataIndex: 'usage_instructions',
      key: 'usage_instructions',
    },
    {
      title: '频次',
      dataIndex: 'frequency',
      key: 'frequency',
    },
    {
      title: '天数',
      dataIndex: 'days',
      key: 'days',
      render: (days) => days ? `${days}天` : '-'
    },
    {
      title: '开方时间',
      dataIndex: 'issued_at',
      key: 'issued_at',
      render: (text) => text ? new Date(text).toLocaleString() : '-'
    }
  ]

  const labColumns = [
    {
      title: '检验项目',
      dataIndex: 'test_name',
      key: 'test_name',
    },
    {
      title: '检验结果',
      dataIndex: 'result_value',
      key: 'result_value',
    },
    {
      title: '参考范围',
      dataIndex: 'reference_range',
      key: 'reference_range',
    },
    {
      title: '结果标志',
      dataIndex: 'result_flag',
      key: 'result_flag',
      render: (flag) => {
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
      title: '检验时间',
      dataIndex: 'result_at',
      key: 'result_at',
      render: (text) => text ? new Date(text).toLocaleString() : '-'
    }
  ]

  const invoiceColumns = [
    {
      title: '账单号',
      dataIndex: 'invoice_no',
      key: 'invoice_no',
    },
    {
      title: '账单日期',
      dataIndex: 'issued_at',
      key: 'issued_at',
      render: (text) => text ? new Date(text).toLocaleDateString() : '-'
    },
    {
      title: '总金额',
      dataIndex: 'total_amount',
      key: 'total_amount',
      render: (amount) => `¥${(amount || 0).toFixed(2)}`
    },
    {
      title: '已付金额',
      dataIndex: 'paid_amount',
      key: 'paid_amount',
      render: (amount) => `¥${(amount || 0).toFixed(2)}`
    },
    {
      title: '待付金额',
      dataIndex: 'outstanding_amount',
      key: 'outstanding_amount',
      render: (amount) => `¥${(amount || 0).toFixed(2)}`
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      render: (status) => {
        const statusMap = {
          'OPEN': { color: 'orange', text: '未结清' },
          'PARTIALLY_PAID': { color: 'blue', text: '部分已付' },
          'PAID': { color: 'green', text: '已付清' },
          'VOID': { color: 'red', text: '已作废' }
        }
        const s = statusMap[status] || { color: 'default', text: status }
        return <Tag color={s.color}>{s.text}</Tag>
      }
    }
  ]

  return (
    <div style={{ padding: '24px' }}>
      <Card 
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <UserOutlined style={{ fontSize: '20px', color: '#52c41a' }} />
            <span>患者自助门户</span>
          </div>
        }
        style={{ marginBottom: '24px' }}
      >
        {myInfo && (
          <Descriptions bordered column={2}>
            <Descriptions.Item label="患者编号">{myInfo.patient_no}</Descriptions.Item>
            <Descriptions.Item label="姓名">{myInfo.patient_name}</Descriptions.Item>
            <Descriptions.Item label="性别">
              {myInfo.gender === 'M' ? '男' : myInfo.gender === 'F' ? '女' : '未知'}
            </Descriptions.Item>
            <Descriptions.Item label="出生日期">{myInfo.birth_date}</Descriptions.Item>
            <Descriptions.Item label="血型">{myInfo.blood_type}</Descriptions.Item>
            <Descriptions.Item label="联系电话">{myInfo.phone}</Descriptions.Item>
            <Descriptions.Item label="地址" span={2}>{myInfo.address}</Descriptions.Item>
            <Descriptions.Item label="过敏史" span={2}>
              {myInfo.allergy_history || '无'}
            </Descriptions.Item>
          </Descriptions>
        )}
      </Card>

      <Tabs defaultActiveKey="encounters" size="large">
        <TabPane 
          tab={
            <span>
              <FileTextOutlined />
              就诊记录
            </span>
          } 
          key="encounters"
        >
          <Table 
            columns={encounterColumns}
            dataSource={encounters}
            rowKey="encounter_id"
            loading={loading}
            pagination={{ pageSize: 10 }}
          />
        </TabPane>

        <TabPane 
          tab={
            <span>
              <FileTextOutlined />
              处方记录
            </span>
          } 
          key="prescriptions"
        >
          <Table 
            columns={prescriptionColumns}
            dataSource={prescriptions}
            rowKey={(record) => `${record.prescription_id}_${record.prescription_item_id}`}
            loading={loading}
            pagination={{ pageSize: 10 }}
          />
        </TabPane>

        <TabPane 
          tab={
            <span>
              <ExperimentOutlined />
              检验结果
            </span>
          } 
          key="lab-results"
        >
          <Table 
            columns={labColumns}
            dataSource={labResults}
            rowKey="lab_result_id"
            loading={loading}
            pagination={{ pageSize: 10 }}
          />
        </TabPane>

        <TabPane 
          tab={
            <span>
              <DollarOutlined />
              费用账单
            </span>
          } 
          key="invoices"
        >
          <Table 
            columns={invoiceColumns}
            dataSource={invoices}
            rowKey="invoice_id"
            loading={loading}
            pagination={{ pageSize: 10 }}
          />
        </TabPane>
      </Tabs>
    </div>
  )
}

export default PatientPortal


