import { useMutation, useQueryClient } from '@tanstack/react-query'
import { recordCompensationChange, type RecordRaisePayload } from '../api/endpoints'

export function useRecordCompensationChange(employeeId: number) {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (payload: RecordRaisePayload) => recordCompensationChange(employeeId, payload),
    onSuccess: (updated) => {
      queryClient.setQueryData(['employee', String(employeeId)], updated)
      queryClient.invalidateQueries({ queryKey: ['employees'] })
    },
  })
}
