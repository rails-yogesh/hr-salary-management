import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { ApiError } from '../api/client'
import type { PayFrequency } from '../api/types'
import { useCreateEmployee } from '../hooks/useCreateEmployee'
import { useLookups } from '../hooks/useLookups'

export function NewEmployeePage() {
  const navigate = useNavigate()
  const lookups = useLookups()
  const createEmployee = useCreateEmployee()

  const [firstName, setFirstName] = useState('')
  const [lastName, setLastName] = useState('')
  const [workEmail, setWorkEmail] = useState('')
  const [jobTitle, setJobTitle] = useState('')
  const [countryId, setCountryId] = useState('')
  const [departmentId, setDepartmentId] = useState('')
  const [jobLevelId, setJobLevelId] = useState('')
  const [hireDate, setHireDate] = useState('')
  const [amount, setAmount] = useState('')
  const [currencyCode, setCurrencyCode] = useState('USD')
  const [payFrequency, setPayFrequency] = useState<PayFrequency>('annual')
  const [error, setError] = useState<string | null>(null)

  function handleCountryChange(value: string) {
    setCountryId(value)
    const country = lookups.data?.countries.find((c) => String(c.id) === value)
    if (country) setCurrencyCode(country.currency_code)
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    setError(null)

    try {
      const created = await createEmployee.mutateAsync({
        employee: {
          first_name: firstName,
          last_name: lastName,
          work_email: workEmail,
          job_title: jobTitle,
          country_id: Number(countryId),
          department_id: Number(departmentId),
          job_level_id: Number(jobLevelId),
          hire_date: hireDate,
        },
        compensation: {
          amount_cents: Math.round(Number(amount) * 100),
          currency_code: currencyCode,
          pay_frequency: payFrequency,
          effective_date: hireDate,
        },
      })
      navigate(`/employees/${created.id}`)
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Failed to create employee.')
    }
  }

  return (
    <div>
      <h1>Add Employee</h1>

      <form onSubmit={handleSubmit} className="form">
        {error && (
          <div className="error-banner" role="alert">
            {error}
          </div>
        )}

        <div className="form-row">
          <div className="field">
            <label htmlFor="first-name">First name</label>
            <input id="first-name" required value={firstName} onChange={(event) => setFirstName(event.target.value)} />
          </div>
          <div className="field">
            <label htmlFor="last-name">Last name</label>
            <input id="last-name" required value={lastName} onChange={(event) => setLastName(event.target.value)} />
          </div>
        </div>

        <div className="field">
          <label htmlFor="work-email">Work email</label>
          <input
            id="work-email"
            type="email"
            required
            value={workEmail}
            onChange={(event) => setWorkEmail(event.target.value)}
          />
        </div>

        <div className="field">
          <label htmlFor="job-title">Job title</label>
          <input id="job-title" required value={jobTitle} onChange={(event) => setJobTitle(event.target.value)} />
        </div>

        <div className="form-row">
          <div className="field">
            <label htmlFor="country">Country</label>
            <select id="country" required value={countryId} onChange={(event) => handleCountryChange(event.target.value)}>
              <option value="">Select a country</option>
              {lookups.data?.countries.map((country) => (
                <option key={country.id} value={country.id}>
                  {country.name}
                </option>
              ))}
            </select>
          </div>
          <div className="field">
            <label htmlFor="department">Department</label>
            <select id="department" required value={departmentId} onChange={(event) => setDepartmentId(event.target.value)}>
              <option value="">Select a department</option>
              {lookups.data?.departments.map((department) => (
                <option key={department.id} value={department.id}>
                  {department.name}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="form-row">
          <div className="field">
            <label htmlFor="job-level">Job level</label>
            <select id="job-level" required value={jobLevelId} onChange={(event) => setJobLevelId(event.target.value)}>
              <option value="">Select a job level</option>
              {lookups.data?.job_levels.map((level) => (
                <option key={level.id} value={level.id}>
                  {level.name}
                </option>
              ))}
            </select>
          </div>
          <div className="field">
            <label htmlFor="hire-date">Hire date</label>
            <input
              id="hire-date"
              type="date"
              required
              value={hireDate}
              onChange={(event) => setHireDate(event.target.value)}
            />
          </div>
        </div>

        <h3>Starting compensation</h3>

        <div className="form-row">
          <div className="field">
            <label htmlFor="amount">Amount</label>
            <input
              id="amount"
              type="number"
              min="0"
              step="0.01"
              required
              value={amount}
              onChange={(event) => setAmount(event.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="currency">Currency</label>
            <input
              id="currency"
              required
              maxLength={3}
              value={currencyCode}
              onChange={(event) => setCurrencyCode(event.target.value.toUpperCase())}
            />
          </div>
          <div className="field">
            <label htmlFor="pay-frequency">Pay frequency</label>
            <select
              id="pay-frequency"
              value={payFrequency}
              onChange={(event) => setPayFrequency(event.target.value as PayFrequency)}
            >
              <option value="annual">Annual</option>
              <option value="monthly">Monthly</option>
            </select>
          </div>
        </div>

        <button type="submit" className="primary" disabled={createEmployee.isPending}>
          {createEmployee.isPending ? 'Creating…' : 'Create employee'}
        </button>
      </form>
    </div>
  )
}
