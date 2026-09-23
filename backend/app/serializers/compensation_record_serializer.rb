module CompensationRecordSerializer
  def self.call(record)
    {
      id: record.id,
      amount_cents: record.amount_cents,
      currency_code: record.currency_code,
      pay_frequency: record.pay_frequency,
      annual_amount_cents: record.annual_amount_cents,
      annual_usd_cents: ExchangeRate.usd_cents_for(amount_cents: record.annual_amount_cents, currency_code: record.currency_code),
      effective_date: record.effective_date,
      end_date: record.end_date,
      current: record.end_date.nil?,
      change_reason: record.change_reason,
      note: record.note
    }
  end
end
