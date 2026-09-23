# Populates ACME's demo dataset: reference data, one HR-admin login, and
# 10,000 synthetic employees with compensation history. Safe to re-run —
# reference data upserts, and employee generation is skipped entirely once
# any employees exist (see the "already present" branch below). All names
# and emails are Faker-generated; no real employee or customer data is used.
TOTAL_EMPLOYEES = 10_000
BATCH_SIZE = 1_000
REFERENCE_DATE = Date.current

puts "== Reference data =="
refs = SeedData::ReferenceData.apply!(as_of_date: REFERENCE_DATE)
puts "Countries: #{refs[:countries].size}, Departments: #{refs[:departments].size}, Job levels: #{refs[:job_levels].size}"

puts "== Admin user =="
admin_email = ENV.fetch("SEED_ADMIN_EMAIL", "hr@acme.test")
admin_password = ENV.fetch("SEED_ADMIN_PASSWORD", "changeme123!")
AdminUser.find_or_create_by!(email: admin_email) { |user| user.password = admin_password }
puts "Login: #{admin_email} / #{admin_password.gsub(/./, "*")} (set SEED_ADMIN_PASSWORD to override)"

puts "== Employees =="
if Employee.exists?
  puts "#{Employee.count} employees already present — skipping generation."
else
  generator = SeedData::EmployeeGenerator.new(
    countries: refs[:countries],
    departments: refs[:departments],
    job_levels: refs[:job_levels],
    reference_date: REFERENCE_DATE
  )
  employee_attrs = generator.generate(TOTAL_EMPLOYEES)

  employee_attrs.each_slice(BATCH_SIZE).with_index(1) do |batch, i|
    Employee.insert_all!(batch.map { |attrs| SeedData::EmployeeGenerator.db_attributes(attrs) })
    print "\r  employees: #{[ i * BATCH_SIZE, TOTAL_EMPLOYEES ].min}/#{TOTAL_EMPLOYEES}"
  end
  puts

  id_by_number = Employee.where(employee_number: employee_attrs.map { |a| a[:employee_number] })
    .pluck(:employee_number, :id).to_h

  comp_generator = SeedData::CompensationGenerator.new(
    level_bands: SeedData::ReferenceData.level_bands,
    exchange_rates: SeedData::ReferenceData::EXCHANGE_RATES,
    reference_date: REFERENCE_DATE
  )
  comp_rows = employee_attrs.flat_map do |attrs|
    comp_generator.generate_for(
      employee_id: id_by_number.fetch(attrs[:employee_number]),
      job_level_rank: attrs[:job_level_rank],
      currency_code: attrs[:currency_code],
      hire_date: attrs[:hire_date]
    )
  end

  comp_rows.each_slice(BATCH_SIZE).with_index(1) do |batch, i|
    CompensationRecord.insert_all!(batch)
    print "\r  compensation records: #{[ i * BATCH_SIZE, comp_rows.size ].min}/#{comp_rows.size}"
  end
  puts
end

puts "== Done =="
puts "Employees: #{Employee.count}, Compensation records: #{CompensationRecord.count}"
