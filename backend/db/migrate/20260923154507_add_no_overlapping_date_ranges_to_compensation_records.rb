# Security review 2026-09-23 (SEC-H1): the app already validates that a new
# compensation record's effective_date comes after the employee's most
# recent record (CompensationRecord / Employees::RecordCompensationChange),
# but nothing at the database level stopped two records for the same
# employee from having overlapping [effective_date, end_date] ranges. This
# mirrors the existing pattern for the "one current record per employee"
# invariant, which is enforced by both an app validation *and* a DB partial
# unique index — the DB constraint is what still holds if the app-level
# check is ever bypassed (a future feature, a console fix, a bug).
#
# end_date IS NULL (the current record) becomes an unbounded-above range,
# so it correctly overlaps-and-conflicts with any other range that doesn't
# end before it starts.
class AddNoOverlappingDateRangesToCompensationRecords < ActiveRecord::Migration[7.2]
  def change
    enable_extension "btree_gist" unless extension_enabled?("btree_gist")

    add_exclusion_constraint :compensation_records,
      "employee_id WITH =, daterange(effective_date, end_date, '[]') WITH &&",
      using: :gist,
      name: "compensation_records_no_overlapping_date_ranges"
  end
end
