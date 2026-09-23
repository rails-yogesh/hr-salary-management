import { screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import * as endpoints from '../api/endpoints'
import { renderWithProviders } from '../test/renderWithProviders'
import { DashboardPage } from './DashboardPage'

function mockDashboardEndpoints() {
  vi.spyOn(endpoints, 'fetchDashboardSummary').mockResolvedValue({
    headcount: 9_484,
    total_annual_cost_usd_cents: 512_345_678_00,
    average_annual_cost_usd_cents: 54_012_00,
  })
  vi.spyOn(endpoints, 'fetchDashboardByCountry').mockResolvedValue([
    { label: 'Indonesia', headcount: 3_379, total_annual_cost_usd_cents: 180_000_000_00 },
    { label: 'United States', headcount: 1_551, total_annual_cost_usd_cents: 200_000_000_00 },
  ])
  vi.spyOn(endpoints, 'fetchDashboardByDepartment').mockResolvedValue([
    { label: 'Engineering', headcount: 3_000, total_annual_cost_usd_cents: 250_000_000_00 },
  ])
  vi.spyOn(endpoints, 'fetchSalaryDistribution').mockResolvedValue([
    { label: 'L1 - Associate', headcount: 2_973, average_annual_cost_usd_cents: 32_000_00, min_annual_cost_usd_cents: 25_000_00, max_annual_cost_usd_cents: 40_000_00 },
    { label: 'L6 - Director', headcount: 174, average_annual_cost_usd_cents: 190_000_00, min_annual_cost_usd_cents: 160_000_00, max_annual_cost_usd_cents: 220_000_00 },
  ])
}

describe('DashboardPage', () => {
  it('renders headline metrics formatted as USD', async () => {
    mockDashboardEndpoints()
    renderWithProviders(<DashboardPage />)

    expect(await screen.findByText('9,484')).toBeInTheDocument()
    expect(screen.getByText('$512,345,678')).toBeInTheDocument()
    expect(screen.getByText('$54,012')).toBeInTheDocument()
  })

  it('renders chart section headings', async () => {
    mockDashboardEndpoints()
    renderWithProviders(<DashboardPage />)

    expect(await screen.findByText('Cost & Headcount by Country')).toBeInTheDocument()
    expect(screen.getByText('Cost & Headcount by Department')).toBeInTheDocument()
  })

  it('renders the salary distribution table with formatted figures', async () => {
    mockDashboardEndpoints()
    renderWithProviders(<DashboardPage />)

    const row = await screen.findByRole('row', { name: /L1 - Associate/ })
    expect(row).toHaveTextContent('2973')
    expect(row).toHaveTextContent('$32,000')
    expect(row).toHaveTextContent('$25,000')
    expect(row).toHaveTextContent('$40,000')
  })

  it('shows an error state if any dashboard request fails', async () => {
    vi.spyOn(endpoints, 'fetchDashboardSummary').mockRejectedValue(new Error('boom'))
    vi.spyOn(endpoints, 'fetchDashboardByCountry').mockResolvedValue([])
    vi.spyOn(endpoints, 'fetchDashboardByDepartment').mockResolvedValue([])
    vi.spyOn(endpoints, 'fetchSalaryDistribution').mockResolvedValue([])

    renderWithProviders(<DashboardPage />)

    expect(await screen.findByText('Failed to load dashboard data.')).toBeInTheDocument()
  })
})
