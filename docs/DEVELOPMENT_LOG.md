CLASSIFICATION: INTERNAL

# Development Log

A chronological record of how this project was built — every step taken,
in order, plus the actual prompts that drove the work. This complements
`docs/AI_ASSISTED_DEVELOPMENT.md` (which explains the *methodology*); this
document is the literal *log*.

The whole project was built with Claude Code in one continuous session.

---

## 1. Steps taken, in order

### Phase 0 — Scoping and planning

1. Received the full project brief (goal, persona, problem statement,
   requirements, technical constraints — see §2, Prompt 1).
2. Asked two clarifying questions before writing anything, since both
   materially changed scope and were genuinely the stakeholder's call:
   - How to satisfy "fully functional deployed software" with no cloud
     hosting credentials available → **answered: Docker Compose, local**.
   - Whether to include authentication → **answered: yes, simple
     single-admin login**.
3. Entered Claude Code's plan mode and wrote a full implementation plan
   before any code existed: architecture decisions (money-as-cents,
   append-only compensation history, JWT single-admin auth, seed-data
   design, frontend structure, testing strategy, Docker layout) and the
   exact commit-by-commit sequence. Plan approved before implementation
   began.

### Phase 1 — Backend (Rails API)

4. Wrote `docs/REQUIREMENTS.md` — goal, in-scope features, explicit
   non-goals with reasoning — and committed it first, before any code.
   (`b0cb905`)
5. Scaffolded the Rails 7.2 API app (Postgres, RSpec/FactoryBot/Faker/
   shoulda-matchers, rack-cors, kaminari, bcrypt/jwt), an `api/v1`
   namespace, and a health check endpoint. Hit and fixed a real bug here:
   Rails 7.2's JSON encoder is incompatible with `json` 3.x, breaking
   every `render json:` call — pinned `json ~> 2.9`. (`1416f07`)
6. Built the core domain models and migrations: `Country`, `Department`,
   `JobLevel`, `Employee`, `CompensationRecord`, `ExchangeRate`,
   `AdminUser`. Modeled compensation as an append-only history enforced
   by a partial unique DB index, with 67 model specs. (`f06f85f`)
7. Added JWT-based admin authentication (`POST /api/v1/login`), with
   every controller locked down by default via a shared `before_action`.
   (`61d19a6`)
8. Built the 10,000-employee seed data generator (`SeedData::*`
   services): weighted/pyramid-shaped org distribution, batched
   `insert_all` for performance (~5s for 10k employees + ~14.7k
   compensation records), idempotent, with specs covering the generator
   logic on small samples. (`290e118`)
9. Built the Employees API: paginated/searchable/filterable index, show,
   create (employee + initial compensation in one transaction),
   update, terminate, plus a lookups endpoint. Employee numbers made
   server-generated instead of client-supplied. (`718bb17`)
10. Built the compensation-history ("record a raise") API:
    `Employees::RecordCompensationChange` closes the prior record and
    opens a new one atomically, rejecting out-of-order effective dates.
    Added presence validations that were missing on two NOT NULL
    columns. (`c0422ed`)
11. Built the dashboard analytics API (`Dashboard::Analytics`): headcount
    and cost summary, breakdowns by country/department/job level, all as
    SQL aggregation rather than Ruby-side loops, with cent-level exact
    arithmetic assertions in the specs. (`ea9903c`)

### Phase 2 — Frontend (React + TypeScript)

12. Scaffolded the Vite + React + TypeScript app: typed API client
    (`api/client.ts`, unit-tested directly), typed endpoint functions,
    auth context, routing skeleton, placeholder pages. (`73ab603`)
13. Built the real login page and route guard. Found and fixed a genuine
    test-isolation bug while writing these tests: `@testing-library/react`'s
    automatic cleanup never registered because Vitest's `globals` option
    was off — DOM from one test was leaking into the next. (`a8e6d3c`)
14. Built the employee list page: debounced search, country/department/
    status filters, pagination, money/date formatting utilities (with a
    regression test for a classic timezone off-by-one bug in date
    parsing). (`e96a3e1`)
15. Built the employee detail page: profile, current compensation, full
    compensation history table, and a terminate-employee action.
    (`30d3914`)
16. Built the new-employee form and the record-a-raise form (embedded in
    the detail page), including a country → currency autofill
    convenience and inline server-validation-error display. (`2ba50c2`)
17. Built the HR dashboard page: headline metric tiles and two Recharts
    bar charts (cost/headcount by country and by department) plus a
    salary-distribution table. Stubbed `ResizeObserver` for jsdom.
    (`a3361ab`)
18. Ran an ad hoc end-to-end smoke test of the dev servers (Vite proxy →
    Rails, login → employees/dashboard against the real 10k-employee
    dataset) and fixed a cosmetic bug found in the process — the browser
    tab still showed the Vite scaffold's default title. (`3680949`)

### Phase 3 — Deployment

19. Dockerized both halves and wrote the root `docker-compose.yml`:
    multi-stage Rails image (entrypoint now also runs `db:seed`), nginx
    serving the built SPA and proxying `/api` to the backend, Postgres
    with a healthcheck gating startup order. Found and fixed a real bug
    only visible by actually running the stack: a leftover
    Rails-generated `database.yml` block was silently overriding the
    shared DB connection settings, causing
    `fe_sendauth: no password supplied`. Also turned off `force_ssl` by
    default (the compose stack serves plain HTTP with no TLS proxy in
    front of it). Verified end-to-end after the fix. (`ad50cb6`)

### Phase 4 — Documentation

