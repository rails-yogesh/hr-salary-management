import { useMutation, useQueryClient } from '@tanstack/react-query'
import { terminateEmployee } from '../api/endpoints'

export function useTerminateEmployee(employeeId: number) {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (terminationDate: string) => terminateEmployee(employeeId, terminationDate),
    onSuccess: (updated) => {
      queryClient.setQueryData(['employee', String(employeeId)], updated)
      queryClient.invalidateQueries({ queryKey: ['employees'] })
    },
  })
}
