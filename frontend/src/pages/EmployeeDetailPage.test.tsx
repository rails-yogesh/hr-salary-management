import { screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Route, Routes } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import * as endpoints from '../api/endpoints'
import type { EmployeeDetail } from '../api/types'
import { renderWithProviders } from '../test/renderWithProviders'
import { EmployeeDetailPage } from './EmployeeDetailPage'

function employeeDetail(overrides: Partial<EmployeeDetail> = {}): EmployeeDetail {
  return {
    id: 7,
    employee_number: 'EMP000007',
    full_name: 'Grace Hopper',
    work_email: 'grace.hopper@acme.test',
    job_title: 'Staff Engineer',
    employment_status: 'active',
    hire_date: '2022-03-15',
    termination_date: null,
    country: { id: 1, code: 'US', name: 'United States' },
    department: { id: 1, name: 'Engineering' },
    job_level: { id: 4, name: 'L4 - Lead', rank: 4 },
    current_compensation: {
      id: 2,
      amount_cents: 150_000_00,
      currency_code: 'USD',
      pay_frequency: 'annual',
      annual_amount_cents: 150_000_00,
      annual_usd_cents: 150_000_00,
      effective_date: '2024-01-01',
      end_date: null,
      current: true,
      change_reason: 'promotion',
      note: null,
    },
    compensation_history: [
      {
        id: 1,
        amount_cents: 120_000_00,
        currency_code: 'USD',
        pay_frequency: 'annual',
        annual_amount_cents: 120_000_00,
        annual_usd_cents: 120_000_00,
        effective_date: '2022-03-15',
        end_date: '2023-12-31',
        current: false,
        change_reason: 'hire',
        note: null,
      },
      {
        id: 2,
        amount_cents: 150_000_00,
        currency_code: 'USD',
        pay_frequency: 'annual',
        annual_amount_cents: 150_000_00,
        annual_usd_cents: 150_000_00,
        effective_date: '2024-01-01',
        end_date: null,
        current: true,
        change_reason: 'promotion',
        note: null,
      },
    ],
    ...overrides,
  }
}

function renderDetailPage() {
  return renderWithProviders(
    <Routes>
      <Route path="/employees/:id" element={<EmployeeDetailPage />} />
    </Routes>,
    { route: '/employees/7' },
  )
}

describe('EmployeeDetailPage', () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('renders the profile and full compensation history', async () => {
    vi.spyOn(endpoints, 'fetchEmployee').mockResolvedValue(employeeDetail())

    renderDetailPage()

    expect(await screen.findByRole('heading', { name: 'Grace Hopper' })).toBeInTheDocument()
    expect(screen.getByText(/Job title:/)).toHaveTextContent('Staff Engineer')
    expect(screen.getByText(/year\)/)).toHaveTextContent('$150,000 / annual (~$150,000 / year)')
    const historyTable = screen.getByRole('table')
    expect(within(historyTable).getAllByRole('row')).toHaveLength(3) // header + 2 history rows
    expect(within(historyTable).getByText('Hire')).toBeInTheDocument()
    expect(within(historyTable).getByText('Promotion')).toBeInTheDocument()
  })

  it('shows an error state when the employee cannot be loaded', async () => {
    vi.spyOn(endpoints, 'fetchEmployee').mockRejectedValue(new Error('boom'))

    renderDetailPage()

    expect(await screen.findByText('Could not load this employee.')).toBeInTheDocument()
  })

  it('does not show a terminate button for an already-terminated employee', async () => {
    vi.spyOn(endpoints, 'fetchEmployee').mockResolvedValue(
      employeeDetail({ employment_status: 'terminated', termination_date: '2026-01-01' }),
    )

    renderDetailPage()

    await screen.findByRole('heading', { name: 'Grace Hopper' })
    expect(screen.queryByRole('button', { name: /terminate employee/i })).not.toBeInTheDocument()
    expect(screen.getByText(/Termination date/)).toBeInTheDocument()
  })

  describe('terminating an employee', () => {
    beforeEach(() => {
      vi.spyOn(endpoints, 'fetchEmployee').mockResolvedValue(employeeDetail())
    })

    it('does nothing if the confirmation is dismissed', async () => {
      vi.spyOn(window, 'confirm').mockReturnValue(false)
      const terminateSpy = vi.spyOn(endpoints, 'terminateEmployee')
      const user = userEvent.setup()

      renderDetailPage()
      await user.click(await screen.findByRole('button', { name: /terminate employee/i }))

      expect(terminateSpy).not.toHaveBeenCalled()
    })

    it('calls the API and reflects the terminated status on success', async () => {
      vi.spyOn(window, 'confirm').mockReturnValue(true)
      vi.spyOn(endpoints, 'terminateEmployee').mockResolvedValue(
        employeeDetail({ employment_status: 'terminated', termination_date: '2026-09-23' }),
      )
      const user = userEvent.setup()

      renderDetailPage()
      await user.click(await screen.findByRole('button', { name: /terminate employee/i }))

      await waitFor(() => expect(endpoints.terminateEmployee).toHaveBeenCalledWith(7, expect.any(String)))
      expect(await screen.findByText('Terminated', { selector: '.status-badge' })).toBeInTheDocument()
    })

    it('shows an error banner if terminating fails', async () => {
      vi.spyOn(window, 'confirm').mockReturnValue(true)
      const { ApiError } = await import('../api/client')
      vi.spyOn(endpoints, 'terminateEmployee').mockRejectedValue(new ApiError(422, 'termination_date is invalid'))
      const user = userEvent.setup()

      renderDetailPage()
      await user.click(await screen.findByRole('button', { name: /terminate employee/i }))

      expect(await screen.findByRole('alert')).toHaveTextContent('termination_date is invalid')
    })
  })
})
