import { describe, expect, it } from 'vitest'
import { formatDate, formatMoney, formatUsd } from './format'

describe('formatMoney', () => {
  it('formats whole-dollar USD amounts', () => {
    expect(formatMoney(100_000_00, 'USD')).toBe('$100,000')
  })

  it('formats other currencies with their own symbol', () => {
    expect(formatMoney(5_000_000_00, 'IDR')).toContain('5,000,000')
  })
})

describe('formatUsd', () => {
  it('is formatMoney pinned to USD', () => {
    expect(formatUsd(250_00)).toBe('$250')
  })
})

describe('formatDate', () => {
  it('renders a plain YYYY-MM-DD date without a timezone-related off-by-one', () => {
    // Regression check: this date, parsed as UTC midnight and rendered in a
    // timezone behind UTC, would incorrectly print Dec 31.
    expect(formatDate('2026-01-01')).toBe('Jan 1, 2026')
  })

  it('renders a mid-month date correctly', () => {
    expect(formatDate('2025-06-15')).toBe('Jun 15, 2025')
  })
})
