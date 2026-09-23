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

### Phase 8 — Final security and code review

28. Launched a full security + code quality review of the entire
    repository (backend, frontend, Docker/deployment config, git history,
    secrets hygiene) via a dedicated reviewer agent, at the user's request
    for "one final security and code review." Result: 0 Critical, 1 High,
    5 Medium, 6 Low, 4 Info findings, saved to
    `docs/security/2026-09-23-full-repo-final-review.md`. Everything
    already documented in `docs/ARCHITECTURE.md`'s security posture
    section checked out as accurate; the two findings that mattered most
    weren't on that list.
29. Fixed the High finding (SEC-H1): compensation records could be
    backdated before an employee's hire date, or overlap an already-closed
    historical record, with nothing catching it anywhere. Added a model
    validation, changed the raise-recording service to check the full
    history (not just the current record), and added a Postgres exclusion
    constraint as a DB-level backstop — mirroring the existing pattern for
    the "one current record" invariant. Reproduced the exact exploit from
    the report as a regression test, confirmed it failed before the fix
    and passed after. (`1e927dd`)
30. Fixed SEC-M1 (no rate limiting on `/api/v1/login`): added rack-attack,
    throttling by IP and by email, verified against both form and JSON
    request bodies and a live `docker-compose` round trip. Also added a
    test-support hook to reset rack-attack's counters between specs, since
    they persist across the whole suite otherwise. (`7cad0b2`)
31. Fixed SEC-M2 (no minimum password length on the admin account): added
    a 12-character minimum validation; confirmed the seeded default
    password and factory default both already qualified. (`372acbd`)
32. Fixed SEC-M4 (backend port published directly to the host, bypassing
    nginx): removed the `ports:` mapping in `docker-compose.yml`. Verified
    via a full `docker compose down -v && up --build` that port 3000 now
    refuses host connections while the app remains fully functional
    through nginx on :8080 — including re-verifying login, rate limiting,
    and the SEC-H1 fix all still work end-to-end in the rebuilt
    containers. (`9a2c214`)
33. Fixed SEC-M5 (no security headers anywhere): added
    `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, and a
    same-origin CSP to nginx's SPA location specifically — not
    server-wide, since Rails already sends its own equivalent headers on
    API responses and duplicating them risked sending conflicting
    `X-Frame-Options` values on the same response. Verified with `curl -I`
    and a real headless-Chrome pass (login, dashboard, employee list) that
    the CSP doesn't break anything. (`ab800d9`)
34. Ran the two dependency scanners the review had flagged as unexecuted:
    `bin/brakeman` (one finding — Rails 7.2.3.2 is past its support
    window per Brakeman's own EOL database, logged as a separate
    follow-up rather than fixed inline) and `bundle-audit`/`npm audit`
    (both clean, zero known vulnerabilities across either stack).
35. Added a Remediation Log to the security report (appended, not
    rewriting the original findings) recording what was fixed, by which
    commit, and what's carried forward as an explicit accepted gap
    (SEC-M3, JWT revocation) versus backlog (the Low/Info items). Updated
    `docs/ARCHITECTURE.md`'s security posture section to match the new
    state. (`b90f797`)
36. Pushed all of the above to `origin/main`.

### Phase 9 — Keeping this log itself current

37. Updated this document (again) to add Phase 8 and the prompts that
    drove it, at the user's request — asked for *before* the Phase 8
    commits were pushed, but arrived after the first push of that batch
    had already gone out (see Prompt 10). Handled as a follow-up
    push rather than an unpick/redo, since the commits themselves were
    correct and complete; only this log was behind.

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

### Prompt 6 — this document (first version)

> Please also create a one document and list all the steps we have done while developing the application and also mention the prompt we have used

### Prompt 7 — request the final security and code review

> Lets do one finnal security and code review

### Prompt 8 — mid-review check-in

> m

(Sent while the review agent was still running in the background;
answered with a status update, not a guess at findings that hadn't come
back yet.)

### Prompt 9 — approve all fixes, tie commits to findings, push the doc

> yes go ahead and after the fix mentioned the commit msg along with the security finding in the doc we will also push the doc

Interpreted as: fix everything the review flagged as worth fixing
(the High finding plus all four cheap Medium fixes — confirmed as options
1 and 2 offered after the review completed), reference the specific
finding ID from the report in each fix's commit message, update the
report itself with what was fixed, and push it all.

### Prompt 10 — update this log before the push (arrived mid-push)

> before pusshing lets update the prompt doc to also include the prompt about securtiy and code review

This message arrived after the Phase 8 commits (`1e927dd` through
`b90f797`) had already been pushed to `origin/main` — this document was
the one piece of that batch not yet updated to reflect it. Addressed as
a same-day follow-up: this document updated to add Phase 8 and Prompts
7-10, then pushed as its own commit (see Phase 9 above) rather than
rewriting history to insert it earlier.
