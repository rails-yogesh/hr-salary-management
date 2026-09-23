import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import * as endpoints from '../api/endpoints'
import type { EmployeeListResponse, Lookups } from '../api/types'
import { renderWithProviders } from '../test/renderWithProviders'
import { EmployeeListPage } from './EmployeeListPage'

const lookups: Lookups = {
  countries: [{ id: 1, code: 'US', name: 'United States', currency_code: 'USD' }],
  departments: [{ id: 1, name: 'Engineering' }],
  job_levels: [{ id: 1, name: 'L1', rank: 1 }],
}

function employeeListResponse(overrides: Partial<EmployeeListResponse> = {}): EmployeeListResponse {
  return {
    employees: [
      {
        id: 1,
        employee_number: 'EMP000001',
        full_name: 'Ada Lovelace',
        work_email: 'ada@acme.test',
        job_title: 'Software Engineer',
        employment_status: 'active',
        hire_date: '2024-01-01',
        country: { id: 1, code: 'US', name: 'United States' },
        department: { id: 1, name: 'Engineering' },
        job_level: { id: 1, name: 'L1', rank: 1 },
        current_compensation: {
          id: 1,
          amount_cents: 100_000_00,
          currency_code: 'USD',
          pay_frequency: 'annual',
          annual_amount_cents: 100_000_00,
          annual_usd_cents: 100_000_00,
          effective_date: '2024-01-01',
          end_date: null,
          current: true,
          change_reason: 'hire',
          note: null,
        },
      },
    ],
    meta: { current_page: 1, total_pages: 1, total_count: 1, per_page: 25 },
    ...overrides,
  }
}

describe('EmployeeListPage', () => {
  beforeEach(() => {
    vi.spyOn(endpoints, 'fetchLookups').mockResolvedValue(lookups)
  })

  it('renders employees returned by the API', async () => {
    vi.spyOn(endpoints, 'fetchEmployees').mockResolvedValue(employeeListResponse())

    renderWithProviders(<EmployeeListPage />)

    expect(await screen.findByText('Ada Lovelace')).toBeInTheDocument()
    expect(screen.getByText('EMP000001')).toBeInTheDocument()
    expect(screen.getByText('$100,000 / annual')).toBeInTheDocument()
    expect(screen.getByText('Active', { selector: '.status-badge' })).toBeInTheDocument()
  })

  it('shows an empty state when no employees match', async () => {
    vi.spyOn(endpoints, 'fetchEmployees').mockResolvedValue(
      employeeListResponse({ employees: [], meta: { current_page: 1, total_pages: 1, total_count: 0, per_page: 25 } }),
    )

    renderWithProviders(<EmployeeListPage />)

    expect(await screen.findByText('No employees match these filters.')).toBeInTheDocument()
  })

  it('debounces search input and refetches with the query', async () => {
    const fetchSpy = vi.spyOn(endpoints, 'fetchEmployees').mockResolvedValue(employeeListResponse())
    const user = userEvent.setup()

    renderWithProviders(<EmployeeListPage />)
    await screen.findByText('Ada Lovelace')
    fetchSpy.mockClear()

    await user.type(screen.getByLabelText('Search employees'), 'hopper')

    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalledWith(expect.objectContaining({ q: 'hopper', page: 1 }))
    })
  })

  it('applies country/department/status filters and resets to page 1', async () => {
    const fetchSpy = vi.spyOn(endpoints, 'fetchEmployees').mockResolvedValue(employeeListResponse())
    const user = userEvent.setup()

    renderWithProviders(<EmployeeListPage />)
    await screen.findByText('Ada Lovelace')
    fetchSpy.mockClear()

    await user.selectOptions(screen.getByLabelText('Filter by country'), 'United States')

    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalledWith(expect.objectContaining({ country_id: 1, page: 1 }))
    })
  })

  it('disables Previous on the first page and Next on the last page', async () => {
    vi.spyOn(endpoints, 'fetchEmployees').mockResolvedValue(
      employeeListResponse({ meta: { current_page: 1, total_pages: 1, total_count: 1, per_page: 25 } }),
    )

    renderWithProviders(<EmployeeListPage />)
    await screen.findByText('Ada Lovelace')

    expect(screen.getByRole('button', { name: 'Previous' })).toBeDisabled()
    expect(screen.getByRole('button', { name: 'Next' })).toBeDisabled()
  })

  it('advances to the next page and calls the API with page 2', async () => {
    const fetchSpy = vi
      .spyOn(endpoints, 'fetchEmployees')
      .mockResolvedValue(employeeListResponse({ meta: { current_page: 1, total_pages: 2, total_count: 2, per_page: 1 } }))
    const user = userEvent.setup()

    renderWithProviders(<EmployeeListPage />)
    await screen.findByText('Ada Lovelace')
    fetchSpy.mockClear()

    await user.click(screen.getByRole('button', { name: 'Next' }))

    await waitFor(() => {
      expect(fetchSpy).toHaveBeenCalledWith(expect.objectContaining({ page: 2 }))
    })
  })
})
