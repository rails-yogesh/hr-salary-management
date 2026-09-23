import { useQuery } from '@tanstack/react-query'
import {
  fetchDashboardByCountry,
  fetchDashboardByDepartment,
  fetchDashboardSummary,
  fetchSalaryDistribution,
} from '../api/endpoints'

// Dashboard figures change whenever anyone records a hire/raise/termination
// elsewhere in the app; a short staleTime keeps it reasonably fresh without
// refetching on every render.
const DASHBOARD_STALE_TIME_MS = 30_000

export function useDashboardSummary() {
  return useQuery({
    queryKey: ['dashboard', 'summary'],
    queryFn: fetchDashboardSummary,
    staleTime: DASHBOARD_STALE_TIME_MS,
  })
}

export function useDashboardByCountry() {
  return useQuery({
    queryKey: ['dashboard', 'by_country'],
    queryFn: fetchDashboardByCountry,
    staleTime: DASHBOARD_STALE_TIME_MS,
  })
}

export function useDashboardByDepartment() {
  return useQuery({
    queryKey: ['dashboard', 'by_department'],
    queryFn: fetchDashboardByDepartment,
    staleTime: DASHBOARD_STALE_TIME_MS,
  })
}

export function useSalaryDistribution() {
  return useQuery({
    queryKey: ['dashboard', 'salary_distribution'],
    queryFn: fetchSalaryDistribution,
    staleTime: DASHBOARD_STALE_TIME_MS,
  })
}
