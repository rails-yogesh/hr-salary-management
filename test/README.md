CLASSIFICATION: INTERNAL

# Manual test screenshots

Screenshots from a manual, browser-driven verification pass against the
full `docker-compose up` stack (Chrome via Playwright, not part of the
app's own test suite — see `backend/spec/` and `frontend/src/**/*.test.tsx`
for the automated tests that run in CI/locally).

Login used: `hr@acme.test` / `changeme123!` against the seeded 10,000-employee
dataset.

| Screenshot | What it shows |
|---|---|
| `01-login.png` | Login page |
| `02-dashboard.png` | Dashboard: headcount/cost tiles, cost-by-country and cost-by-department charts |
| `03-employee-list.png` | Employee list: search, filters, status badges, formatted per-currency salaries |
| `04-employee-search-nomatch.png` | Search with no matches — empty state |
| `04-employee-search.png` | Search narrowing the result set |
| `05-employee-detail.png` | Employee detail: profile, current compensation, compensation history |
| `06-record-raise.png` | After recording a raise: prior record closed, new current record, success banner |
| `07-terminated.png` | After terminating an employee: status badge updated, terminate button and raise form both hidden |
| `08-new-employee-form.png` | New-employee form, including country → currency autofill (Australia → AUD) |
| `09-new-employee-created.png` | Newly created employee's detail page after submission |

All 16 assertions checked during this pass (data present, counts
narrowing on filter/search, history row added on raise, status updated
on terminate, navigation on create) passed with zero browser console
errors.
