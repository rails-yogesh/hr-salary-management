CLASSIFICATION: INTERNAL

# Trade-offs and Performance Considerations

Decisions made under real time constraints, with reasoning, so they can be
revisited deliberately rather than rediscovered by accident.

## Deliberate trade-offs

- **Compensation history is append-only, never overwritten.** More schema
  and code (a service object instead of `update`) than a single mutable
  `salary` column. Chosen because "what did we pay this person and why did
  it change" is one of the stated questions the HR Manager needs answered,
  and because a demo tool for salary data should default to an audit trail
  rather than silent overwrites. Cost: every read of "current salary" is a
  join/lookup instead of a column read (mitigated by the partial unique
  index and the `current_compensation_record` association).
- **Static exchange-rate snapshot instead of a live FX feed.** A live feed
  needs a paid provider and makes historical totals a moving target (the
  same report run twice would return different numbers). Cost: USD
  totals are only as current as the last time someone updates
  `SeedData::ReferenceData::EXCHANGE_RATES`. Documented everywhere it
  affects a number (dashboard copy, `docs/REQUIREMENTS.md`).
- **Money stored as integer cents for every currency, including
  zero-decimal-in-practice ones like IDR.** Simpler schema (one column
  shape for all currencies) at the cost of large-looking numbers for
  weak currencies (e.g. an IDR salary is stored as billions of "cents").
  A system handling real IDR/JPY-style currencies would look up each
  currency's minor-unit exponent (ISO 4217 defines this) instead of
  assuming 2 decimal places everywhere. Not worth the complexity here.
- **No RBAC.** One persona (HR Manager) is in scope. Building a role
  system with no second role to design against would be speculative and
  likely wrong. See `docs/ARCHITECTURE.md`'s security section for what
  this means in practice.
- **Employee numbers are server-generated, not client-supplied**
  (`Employee.next_employee_number`), trading a tiny bit of flexibility for
  removing an entire class of collision/typo bugs.
- **Docker Compose instead of a real cloud deployment.** No hosting
  account/credentials were available for this exercise; a one-command
  `docker-compose up --build` was agreed as satisfying "fully functional
  deployed software" (see `docs/REQUIREMENTS.md`, confirmed with
  stakeholder before building).
- **Plain CSS, no component library.** This is a standalone exercise, not
  a product surface with an existing design system to integrate with.
  Recharts is the one exception (charting from scratch is not a good use
  of the time budget) — it does add ~370KB to the bundle, called out below.

## Performance considerations

- **Seeding 10,000 employees**: done via two batched `insert_all!` passes
  (1,000 rows per batch) instead of 10,000 individual `.create!` calls,
  which would run validations and callbacks per row and be dramatically
  slower. On the machine this was built on, generating 10,000 employees +
  ~14,700 compensation records takes about 5 seconds.
- **Dashboard analytics**: SQL aggregation (`GROUP BY` + `SUM`/`AVG`/`COUNT`)
  rather than loading records into Ruby, so it stays proportional to
  "number of countries/departments/job levels" (small, fixed) rather than
  "number of employees" for the response payload — the database still
  scans the compensation-records table, but that scan is a single indexed
  join per query, not N+1 lookups.
- **Employee list pagination**: capped at 100 per page
  (`Paginatable::MAX_PER_PAGE`) regardless of what a client requests, so a
  malicious or buggy `per_page=999999` can't force a full unpaginated scan
  through the API.
- **Search-as-you-type**: debounced 300ms client-side
  (`useDebouncedValue`) so typing a name doesn't fire one request per
  keystroke against a 10k-row table.
- **Frontend bundle size**: the production build is ~370KB gzip-adjacent
  mostly due to Recharts. Acceptable for this exercise; a real product
  would either code-split the dashboard route (`React.lazy`) or pick a
  lighter charting library if bundle size mattered.

## What I'd do differently with more time / at real scale

- Add a rate-history table for `ExchangeRate` (currency_code + as_of_date
  as a composite key) instead of one row per currency, so historical USD
  totals could be recomputed as-of a past date.
- Add database-level check constraints mirroring the Rails validations
  (e.g. `amount_cents > 0`) as defense-in-depth against direct DB access
  or a future bug in application-level validation.
- Move `Employees::RecordCompensationChange`'s effective-date comparison
  into the database transaction with a `SELECT ... FOR UPDATE` to close a
  narrow race window: two concurrent raises for the same employee could
  both read the same "current" record before either commits. Unlikely for
  a single HR-admin user, but worth flagging rather than ignoring for a
  system that will eventually have more than one editor.
- Load-test the dashboard endpoints beyond 10k employees to find where the
  aggregation queries start needing additional indexes or materialized
  summaries.