20. Wrote `README.md` (quick start, local dev, test/lint commands),
    `docs/ARCHITECTURE.md` (system diagram, key design decisions, an
    explicit security-posture section), `docs/TRADE_OFFS.md` (deliberate
    trade-offs and performance considerations), and
    `docs/AI_ASSISTED_DEVELOPMENT.md` (the build methodology). Also ran a
    repo-wide `rubocop` pass for the first time and fixed the cosmetic
    offenses it found. (`faae534`)

### Phase 5 — Final verification

21. Ran the full backend (136 examples) and frontend (42 examples) test
    suites clean, plus `rubocop`/`oxlint`/`tsc`/`vite build`.
22. Ran `docker compose up --build` from a fully wiped volume and
    verified: 10,000 employees seeded, login working, dashboard/employee
    list/lookups responding correctly, and all three write paths (create
    employee, record a raise, terminate) working end-to-end through the
    live containers via `curl`.
23. Removed a stray empty `package-lock.json` accidentally created at the
    repo root by an earlier `npm` command run from the wrong directory.

### Phase 6 — Manual browser verification

24. Installed Playwright (system Chrome, since the bundled Chromium
    binary doesn't support this machine's macOS version) and wrote a
    driver script exercising the app through a real browser against the
    live `docker-compose` stack: login, dashboard, employee list
    (search/filter/pagination), employee detail, recording a raise,
    terminating an employee, and creating a new employee.
25. Found and fixed a flaw in the *test script itself* (not the app): the
    first pass measured "search narrows results" and "filter narrows
    results" against a table that's always capped at one page of rows,
    so it couldn't actually detect a difference — rewrote those checks to
    compare the pagination metadata's total count instead. Also made the
    raise/terminate flow filter to "Active" status first, so re-running
    the script against the same persistent dev database doesn't land on
    an employee a previous run already terminated (whose "record a
    raise" form is correctly hidden — that's the app behaving correctly,
    not a bug).
26. All 16 checks passed against the real UI with zero browser console
    errors. Moved the resulting screenshots into the repo under
    `test/screenshots/` with a `test/README.md` explaining each one, and
    committed them (`99822cf`), then cleaned up the temporary Playwright
    harness (never tracked by git).

### Phase 7 — This document

27. Wrote this development log at the user's request.

---

## 2. Prompts used

The verbatim user-authored prompts that drove this session, in order.
(Tool outputs, system reminders, and this assistant's own responses are
not reproduced here — only what the human actually typed or selected.)

### Prompt 1 — the original brief

> Hi, You are a senior software engineer.
> Expectations:
> - Demonstrate clarity in thought and structured problem solving
> - Show strong engineering fundamentals & product thinking
> - Make thoughtful architectural and design decisions
> - Write production-quality code and tests
> - maintain correctness and quality
>
> Goal:
> Build employee salary management software for an organization with 10,000 employees.
>
> User Persona:
> HR Manager of the org
>
> Problem Statement:
> Currently, ACME org's HR team manages salary data for 10,000 employees across multiple countries, with everything managed via excels, which is tedious. We want the HR manager to manage the salaries data via web-based software and be able to answer questions about how the org pays people.
>
> Requirements:
> Write a one-page requirements document before building the software, outlining the goal, scope & features, and what you are deliberately leaving out, and reasoning for it.
>
> Technical Constraints:
> You should build end-to-end, fully functional software, including backend & UI.
>
> 1. Backend:
> - Rails
>
> 2. UI:
> - ReactJS
>
> 3. Seeding:
> - Seed script with 10,000 employees.
>
> 4. Readiness:
> - Fully functional deployed software
>
> 5. Database:
> - Postgres
>
> Development Approach:
> build the solution while maintaining high standards of code quality and test coverage.
>
> Your solution should include:
> - A meaningful set of unit tests that cover the core functionality
> - Tests that are fast, deterministic, and easy to understand
> - Good code structure, readability, and maintainability
>
> - Your commit history should show the evolution of your solution through incremental commits. This helps us understand how you approached the problem and how your implementation developed over time.
>
> Artifacts:
>
> Along with your solution, please commit any artifacts that help us understand your thinking and approach. Examples might include:
>
> - Requirements document
> - Planning or design notes
> - Architecture diagrams
> - Prompts or instructions used with AI tools
> - Trade-off explanations
> - Performance considerations

### Clarifying questions asked back (before writing any code)

Two multiple-choice questions were asked via Claude Code's clarification
tool, since the answers changed scope materially and were the
stakeholder's call, not a default to assume:

- **Q: How should "fully functional deployed software" be satisfied,
  given no cloud hosting credentials were available?**
  **A: Docker Compose, local (Recommended).**
- **Q: Should the app include login/authentication for the HR manager?**
  **A: Simple single-role auth (Recommended).**

### Plan review

A full implementation plan (architecture, data model, API design,
frontend structure, testing strategy, commit sequence) was written and
presented via Claude Code's plan mode. It was approved as-is, with no
requested changes, before implementation began.

### Prompt 2 — mid-session status check

> what is the progress

(Asked while a background `docker compose build` step was in flight;
answered with a status summary rather than a guess, per the standing
instruction not to fabricate results from in-flight background work.)

### Prompt 3 — resume

> yes please continue

### Prompt 4 — manual testing request

> lets start the servers and do the manaul testing on this

### Prompt 5 — move screenshots into the repo

> lets do one thing move the screenshot of testing to the current repo folder under test folder and commit them

### Prompt 6 — this document

> Please also create a one document and list all the steps we have done while developing the application and also mention the prompt we have used
