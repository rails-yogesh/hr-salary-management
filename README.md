CLASSIFICATION: INTERNAL

# ACME Salary Management

A web application replacing ACME HR's spreadsheet-based salary tracking:
manage employee compensation records and answer questions about how the
org pays people, across 10,000 seeded employees in 6 countries.

- **Problem / scope / what's deliberately left out**: [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md)
- **How it's built and why**: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Trade-offs and performance notes**: [docs/TRADE_OFFS.md](docs/TRADE_OFFS.md)
- **How this was built**: [docs/AI_ASSISTED_DEVELOPMENT.md](docs/AI_ASSISTED_DEVELOPMENT.md)
- **Full step-by-step log + prompts used**: [docs/DEVELOPMENT_LOG.md](docs/DEVELOPMENT_LOG.md)
- **Security + code review (findings + remediation log)**: [docs/security/2026-09-23-full-repo-final-review.md](docs/security/2026-09-23-full-repo-final-review.md)

## Quick start (Docker Compose)

Requires Docker Desktop (or another Docker Engine + Compose v2) running.

```bash
docker compose up --build
```

This builds and starts three containers — Postgres, the Rails API, and
the React frontend (served by nginx) — and seeds 10,000 employees on
first boot (idempotent; safe on every restart).

Once it's up:

- App: <http://localhost:8080>
- API (via nginx, same origin as the app): <http://localhost:8080/api/v1>
- Login: `hr@acme.test` / `changeme123!` (overridable — see `.env.example`)

(The backend container's port isn't published to the host — the browser
only ever talks to nginx on one origin, per `docs/ARCHITECTURE.md`. For
local debugging against the API directly, use
`docker compose exec backend curl http://localhost:3000/...` from inside
the container, or temporarily add a `ports:` mapping back.)

To stop: `docker compose down`. To wipe the seeded data and start over:
`docker compose down -v`.

## Local development (without Docker)

Requires Ruby 3.4.5, Node 20+, and a local PostgreSQL server.

### Backend

```bash
cd backend
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server -p 3000
```

Database connection defaults to a local Unix socket with no
username/password (matches a typical Homebrew/local Postgres install).
Override via `DATABASE_HOST` / `DATABASE_USERNAME` / `DATABASE_PASSWORD` /
`DATABASE_NAME` if your setup differs.

### Frontend

```bash
cd frontend
npm install
npm run dev
```

Opens on <http://localhost:5173> and proxies `/api` to `http://localhost:3000`
(configurable via `VITE_BACKEND_URL`; see `vite.config.ts`).

## Running tests

```bash
# Backend: RSpec (136 examples — models, services, request specs)
cd backend && bundle exec rspec

# Frontend: Vitest (42 examples — API client, hooks, components, pages)
cd frontend && npm test
```

Both suites are fast (a few seconds total) and fully mocked/isolated —
no network calls, no shared state between tests, no sleeps.

## Project structure

```
backend/    Rails 7.2 API (Postgres, RSpec)
frontend/   React 19 + TypeScript SPA (Vite, TanStack Query, Vitest)
docs/       Requirements, architecture, trade-offs, this project's process
docker-compose.yml   One-command deployment for all three services
```

## Linting

```bash
cd backend && bundle exec rubocop
cd frontend && npx oxlint src
```
