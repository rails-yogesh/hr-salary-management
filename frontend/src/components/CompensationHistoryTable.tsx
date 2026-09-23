import type { CompensationRecord } from '../api/types'
import { CHANGE_REASON_LABELS } from '../utils/employmentStatus'
import { formatDate, formatMoney, formatUsd } from '../utils/format'

export function CompensationHistoryTable({ records }: { records: CompensationRecord[] }) {
  if (records.length === 0) return <p>No compensation history yet.</p>

  return (
    <table>
      <thead>
        <tr>
          <th>Effective</th>
          <th>Ends</th>
          <th>Amount</th>
          <th>Frequency</th>
          <th>Annualized (USD)</th>
          <th>Reason</th>
          <th>Note</th>
        </tr>
      </thead>
      <tbody>
        {records.map((record) => (
          <tr key={record.id}>
            <td>{formatDate(record.effective_date)}</td>
            <td>{record.end_date ? formatDate(record.end_date) : <strong>Current</strong>}</td>
            <td>{formatMoney(record.amount_cents, record.currency_code)}</td>
            <td>{record.pay_frequency}</td>
            <td>{formatUsd(record.annual_usd_cents)}</td>
            <td>{CHANGE_REASON_LABELS[record.change_reason] ?? record.change_reason}</td>
            <td>{record.note ?? '—'}</td>
          </tr>
        ))}
      </tbody>
    </table>
  )
}
