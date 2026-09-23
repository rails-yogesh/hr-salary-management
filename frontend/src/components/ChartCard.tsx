import type { ReactNode } from 'react'

export function ChartCard({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="card detail-section">
      <h3>{title}</h3>
      {children}
    </div>
  )
}
