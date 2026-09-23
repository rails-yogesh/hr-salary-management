module EmployeeSerializer
  def self.list_item(employee)
    {
      id: employee.id,
      employee_number: employee.employee_number,
      full_name: employee.full_name,
      work_email: employee.work_email,
      job_title: employee.job_title,
      employment_status: employee.employment_status,
      hire_date: employee.hire_date,
      country: { id: employee.country.id, code: employee.country.code, name: employee.country.name },
      department: { id: employee.department.id, name: employee.department.name },
      job_level: { id: employee.job_level.id, name: employee.job_level.name, rank: employee.job_level.rank },
      current_compensation: employee.current_compensation_record && CompensationRecordSerializer.call(employee.current_compensation_record)
    }
  end

  def self.detail(employee)
    list_item(employee).merge(
      termination_date: employee.termination_date,
      compensation_history: employee.compensation_records.order(effective_date: :desc).map { |r| CompensationRecordSerializer.call(r) }
    )
  end
end
