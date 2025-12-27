import React, { useEffect, useState } from 'react'
import { Card, Row, Col, Table, DatePicker, Space, Button } from 'antd'
import { statisticsAPI } from '../utils/api'
import dayjs from 'dayjs'

const { RangePicker } = DatePicker

function Statistics() {
  const [loading, setLoading] = useState(false)
  const [dateRange, setDateRange] = useState([dayjs().subtract(7, 'day'), dayjs()])
  const [departmentRevenue, setDepartmentRevenue] = useState([])
  const [doctorWorkload, setDoctorWorkload] = useState([])
  const [revenueData, setRevenueData] = useState([])

  useEffect(() => {
    fetchStatistics()
  }, [dateRange])

  const fetchStatistics = async () => {
    try {
      setLoading(true)
      const params = {
        start_date: dateRange[0].format('YYYY-MM-DD'),
        end_date: dateRange[1].format('YYYY-MM-DD'),
      }

      const [deptRevenue, doctorWork, revenue] = await Promise.all([
        statisticsAPI.getDepartmentRevenue(params),
        statisticsAPI.getDoctorWorkload(params),
        statisticsAPI.getRevenue(params),
      ])

      setDepartmentRevenue(deptRevenue.statistics || [])
      setDoctorWorkload(doctorWork.statistics || [])
      setRevenueData(revenue.statistics || [])
    } catch (error) {
      console.error('Failed to fetch statistics:', error)
    } finally {
      setLoading(false)
    }
  }

  const departmentColumns = [
    {
      title: '科室',
      dataIndex: 'department_name',
      key: 'department_name',
    },
    {
      title: '就诊人次',
      dataIndex: 'encounter_count',
      key: 'encounter_count',
    },
    {
      title: '总收入',
      dataIndex: 'total_revenue',
      key: 'total_revenue',
      render: (revenue) => `¥${revenue.toFixed(2)}`,
    },
  ]

  const doctorColumns = [
    {
      title: '医生',
      dataIndex: 'doctor_name',
      key: 'doctor_name',
    },
    {
      title: '职称',
      dataIndex: 'title',
      key: 'title',
    },
    {
      title: '科室',
      dataIndex: 'department_name',
      key: 'department_name',
    },
    {
      title: '就诊人次',
      dataIndex: 'encounter_count',
      key: 'encounter_count',
    },
  ]

  const revenueColumns = [
    {
      title: '日期',
      dataIndex: 'date',
      key: 'date',
    },
    {
      title: '收款笔数',
      dataIndex: 'payment_count',
      key: 'payment_count',
    },
    {
      title: '收入金额',
      dataIndex: 'total_revenue',
      key: 'total_revenue',
      render: (revenue) => `¥${revenue.toFixed(2)}`,
    },
  ]

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">统计报表</h1>
      </div>

      <div style={{ marginBottom: 16 }}>
        <Space>
          <RangePicker value={dateRange} onChange={setDateRange} />
          <Button type="primary" onClick={fetchStatistics} loading={loading}>
            查询
          </Button>
        </Space>
      </div>

      <Row gutter={16}>
        <Col span={24} style={{ marginBottom: 16 }}>
          <Card title="科室收入统计" loading={loading}>
            <Table
              columns={departmentColumns}
              dataSource={departmentRevenue}
              rowKey="department_name"
              pagination={false}
            />
          </Card>
        </Col>

        <Col span={24} style={{ marginBottom: 16 }}>
          <Card title="医生工作量统计" loading={loading}>
            <Table
              columns={doctorColumns}
              dataSource={doctorWorkload}
              rowKey="doctor_name"
              pagination={{ pageSize: 10 }}
            />
          </Card>
        </Col>

        <Col span={24}>
          <Card title="每日收入统计" loading={loading}>
            <Table
              columns={revenueColumns}
              dataSource={revenueData}
              rowKey="date"
              pagination={false}
            />
          </Card>
        </Col>
      </Row>
    </div>
  )
}

export default Statistics

