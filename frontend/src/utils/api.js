import axios from 'axios'
import { message } from 'antd'

// 创建axios实例
const api = axios.create({
  baseURL: '/api',
  timeout: 10000,
})

// 请求拦截器
api.interceptors.request.use(
  (config) => {
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// 响应拦截器
api.interceptors.response.use(
  (response) => {
    return response.data
  },
  (error) => {
    const errorMessage = error.response?.data?.error || error.message || '请求失败'
    message.error(errorMessage)
    return Promise.reject(error)
  }
)

// API方法
export const patientAPI = {
  getList: (params) => api.get('/patients/', { params }),
  getDetail: (id) => api.get(`/patients/${id}`),
  create: (data) => api.post('/patients/', data),
  update: (id, data) => api.put(`/patients/${id}`, data),
  delete: (id) => api.delete(`/patients/${id}`),
}

export const scheduleAPI = {
  getList: (params) => api.get('/schedules/', { params }),
  getDetail: (id) => api.get(`/schedules/${id}`),
  create: (data) => api.post('/schedules/', data),
  update: (id, data) => api.put(`/schedules/${id}`, data),
  delete: (id) => api.delete(`/schedules/${id}`),
}

export const registrationAPI = {
  getList: (params) => api.get('/registrations/', { params }),
  getDetail: (id) => api.get(`/registrations/${id}`),
  create: (data) => api.post('/registrations/', data),
  cancel: (id) => api.post(`/registrations/${id}/cancel`),
  complete: (id) => api.post(`/registrations/${id}/complete`),
}

export const encounterAPI = {
  getList: (params) => api.get('/encounters/', { params }),
  getDetail: (id) => api.get(`/encounters/${id}`),
  create: (data) => api.post('/encounters/', data),
  update: (id, data) => api.put(`/encounters/${id}`, data),
  close: (id) => api.post(`/encounters/${id}/close`),
}

export const invoiceAPI = {
  getList: (params) => api.get('/invoices/', { params }),
  getDetail: (id) => api.get(`/invoices/${id}`),
  create: (data) => api.post('/invoices/', data),
  void: (id) => api.post(`/invoices/${id}/void`),
  getUnbilledCharges: (encounterId) => api.get(`/invoices/encounter/${encounterId}/unbilled-charges`),
}

export const paymentAPI = {
  getList: (params) => api.get('/payments/', { params }),
  getDetail: (id) => api.get(`/payments/${id}`),
  create: (data) => api.post('/payments/', data),
  cancel: (id) => api.post(`/payments/${id}/cancel`),
}

export const staffAPI = {
  getList: (params) => api.get('/staff/', { params }),
  getDetail: (id) => api.get(`/staff/${id}`),
  create: (data) => api.post('/staff/', data),
  update: (id, data) => api.put(`/staff/${id}`, data),
  delete: (id) => api.delete(`/staff/${id}`),
}

export const departmentAPI = {
  getList: (params) => api.get('/departments/', { params }),
  getDetail: (id) => api.get(`/departments/${id}`),
  create: (data) => api.post('/departments/', data),
  update: (id, data) => api.put(`/departments/${id}`, data),
  delete: (id) => api.delete(`/departments/${id}`),
}

export const statisticsAPI = {
  getRevenue: (params) => api.get('/statistics/revenue', { params }),
  getEncounters: (params) => api.get('/statistics/encounters', { params }),
  getDepartmentRevenue: (params) => api.get('/statistics/department-revenue', { params }),
  getDoctorWorkload: (params) => api.get('/statistics/doctor-workload', { params }),
  getDashboard: () => api.get('/statistics/dashboard'),
}

export default api

