import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { fetchEmployees, type EmployeeListParams } from '../api/endpoints'

export function useEmployees(params: EmployeeListParams) {
  return useQuery({
    queryKey: ['employees', params],
    queryFn: () => fetchEmployees(params),
    placeholderData: keepPreviousData,
  })
}
