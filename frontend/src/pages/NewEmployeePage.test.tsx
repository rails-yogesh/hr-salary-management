import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { ApiError } from '../api/client'
import * as endpoints from '../api/endpoints'
import type { EmployeeDetail, Lookups } from '../api/types'
import { renderWithProviders } from '../test/renderWithProviders'
import { NewEmployeePage } from './NewEmployeePage'

const lookups: Lookups = {
  countries: [
    { id: 1, code: 'US', name: 'United States', currency_code: 'USD' },
    { id: 2, code: 'ID', name: 'Indonesia', currency_code: 'IDR' },
  ],
  departments: [{ id: 1, name: 'Engineering' }],
  job_levels: [{ id: 1, name: 'L1', rank: 1 }],
}

function renderNewEmployeePage() {
  return renderWithProviders(
    <Routes>
      <Route path="/employees/new" element={<NewEmployeePage />} />
      <Route path="/employees/:id" element={<div>Employee Detail Page</div>} />
    </Routes>,
    { route: '/employees/new' },
  )
}

async function fillRequiredFields(user: ReturnType<typeof userEvent.setup>) {
  await screen.findByRole('option', { name: 'United States' })
  await user.type(screen.getByLabelText('First name'), 'Ada')
  await user.type(screen.getByLabelText('Last name'), 'Lovelace')
  await user.type(screen.getByLabelText('Work email'), 'ada@acme.test')
  await user.type(screen.getByLabelText('Job title'), 'Software Engineer')
  await user.selectOptions(screen.getByLabelText('Country'), 'United States')
  await user.selectOptions(screen.getByLabelText('Department'), 'Engineering')
  await user.selectOptions(screen.getByLabelText('Job level'), 'L1')
  await user.type(screen.getByLabelText('Hire date'), '2026-01-15')
  await user.type(screen.getByLabelText('Amount'), '90000')
}

describe('NewEmployeePage', () => {
  beforeEach(() => {
    vi.spyOn(endpoints, 'fetchLookups').mockResolvedValue(lookups)
  })

  it('auto-fills the currency when a country is selected', async () => {
    const user = userEvent.setup()
    renderNewEmployeePage()

    await screen.findByRole('option', { name: 'Indonesia' })
    await user.selectOptions(screen.getByLabelText('Country'), 'Indonesia')

    expect(screen.getByLabelText('Currency')).toHaveValue('IDR')
  })

  it('creates the employee and navigates to their detail page', async () => {
    const createSpy = vi.spyOn(endpoints, 'createEmployee').mockResolvedValue({ id: 42 } as EmployeeDetail)
    const user = userEvent.setup()

    renderNewEmployeePage()
    await screen.findByLabelText('Country')
    await fillRequiredFields(user)
    await user.click(screen.getByRole('button', { name: /create employee/i }))

    await waitFor(() => expect(screen.getByText('Employee Detail Page')).toBeInTheDocument())

    expect(createSpy).toHaveBeenCalledWith({
      employee: {
        first_name: 'Ada',
        last_name: 'Lovelace',
        work_email: 'ada@acme.test',
        job_title: 'Software Engineer',
        country_id: 1,
        department_id: 1,
        job_level_id: 1,
        hire_date: '2026-01-15',
      },
      compensation: {
        amount_cents: 9_000_000,
        currency_code: 'USD',
        pay_frequency: 'annual',
        effective_date: '2026-01-15',
      },
    })
  })

  it('shows an error banner and does not navigate when creation fails', async () => {
    vi.spyOn(endpoints, 'createEmployee').mockRejectedValue(new ApiError(422, "Work email has already been taken"))
    const user = userEvent.setup()

    renderNewEmployeePage()
    await screen.findByLabelText('Country')
    await fillRequiredFields(user)
    await user.click(screen.getByRole('button', { name: /create employee/i }))

    expect(await screen.findByRole('alert')).toHaveTextContent('Work email has already been taken')
    expect(screen.queryByText('Employee Detail Page')).not.toBeInTheDocument()
  })
})
