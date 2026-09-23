import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useDebouncedValue } from '../hooks/useDebouncedValue'
import { useEmployees } from '../hooks/useEmployees'
import { useLookups } from '../hooks/useLookups'
import { formatMoney } from '../utils/format'

const STATUS_LABELS: Record<string, string> = {
  active: 'Active',
  terminated: 'Terminated',
  on_leave: 'On Leave',
}

export function EmployeeListPage() {
  const [search, setSearch] = useState('')
  const [countryId, setCountryId] = useState('')
  const [departmentId, setDepartmentId] = useState('')
  const [status, setStatus] = useState('')
  const [page, setPage] = useState(1)

  const debouncedSearch = useDebouncedValue(search, 300)
  const lookups = useLookups()
  const employees = useEmployees({
    q: debouncedSearch || undefined,
    country_id: countryId ? Number(countryId) : undefined,
    department_id: departmentId ? Number(departmentId) : undefined,
    employment_status: status || undefined,
    page,
  })

  function handleFilterChange(setter: (value: string) => void) {
    return (event: React.ChangeEvent<HTMLSelectElement>) => {
      setter(event.target.value)
      setPage(1)
    }
  }

  const meta = employees.data?.meta

  return (
    <div>
      <h1>Employees</h1>

      <div className="filters">
        <input
          type="search"
          aria-label="Search employees"
          placeholder="Search name, email, or employee #"
          value={search}
          onChange={(event) => {
            setSearch(event.target.value)
            setPage(1)
          }}
        />
        <select aria-label="Filter by country" value={countryId} onChange={handleFilterChange(setCountryId)}>
          <option value="">All countries</option>
          {lookups.data?.countries.map((country) => (
            <option key={country.id} value={country.id}>
              {country.name}
            </option>
          ))}
        </select>
        <select aria-label="Filter by department" value={departmentId} onChange={handleFilterChange(setDepartmentId)}>
          <option value="">All departments</option>
          {lookups.data?.departments.map((department) => (
            <option key={department.id} value={department.id}>
              {department.name}
            </option>
          ))}
        </select>
        <select aria-label="Filter by status" value={status} onChange={handleFilterChange(setStatus)}>
          <option value="">All statuses</option>
          {Object.entries(STATUS_LABELS).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </select>
      </div>

      {employees.isError && <div className="error-banner">Failed to load employees. Please try again.</div>}

      {employees.isLoading && <p>Loading…</p>}

      {employees.data && (
        <>
          <table>
            <thead>
              <tr>
                <th>Employee</th>
                <th>Country</th>
                <th>Department</th>
                <th>Job Title</th>
                <th>Status</th>
                <th>Current Salary</th>
              </tr>
            </thead>
            <tbody>
              {employees.data.employees.map((employee) => (
                <tr key={employee.id}>
                  <td>
                    <Link to={`/employees/${employee.id}`}>{employee.full_name}</Link>
                    <div className="metric-label">{employee.employee_number}</div>
                  </td>
                  <td>{employee.country.name}</td>
                  <td>{employee.department.name}</td>
                  <td>{employee.job_title}</td>
                  <td>
                    <span className={`status-badge ${employee.employment_status}`}>
                      {STATUS_LABELS[employee.employment_status]}
                    </span>
                  </td>
                  <td>
                    {employee.current_compensation
                      ? `${formatMoney(employee.current_compensation.amount_cents, employee.current_compensation.currency_code)} / ${employee.current_compensation.pay_frequency}`
                      : '—'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {employees.data.employees.length === 0 && <p>No employees match these filters.</p>}

          {meta && (
            <div className="pagination">
              <button type="button" disabled={page <= 1} onClick={() => setPage((current) => current - 1)}>
                Previous
              </button>
              <span>
                Page {meta.current_page} of {meta.total_pages} ({meta.total_count} total)
              </span>
              <button
                type="button"
                disabled={page >= meta.total_pages}
                onClick={() => setPage((current) => current + 1)}
              >
                Next
              </button>
            </div>
          )}
        </>
      )}
    </div>
  )
}
