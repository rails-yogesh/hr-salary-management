import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { ApiError } from '../api/client'
import * as endpoints from '../api/endpoints'
import type { EmployeeDetail } from '../api/types'
import { renderWithProviders } from '../test/renderWithProviders'
import { RecordRaiseForm } from './RecordRaiseForm'

async function fillAndSubmit(user: ReturnType<typeof userEvent.setup>) {
  await user.clear(screen.getByLabelText('New amount'))
  await user.type(screen.getByLabelText('New amount'), '135000')
  await user.type(screen.getByLabelText('Effective date'), '2026-06-01')
  await user.selectOptions(screen.getByLabelText('Reason'), 'Promotion')
  await user.click(screen.getByRole('button', { name: /record change/i }))
}

describe('RecordRaiseForm', () => {
  it('submits the raise with amount converted to cents', async () => {
    const spy = vi.spyOn(endpoints, 'recordCompensationChange').mockResolvedValue({ id: 99 } as EmployeeDetail)
    const user = userEvent.setup()

    renderWithProviders(<RecordRaiseForm employeeId={7} defaultCurrencyCode="USD" />)
    await fillAndSubmit(user)

    await waitFor(() =>
      expect(spy).toHaveBeenCalledWith(7, {
        amount_cents: 13_500_000,
        currency_code: 'USD',
        pay_frequency: 'annual',
        effective_date: '2026-06-01',
        change_reason: 'promotion',
        note: undefined,
      }),
    )
    expect(await screen.findByRole('status')).toHaveTextContent('Compensation change recorded.')
  })

  it('clears the amount field after a successful submission', async () => {
    vi.spyOn(endpoints, 'recordCompensationChange').mockResolvedValue({ id: 99 } as EmployeeDetail)
    const user = userEvent.setup()

    renderWithProviders(<RecordRaiseForm employeeId={7} defaultCurrencyCode="USD" />)
    await fillAndSubmit(user)

    await waitFor(() => expect(screen.getByLabelText('New amount')).toHaveValue(null))
  })

  it('shows an error banner when the API rejects the change (e.g. out-of-order effective date)', async () => {
    vi.spyOn(endpoints, 'recordCompensationChange').mockRejectedValue(
      new ApiError(422, "effective_date must be after the current record's effective date (2026-01-01)"),
    )
    const user = userEvent.setup()

    renderWithProviders(<RecordRaiseForm employeeId={7} defaultCurrencyCode="USD" />)
    await fillAndSubmit(user)

    expect(await screen.findByRole('alert')).toHaveTextContent('effective_date must be after')
  })
})
