import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { ApiError } from '../api/client'
import { CompensationHistoryTable } from '../components/CompensationHistoryTable'
import { StatusBadge } from '../components/StatusBadge'
import { useEmployee } from '../hooks/useEmployee'
import { useTerminateEmployee } from '../hooks/useTerminateEmployee'
import { formatDate, formatMoney, formatUsd } from '../utils/format'

function today(): string {
  return new Date().toISOString().slice(0, 10)
}

export function EmployeeDetailPage() {
  const { id } = useParams<{ id: string }>()
  const employee = useEmployee(id)
  const terminate = useTerminateEmployee(Number(id))
  const [actionError, setActionError] = useState<string | null>(null)

  async function handleTerminate() {
    if (!window.confirm('Terminate this employee as of today? This cannot be undone from here.')) return

    setActionError(null)
    try {
      await terminate.mutateAsync(today())
    } catch (err) {
      setActionError(err instanceof ApiError ? err.message : 'Failed to terminate employee.')
    }
  }

  if (employee.isLoading) return <p>Loading…</p>
  if (employee.isError || !employee.data) {
    return <div className="error-banner">Could not load this employee.</div>
  }

  const data = employee.data

  return (
    <div>
      <p>
        <Link to="/employees">&larr; Back to employees</Link>
      </p>

      <h1>{data.full_name}</h1>
      <p className="metric-label">{data.employee_number}</p>

      {actionError && (
        <div className="error-banner" role="alert">
          {actionError}
        </div>
      )}

      <div className="card-grid">
        <div className="card">
          <div className="metric-label">Status</div>
          <div className="metric-value">
            <StatusBadge status={data.employment_status} />
          </div>
        </div>
        <div className="card">
          <div className="metric-label">Department</div>
          <div className="metric-value">{data.department.name}</div>
        </div>
        <div className="card">
          <div className="metric-label">Country</div>
          <div className="metric-value">{data.country.name}</div>
        </div>
        <div className="card">
          <div className="metric-label">Job Level</div>
          <div className="metric-value">{data.job_level.name}</div>
        </div>
      </div>

      <div className="card detail-section">
        <h3>Profile</h3>
        <p>Email: {data.work_email}</p>
        <p>Job title: {data.job_title}</p>
        <p>Hire date: {formatDate(data.hire_date)}</p>
        {data.termination_date && <p>Termination date: {formatDate(data.termination_date)}</p>}
        {data.employment_status !== 'terminated' && (
          <button type="button" onClick={handleTerminate} disabled={terminate.isPending}>
            {terminate.isPending ? 'Terminating…' : 'Terminate employee'}
          </button>
        )}
      </div>

      <div className="card detail-section">
        <h3>Current compensation</h3>
        {data.current_compensation ? (
          <p>
            {formatMoney(data.current_compensation.amount_cents, data.current_compensation.currency_code)} /{' '}
            {data.current_compensation.pay_frequency} (~{formatUsd(data.current_compensation.annual_usd_cents)} / year)
          </p>
        ) : (
          <p>No current compensation on file.</p>
        )}
      </div>

      <div className="card">
        <h3>Compensation history</h3>
        <CompensationHistoryTable records={data.compensation_history} />
      </div>
    </div>
  )
}
