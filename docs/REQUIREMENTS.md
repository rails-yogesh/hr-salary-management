CLASSIFICATION: INTERNAL

# Requirements: Employee Salary Management Software (ACME)

## Goal
ACME's HR team manages salary data for ~10,000 employees across multiple
countries by hand in spreadsheets. This is slow, error-prone, and cannot
answer aggregate questions ("what do we spend on Engineering in Indonesia?")
without manual pivoting. We are replacing the spreadsheet workflow with a
web application that lets a single HR Manager persona maintain accurate,
auditable salary records and answer organization-wide pay questions
on demand.

## Primary user
HR Manager — one internal role. Not building for employee self-service,
line managers, finance, or payroll operators in this iteration.

## In scope

**Employee & compensation records**
- Maintain employee profiles: name, employee number, work email, country,
  department, job level/title, employment status, hire date.
- Record compensation as a dated history, not a single overwritable number:
  every raise, promotion adjustment, or correction is a new dated record.
  Nothing is destructively overwritten — an HR manager can always answer
  "what did this person earn on date X, and why did it change".
- Search, filter (country/department/status), and paginate the employee
  roster — needs to stay fast at 10,000+ rows.
- Terminate/offboard an employee (status change, not deletion — history is
  retained).

**Answering "how does the org pay people"**
- Dashboard: total headcount and total annualized payroll cost, normalized
  to a common currency (USD) so cross-country totals are meaningful.
- Breakdown of headcount and cost by country and by department.
- Salary distribution by job level, to see pay bands and outliers.
- All of the above computed live from current data, not a stale export.

**Access control**
- Single HR-admin login (token-based). The application is not usable
  without authentication.

**Non-functional**
- Works correctly and stays responsive with 10,000 seeded employees and
  a multi-record compensation history per employee.
- Automated tests cover the domain logic that would be expensive to get
  wrong (money handling, the append-only compensation invariant, auth).
- Runs anywhere via `docker-compose up` — no bespoke local setup required
  to evaluate it.

## Deliberately out of scope (and why)

- **Payroll processing, tax withholding, payslip generation.** Tax rules
  are country-specific, legally sensitive, and a multi-quarter project on
  their own. This tool answers "what do we pay," not "how do we run
  payroll" — those are adjacent but separable systems, typically bought
  (e.g. a Mekari Talenta-style payroll product) rather than built here.
- **Live FX rates.** Real-time currency conversion needs a paid data feed
  and introduces a moving target for every historical report ("what was
  the USD total in March" would change every time you asked). We use a
  static, dated exchange-rate snapshot and label it as such everywhere it
  affects a number. ASSUMPTION: point-in-time accuracy is not required for
  this iteration; if it is, swap the snapshot table for a rate-history
  table plus a provider integration.
- **Multi-role RBAC / org-wide SSO.** The stated persona is a single HR
  Manager. Building granular roles (manager view, employee self-service,
  finance read-only) without a second persona to design against would be
  speculative scope. We do implement real authentication (not "no login"),
  because shipping salary data behind zero auth is not an acceptable
  default even for a single-persona MVP.
- **Bank/disbursement integration.** Out of scope for the same reason as
  payroll processing — a distinct, compliance-heavy system.
- **Org chart, performance reviews, leave/benefits management.** Adjacent
  HR domains with their own data models; adding them here would dilute
  focus on the stated problem (salary data).
- **Approval workflows for raises.** The HR Manager persona is trusted to
  record compensation changes directly. A maker-checker workflow is a
  reasonable next step once a second role exists to check against.
- **Field-level encryption / advanced data-residency controls.** Salary
  amounts are sensitive; this iteration relies on standard controls
  (auth required, TLS at the infra layer in real deployment, parameterized
  queries, no PII in logs) rather than encryption-at-rest for structured
  columns. Flagged in docs/ARCHITECTURE.md as a gap to close before
  handling real employee PII.
- **Real cloud hosting.** Delivered as a fully working, one-command
  Docker Compose stack rather than deployed to a live cloud endpoint —
  no hosting account/credentials were provided for this exercise.
  ASSUMPTION, confirmed with stakeholder: this satisfies "fully functional
  deployed software" for evaluation purposes.

## Data note
All 10,000 employee records are synthetically generated (Faker) for
demonstration. No real employee or customer PII is used anywhere in this
codebase, seed data, or documentation.
