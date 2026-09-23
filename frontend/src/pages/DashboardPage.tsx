import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { ChartCard } from '../components/ChartCard'
import {
  useDashboardByCountry,
  useDashboardByDepartment,
  useDashboardSummary,
  useSalaryDistribution,
} from '../hooks/useDashboardData'
import { formatUsd } from '../utils/format'

function CostBarChart({ data, color }: { data: { label: string; total_annual_cost_usd_cents: number }[]; color: string }) {
  return (
    <ResponsiveContainer width="100%" height={280}>
      <BarChart data={data}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="label" />
        <YAxis tickFormatter={(value: number) => formatUsd(value)} width={90} />
        <Tooltip formatter={(value: unknown) => formatUsd(Number(value))} />
        <Bar dataKey="total_annual_cost_usd_cents" name="Annual cost (USD)" fill={color} />
      </BarChart>
    </ResponsiveContainer>
  )
}

export function DashboardPage() {
  const summary = useDashboardSummary()
  const byCountry = useDashboardByCountry()
  const byDepartment = useDashboardByDepartment()
  const distribution = useSalaryDistribution()

  const isLoading = summary.isLoading || byCountry.isLoading || byDepartment.isLoading || distribution.isLoading
  const isError = summary.isError || byCountry.isError || byDepartment.isError || distribution.isError

  if (isLoading) return <p>Loading dashboard…</p>
  if (isError || !summary.data) return <div className="error-banner">Failed to load dashboard data.</div>

  return (
    <div>
      <h1>Dashboard</h1>
      <p className="metric-label">
        How ACME pays its people, normalized to USD using a static exchange-rate snapshot (see docs/REQUIREMENTS.md).
      </p>

      <div className="card-grid">
        <div className="card">
          <div className="metric-label">Headcount (active + on leave)</div>
          <div className="metric-value">{summary.data.headcount.toLocaleString()}</div>
        </div>
        <div className="card">
          <div className="metric-label">Total Annual Payroll Cost</div>
          <div className="metric-value">{formatUsd(summary.data.total_annual_cost_usd_cents)}</div>
        </div>
        <div className="card">
          <div className="metric-label">Average Annual Cost / Employee</div>
          <div className="metric-value">{formatUsd(summary.data.average_annual_cost_usd_cents)}</div>
        </div>
      </div>

      <ChartCard title="Cost & Headcount by Country">
        <CostBarChart data={byCountry.data ?? []} color="#4f46e5" />
      </ChartCard>

      <ChartCard title="Cost & Headcount by Department">
        <CostBarChart data={byDepartment.data ?? []} color="#15803d" />
      </ChartCard>

      <div className="card">
        <h3>Salary Distribution by Job Level</h3>
        <table>
          <thead>
            <tr>
              <th>Level</th>
              <th>Headcount</th>
              <th>Average</th>
              <th>Min</th>
              <th>Max</th>
            </tr>
          </thead>
          <tbody>
            {distribution.data?.map((row) => (
              <tr key={row.label}>
                <td>{row.label}</td>
                <td>{row.headcount}</td>
                <td>{formatUsd(row.average_annual_cost_usd_cents)}</td>
                <td>{formatUsd(row.min_annual_cost_usd_cents)}</td>
                <td>{formatUsd(row.max_annual_cost_usd_cents)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
