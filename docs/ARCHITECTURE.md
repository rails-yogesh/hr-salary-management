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
codebase's patterns get reused elsewhere. A full independent security +
code review was run against this codebase — see
`docs/security/2026-09-23-full-repo-final-review.md` for the complete
findings, remediation log, and what's still an open/accepted gap. This
section is the living summary; that report is the point-in-time record.

- **Access control**: single HR-admin role, JWT bearer auth, deny-by-default
  on every controller (see above). No RBAC — there is exactly one persona
  in scope (`docs/REQUIREMENTS.md`). Do not treat this auth scheme as a
  template for a multi-tenant or multi-role system; it isn't one.
  `/api/v1/login` is rate-limited (rack-attack, 5 attempts / 20s by IP and
  by email — `config/initializers/rack_attack.rb`), and `AdminUser`
  requires a 12-character-minimum password — both closed after the
  security review found the single admin account was an unthrottled,
  unconstrained brute-force target.
  **Accepted gap**: JWTs cannot be revoked before their 24h expiry — the
  only "logout" is the frontend clearing `localStorage`; there's no
  server-side denylist. Low impact for a single trusted operator; revisit
  with a `jti` + revocation list if this is ever deployed for more than
  that.
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
  built from user input anywhere in the codebase. Compensation records are
  validated against both the employee's hire date and the employee's full
  compensation history (not just the current record), backed by a Postgres
  exclusion constraint as the DB-level guarantee — see
  `CompensationRecord#effective_date_not_before_hire_date` and the
  `compensation_records_no_overlapping_date_ranges` constraint.
- **Network exposure**: only nginx's port is published to the host
  (`docker-compose.yml`); the Rails backend is reachable solely over the
  internal compose network, by service name. The browser only ever talks
  to nginx on one origin — this is now actually enforced, not just
  documented.
- **Transport**: `config.force_ssl` is off by default
  (`config/environments/production.rb`) because the docker-compose
  deployment serves plain HTTP with no TLS-terminating proxy in front of
  it. Set `FORCE_SSL=true` if this is ever deployed behind real TLS
  termination.
- **Browser-side hardening**: nginx sends `X-Content-Type-Options`,
  `X-Frame-Options: DENY`, `Referrer-Policy`, and a same-origin
  `Content-Security-Policy` on the SPA (not on `/api/`, which Rails
  already headers itself — see `frontend/nginx.conf`). Defense-in-depth:
  React's default escaping means there's no XSS sink in this app today,
  but these headers blunt what a future one could do.
- **Data at rest**: no field-level encryption on salary amounts. Standard
  controls apply (auth required, parameterized queries, no PII in logs —
  `filter_parameter_logging.rb`), but this is a gap to close before this
  pattern is used with real employee data. Flagged as unverified/ASSUMPTION
  territory rather than treated as already handled — see
  `docs/REQUIREMENTS.md`'s "deliberately out of scope" section.
- **Dependencies**: `bundle-audit` (ruby-advisory-db) and `npm audit` both
  report zero known vulnerabilities as of 2026-09-23. Brakeman flags one
  item: Rails 7.2.3.2's support window ended 2026-08-09 — an upgrade is
  tracked as a follow-up, not fixed inline (a framework upgrade warrants
  its own review).
- **Seed data**: every employee record is Faker-generated. No real
  employee or customer PII exists anywhere in this repository, database,
  or seed script.
