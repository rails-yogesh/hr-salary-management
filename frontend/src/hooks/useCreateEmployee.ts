import { useMutation, useQueryClient } from '@tanstack/react-query'
import { createEmployee, type CreateEmployeePayload } from '../api/endpoints'

export function useCreateEmployee() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (payload: CreateEmployeePayload) => createEmployee(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['employees'] })
    },
  })
}
