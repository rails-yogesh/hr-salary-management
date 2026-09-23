CLASSIFICATION: INTERNAL

# Architecture

See `docs/REQUIREMENTS.md` for scope. This document covers how the system
is built and why, and calls out the security posture explicitly.

## System overview

```
                       ┌─────────────────────────┐
   Browser  ───────▶   │  nginx (frontend image)  │
                       │  - serves the React SPA  │
                       │  - proxies /api/* -----> │──┐
                       └─────────────────────────┘  │
                                                     ▼
                                        ┌──────────────────────┐
                                        │ Rails API (backend)  │
                                        │  Api::V1::* controllers│
                                        │  JWT auth             │
                                        └──────────┬────────────┘
                                                     │
                                                     ▼
                                        ┌──────────────────────┐
                                        │      PostgreSQL       │
                                        └──────────────────────┘
```

Three containers (`docker-compose.yml`): `db`, `backend`, `frontend`. The
browser only ever talks to nginx on one origin; nginx forwards `/api/*`
to the backend unchanged, and falls back to `index.html` for client-side
routes (`/employees/42`, etc.).

## Backend

**Domain model** (`backend/app/models/`):

- `Employee` belongs to `Country`, `Department`, `JobLevel`.
- `CompensationRecord` belongs to `Employee`. This is the one modeling
  decision worth understanding before touching the code: **compensation is
  an append-only history, not a mutable field.** A record has an
  `effective_date` and an `end_date`; `end_date IS NULL` means "current."
  Recording a raise (`Employees::RecordCompensationChange`) closes the old
  current record and opens a new one, in one transaction. A partial unique
  index (`compensation_records` migration) enforces "at most one current
  record per employee" at the database level — the model validation
  backing it up is there for a friendlier error message, not as the real
  guarantee.
- Money is `amount_cents` (bigint) + `currency_code` (ISO 4217), never a
  float. `ExchangeRate` is a small, dated, static snapshot table (not a
  live feed — see `docs/REQUIREMENTS.md`) used to normalize cross-currency
  totals to USD.

**API** (`backend/app/controllers/api/v1/`): namespaced REST-ish JSON
endpoints. `Api::V1::BaseController` requires a JWT bearer token by
default (`before_action`) — new controllers are locked down unless they
explicitly opt out (`HealthController` does, for load-balancer checks).
Business logic that spans more than one record (creating an employee with
its first compensation record, recording a raise, the seed data
generators) lives in `app/services/`, not in controllers or fattened
models — this keeps the transactional invariants in one place with direct
unit-test coverage instead of being reverse-engineered from
controller specs.

**Dashboard analytics** (`app/services/dashboard/analytics.rb`): four SQL
aggregation queries (`COUNT`/`SUM`/`AVG`/`MIN`/`MAX` with `GROUP BY`), not
Ruby-side loops over loaded records. This is the endpoint most likely to
get slow as headcount grows, so it stays a handful of indexed joins
(`CompensationRecord` → `ExchangeRate` via a natural-key `belongs_to` on
`currency_code`, → `Employee` → `Country`/`Department`/`JobLevel`) computed
in the database rather than N+1 lookups.

## Frontend

Vite + React + TypeScript SPA (`frontend/src/`). No heavier framework or
design system — this is a standalone exercise, not a product surface with
existing conventions to match.

- `api/client.ts` — the one fetch wrapper everything goes through (bearer
  token, query params, error message extraction). Unit-tested directly.
- `api/endpoints.ts` + `api/types.ts` — typed functions/interfaces mapping
  1:1 to the Rails JSON shapes.
- `context/` — auth state (JWT in `localStorage`), guarding routes via
  `ProtectedRoute`.
- `hooks/` — TanStack Query wrappers per resource (caching, pagination,
  invalidation-on-mutation).
- `pages/` + `components/` — one page per route; shared display bits
  (`StatusBadge`, `CompensationHistoryTable`, `ChartCard`) factored out
  once used in more than one place, not preemptively.

## Security posture (explicit, not assumed)

Labeling this clearly since it's the section most likely to matter if this
codebase's patterns get reused elsewhere:

- **Access control**: single HR-admin role, JWT bearer auth, deny-by-default
  on every controller (see above). No RBAC — there is exactly one persona
  in scope (`docs/REQUIREMENTS.md`). Do not treat this auth scheme as a
  template for a multi-tenant or multi-role system; it isn't one.
- **Secrets management**: `SECRET_KEY_BASE` is read from `ENV` (never
  committed); `config/master.key` is gitignored and not used by the
  Docker image. The docker-compose stack ships a placeholder
  `SECRET_KEY_BASE` and seeded admin password so it runs with zero setup —
  both are clearly labeled "insecure, local demo only" in
  `docker-compose.yml` and `.env.example` and must be overridden for
  anything beyond that.
  Neither password appears in this document with a real value.
- **Input validation**: all mutations go through ActiveRecord validations
  and strong parameters (`permit`); the search scope uses a parameterized
  `ILIKE` (`sanitize_sql_like`), not string interpolation — no raw SQL is
  built from user input anywhere in the codebase.
- **Transport**: `config.force_ssl` is off by default
  (`config/environments/production.rb`) because the docker-compose
  deployment serves plain HTTP with no TLS-terminating proxy in front of
  it. Set `FORCE_SSL=true` if this is ever deployed behind real TLS
  termination.
- **Data at rest**: no field-level encryption on salary amounts. Standard
  controls apply (auth required, parameterized queries, no PII in logs —
  `filter_parameter_logging.rb`), but this is a gap to close before this
  pattern is used with real employee data. Flagged as unverified/ASSUMPTION
  territory rather than treated as already handled — see
  `docs/REQUIREMENTS.md`'s "deliberately out of scope" section.
- **Seed data**: every employee record is Faker-generated. No real
  employee or customer PII exists anywhere in this repository, database,
  or seed script.
