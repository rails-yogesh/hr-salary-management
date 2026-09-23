CLASSIFICATION: INTERNAL

# How this was built

This project was built end-to-end with Claude Code, in a single guided
session with a human reviewer. Recording the process here since it's part
of what this exercise is evaluating.

## Workflow

1. **Requirements before code.** `docs/REQUIREMENTS.md` was written and
   committed first — goal, in-scope features, and explicit non-goals with
   reasoning — before any Rails or React code existed.
2. **A written plan before implementation**, using Claude Code's plan
   mode: architecture decisions (money-as-cents, append-only compensation
   history, the auth scheme, the seed-data design, the commit sequence)
   were made explicit and approved before writing code, rather than
   discovered ad hoc while implementing. Two clarifying questions were
   asked and answered up front, since they materially changed scope and
   were genuinely the stakeholder's call, not a default to assume:
   - "Deployed" = a working `docker-compose up` (no cloud hosting
     credentials were available), not a live cloud endpoint.
   - Include simple single-admin authentication rather than no login,
     since the app handles salary data.
3. **One commit per functional slice**, backend-first then
   frontend-first-to-last-page, each landing with its own tests passing
   before moving on — the commit history is the log of that sequence, not
   reorganized after the fact.
4. **Bugs found by actually running things, not just reading code**: e.g.
   the `db:seed` `Faker::Name.unique` exhaustion, the `render json`
   incompatibility between Rails 7.2 and `json` 3.x, a test-isolation bug
   in the Vitest setup (missing `afterEach(cleanup)`), and a leftover
   Rails-generated `database.yml` production block that silently broke
   the Docker Compose deployment (`fe_sendauth: no password supplied`) —
   were all caught by running the test suite or the actual container, and
   are called out in their commit messages rather than silently folded in.

## What a reviewer should look at to judge the process, not just the result

- The commit history itself (`git log --oneline`), in order.
- Commit messages explain *why*, not just *what* — several document a bug
  that was hit and fixed, not just the feature that was intended.
- `docs/REQUIREMENTS.md` and `docs/TRADE_OFFS.md` were written as the
  scoping/reasoning artifacts requested for this exercise, not
  retrofitted summaries.
