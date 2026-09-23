import { useState, type FormEvent } from 'react'
import { ApiError } from '../api/client'
import type { ChangeReason, PayFrequency } from '../api/types'
import { useRecordCompensationChange } from '../hooks/useRecordCompensationChange'
import { CHANGE_REASON_LABELS } from '../utils/employmentStatus'

const REASON_OPTIONS: ChangeReason[] = ['promotion', 'annual_review', 'market_adjustment', 'correction']

export function RecordRaiseForm({ employeeId, defaultCurrencyCode }: { employeeId: number; defaultCurrencyCode: string }) {
  const recordChange = useRecordCompensationChange(employeeId)
  const [amount, setAmount] = useState('')
  const [currencyCode, setCurrencyCode] = useState(defaultCurrencyCode)
  const [payFrequency, setPayFrequency] = useState<PayFrequency>('annual')
  const [effectiveDate, setEffectiveDate] = useState('')
  const [changeReason, setChangeReason] = useState<ChangeReason>('annual_review')
  const [note, setNote] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [justSaved, setJustSaved] = useState(false)

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    setError(null)
    setJustSaved(false)

    try {
      await recordChange.mutateAsync({
        amount_cents: Math.round(Number(amount) * 100),
        currency_code: currencyCode,
        pay_frequency: payFrequency,
        effective_date: effectiveDate,
        change_reason: changeReason,
        note: note || undefined,
      })
      setAmount('')
      setNote('')
      setJustSaved(true)
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Failed to record compensation change.')
    }
  }

  return (
    <form onSubmit={handleSubmit} className="form">
      {error && (
        <div className="error-banner" role="alert">
          {error}
        </div>
      )}
      {justSaved && (
        <div className="success-banner" role="status">
          Compensation change recorded.
        </div>
      )}

      <div className="form-row">
        <div className="field">
          <label htmlFor="raise-amount">New amount</label>
          <input
            id="raise-amount"
            type="number"
            min="0"
            step="0.01"
            required
            value={amount}
            onChange={(event) => setAmount(event.target.value)}
          />
        </div>
        <div className="field">
          <label htmlFor="raise-currency">Currency</label>
          <input
            id="raise-currency"
            required
            maxLength={3}
            value={currencyCode}
            onChange={(event) => setCurrencyCode(event.target.value.toUpperCase())}
          />
        </div>
      </div>

      <div className="form-row">
        <div className="field">
          <label htmlFor="raise-frequency">Pay frequency</label>
          <select
            id="raise-frequency"
            value={payFrequency}
            onChange={(event) => setPayFrequency(event.target.value as PayFrequency)}
          >
            <option value="annual">Annual</option>
            <option value="monthly">Monthly</option>
          </select>
        </div>
        <div className="field">
          <label htmlFor="raise-effective-date">Effective date</label>
          <input
            id="raise-effective-date"
            type="date"
            required
            value={effectiveDate}
            onChange={(event) => setEffectiveDate(event.target.value)}
          />
        </div>
      </div>

      <div className="field">
        <label htmlFor="raise-reason">Reason</label>
        <select id="raise-reason" value={changeReason} onChange={(event) => setChangeReason(event.target.value as ChangeReason)}>
          {REASON_OPTIONS.map((reason) => (
            <option key={reason} value={reason}>
              {CHANGE_REASON_LABELS[reason]}
            </option>
          ))}
        </select>
      </div>

      <div className="field">
        <label htmlFor="raise-note">Note (optional)</label>
        <input id="raise-note" value={note} onChange={(event) => setNote(event.target.value)} />
      </div>

      <button type="submit" className="primary" disabled={recordChange.isPending}>
        {recordChange.isPending ? 'Saving…' : 'Record change'}
      </button>
    </form>
  )
}
