import { apiRequest } from './client'
import type {
  ChangeReason,
  DashboardBreakdown,
  DashboardSummary,
  EmployeeDetail,
  EmployeeListResponse,
  Lookups,
  PayFrequency,
  SalaryDistributionRow,
} from './types'

export function login(email: string, password: string) {
  return apiRequest<{ token: string; email: string }>('/login', {
    method: 'POST',
    body: { email, password },
  })
}

export function fetchLookups() {
  return apiRequest<Lookups>('/lookups')
}

export interface EmployeeListParams {
  q?: string
  country_id?: number
  department_id?: number
  employment_status?: string
  page?: number
  per_page?: number
  [key: string]: unknown
}

export function fetchEmployees(params: EmployeeListParams) {
  return apiRequest<EmployeeListResponse>('/employees', { params })
}

export function fetchEmployee(id: number | string) {
  return apiRequest<EmployeeDetail>(`/employees/${id}`)
}

export interface CreateEmployeePayload {
  employee: {
    first_name: string
    last_name: string
    work_email: string
    job_title: string
    country_id: number
    department_id: number
    job_level_id: number
    hire_date: string
  }
  compensation: {
    amount_cents: number
    currency_code: string
    pay_frequency: PayFrequency
    effective_date: string
  }
}

export function createEmployee(payload: CreateEmployeePayload) {
  return apiRequest<EmployeeDetail>('/employees', { method: 'POST', body: payload })
}

export interface UpdateEmployeePayload {
  first_name?: string
  last_name?: string
  work_email?: string
  job_title?: string
  country_id?: number
  department_id?: number
  job_level_id?: number
}

export function updateEmployee(id: number, payload: UpdateEmployeePayload) {
  return apiRequest<EmployeeDetail>(`/employees/${id}`, { method: 'PATCH', body: { employee: payload } })
}

export function terminateEmployee(id: number, terminationDate: string) {
  return apiRequest<EmployeeDetail>(`/employees/${id}/terminate`, {
    method: 'PATCH',
    body: { termination_date: terminationDate },
  })
}

export interface RecordRaisePayload {
  amount_cents: number
  currency_code: string
  pay_frequency: PayFrequency
  effective_date: string
  change_reason: ChangeReason
  note?: string
}

export function recordCompensationChange(employeeId: number, payload: RecordRaisePayload) {
  return apiRequest<EmployeeDetail>(`/employees/${employeeId}/compensation_records`, {
    method: 'POST',
    body: { compensation_record: payload },
  })
}

export function fetchDashboardSummary() {
  return apiRequest<DashboardSummary>('/dashboard/summary')
}

export function fetchDashboardByCountry() {
  return apiRequest<DashboardBreakdown[]>('/dashboard/by_country')
}

export function fetchDashboardByDepartment() {
  return apiRequest<DashboardBreakdown[]>('/dashboard/by_department')
}

export function fetchSalaryDistribution() {
  return apiRequest<SalaryDistributionRow[]>('/dashboard/salary_distribution')
}
