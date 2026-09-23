export interface Country {
  id: number
  code: string
  name: string
  currency_code: string
}

export interface Department {
  id: number
  name: string
}

export interface JobLevel {
  id: number
  name: string
  rank: number
}

export type PayFrequency = 'monthly' | 'annual'
export type EmploymentStatus = 'active' | 'terminated' | 'on_leave'
export type ChangeReason = 'hire' | 'promotion' | 'annual_review' | 'market_adjustment' | 'correction'

export interface CompensationRecord {
  id: number
  amount_cents: number
  currency_code: string
  pay_frequency: PayFrequency
  annual_amount_cents: number
  annual_usd_cents: number
  effective_date: string
  end_date: string | null
  current: boolean
  change_reason: ChangeReason
  note: string | null
}

export interface EmployeeSummary {
  id: number
  employee_number: string
  full_name: string
  work_email: string
  job_title: string
  employment_status: EmploymentStatus
  hire_date: string
  country: { id: number; code: string; name: string }
  department: { id: number; name: string }
  job_level: { id: number; name: string; rank: number }
  current_compensation: CompensationRecord | null
}

export interface EmployeeDetail extends EmployeeSummary {
  termination_date: string | null
  compensation_history: CompensationRecord[]
}

export interface PaginationMeta {
  current_page: number
  total_pages: number
  total_count: number
  per_page: number
}

export interface EmployeeListResponse {
  employees: EmployeeSummary[]
  meta: PaginationMeta
}

export interface Lookups {
  countries: Country[]
  departments: Department[]
  job_levels: JobLevel[]
}

export interface DashboardSummary {
  headcount: number
  total_annual_cost_usd_cents: number
  average_annual_cost_usd_cents: number
}

export interface DashboardBreakdown {
  label: string
  headcount: number
  total_annual_cost_usd_cents: number
}

export interface SalaryDistributionRow {
  label: string
  headcount: number
  average_annual_cost_usd_cents: number
  min_annual_cost_usd_cents: number
  max_annual_cost_usd_cents: number
}
