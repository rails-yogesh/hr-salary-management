import { useQuery } from '@tanstack/react-query'
import { fetchLookups } from '../api/endpoints'

export function useLookups() {
  return useQuery({
    queryKey: ['lookups'],
    queryFn: fetchLookups,
    staleTime: Infinity, // countries/departments/job levels don't change during a session
  })
}
