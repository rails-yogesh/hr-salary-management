export function formatMoney(amountCents: number, currencyCode: string): string {
  return new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: currencyCode,
    maximumFractionDigits: 0,
  }).format(amountCents / 100)
}

export function formatUsd(amountCents: number): string {
  return formatMoney(amountCents, 'USD')
}

// Rails serializes `date` columns as plain "YYYY-MM-DD" with no time
// component. `new Date("YYYY-MM-DD")` parses that as UTC midnight, which
// `toLocaleDateString` then renders a day early in any timezone behind UTC.
// Parsing the parts into a *local* Date avoids that off-by-one.
export function formatDate(isoDate: string): string {
  const [year, month, day] = isoDate.split('-').map(Number)
  return new Date(year, month - 1, day).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}
