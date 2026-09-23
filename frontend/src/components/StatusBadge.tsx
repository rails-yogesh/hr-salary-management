import { EMPLOYMENT_STATUS_LABELS } from '../utils/employmentStatus'

export function StatusBadge({ status }: { status: string }) {
  return <span className={`status-badge ${status}`}>{EMPLOYMENT_STATUS_LABELS[status] ?? status}</span>
}
