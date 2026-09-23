import { useQuery } from '@tanstack/react-query'
import { fetchEmployee } from '../api/endpoints'

export function useEmployee(id: string | undefined) {
  return useQuery({
    queryKey: ['employee', id],
    queryFn: () => fetchEmployee(id as string),
    enabled: Boolean(id),
  })
}
