import React, { useState } from 'react'
import { Form, Select, InputNumber, Input, Button, Card, message, Alert } from 'antd'
import { useNavigate, useLocation } from 'react-router-dom'
import { paymentAPI, invoiceAPI } from '../utils/api'

function PaymentForm() {
  const navigate = useNavigate()
  const location = useLocation()
  const invoice = location.state?.invoice
  const [form] = Form.useForm()
  const [loading, setLoading] = useState(false)
  const [invoices, setInvoices] = React.useState([])
  const [selectedInvoice, setSelectedInvoice] = React.useState(invoice || null)

  React.useEffect(() => {
    fetchInvoices()

    // 如果从发票页面跳转过来，预填充信息
    if (invoice) {
      form.setFieldsValue({
        invoice_id: invoice.invoice_id,
        amount: invoice.remaining_amount,
      })
      setSelectedInvoice(invoice)
    }
  }, [])

  const fetchInvoices = async () => {
    try {
      const result = await invoiceAPI.getList({ per_page: 100 })
      setInvoices(result.invoices.filter((inv) => inv.status !== 'PAID' && inv.status !== 'VOID'))
    } catch (error) {
      console.error('Failed to fetch invoices:', error)
    }
  }

  const handleInvoiceChange = async (invoiceId) => {
    try {
      const invoice = await invoiceAPI.getDetail(invoiceId)
      setSelectedInvoice(invoice)
      form.setFieldsValue({
        amount: invoice.remaining_amount,
      })
    } catch (error) {
      console.error('Failed to fetch invoice:', error)
    }
  }

  const handleSubmit = async (values) => {
    try {
      setLoading(true)
      await paymentAPI.create(values)
      message.success('收款成功')
      navigate('/invoices')
    } catch (error) {
      console.error('Failed to create payment:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">收款</h1>
      </div>

      <Card>
        {selectedInvoice && (
          <Alert
            message="账单信息"
            description={
              <div>
                <p>发票号: {selectedInvoice.invoice_no}</p>
                <p>患者: {selectedInvoice.patient_name}</p>
                <p>总金额: ¥{selectedInvoice.total_amount.toFixed(2)}</p>
                <p>已付金额: ¥{selectedInvoice.paid_amount.toFixed(2)}</p>
                <p>剩余金额: ¥{selectedInvoice.remaining_amount.toFixed(2)}</p>
              </div>
            }
            type="info"
            style={{ marginBottom: 16 }}
          />
        )}

        <Form
          form={form}
          layout="vertical"
          onFinish={handleSubmit}
          initialValues={{
            method: 'CASH',
          }}
        >
          <Form.Item
            name="invoice_id"
            label="发票"
            rules={[{ required: true, message: '请选择发票' }]}
          >
            <Select placeholder="请选择发票" onChange={handleInvoiceChange}>
              {invoices.map((inv) => (
                <Select.Option key={inv.invoice_id} value={inv.invoice_id}>
                  {inv.invoice_no} - {inv.patient_name} - 剩余¥{inv.remaining_amount.toFixed(2)}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>

          <Form.Item
            name="method"
            label="支付方式"
            rules={[{ required: true, message: '请选择支付方式' }]}
          >
            <Select>
              <Select.Option value="CASH">现金</Select.Option>
              <Select.Option value="CARD">银行卡</Select.Option>
              <Select.Option value="WECHAT">微信</Select.Option>
              <Select.Option value="ALIPAY">支付宝</Select.Option>
              <Select.Option value="TRANSFER">转账</Select.Option>
              <Select.Option value="OTHER">其他</Select.Option>
            </Select>
          </Form.Item>

          <Form.Item
            name="amount"
            label="支付金额"
            rules={[{ required: true, message: '请输入支付金额' }]}
          >
            <InputNumber
              min={0}
              max={selectedInvoice?.remaining_amount}
              precision={2}
              style={{ width: '100%' }}
              placeholder="请输入支付金额"
            />
          </Form.Item>

          <Form.Item name="transaction_ref" label="交易流水号">
            <Input placeholder="第三方支付流水号（可选）" />
          </Form.Item>

          <Form.Item>
            <Button type="primary" htmlType="submit" loading={loading} style={{ marginRight: 8 }}>
              确认收款
            </Button>
            <Button onClick={() => navigate('/invoices')}>取消</Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  )
}

export default PaymentForm

