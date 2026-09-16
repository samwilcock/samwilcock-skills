---
name: test-team
description: Run a testing pass through a specialist testing team - unit/integration/e2e test engineers write tests for the target area, a test-plan runner executes any scripted/manual scenarios, and a bug reporter turns every real failure into a structured bug report file the dev-team plugin can consume. Use when the user asks to test, write tests for, run a test plan against, or find bugs in an area of the codebase with the "test team", or explicitly invokes /test-team.
---

# Test Team

Orchestrate a small set of specialist testing subagents (defined in this plugin's `agents/` directory) to cover a target area of the codebase or a feature, and surface real findings as structured bug reports. You are the orchestrator: call each agent via the Agent tool, pass along what it needs, and use its report to decide what happens next. Do not write tests or run test plans yourself — delegate it.

## Scoping the run

Before dispatching agents, work out from the user's request:
- **Target**: a feature, module, flow, or "the whole app" — whatever was named or is clearly implied by conversation context.
- **Which test levels apply**: unit, integration, e2e, or a specific test plan — default to unit + integration for a code-level target, add e2e when the target is a user-facing flow, and use only test-plan-runner when the user hands you an explicit plan to execute rather than asking for new tests.
- If genuinely ambiguous (e.g. "test the app" with no other context, in a large codebase), ask the user to scope it rather than guessing at the whole surface area.

## Pipeline

1. **Test engineers** (`unit-test-engineer`, `integration-test-engineer`, `e2e-test-engineer` as applicable) — dispatch in parallel when more than one level applies, since they typically touch disjoint files. Each writes tests, runs them, and reports pass/fail plus any gaps it noticed.
2. **test-plan-runner** — if a test plan was provided, or the request explicitly asks for a testing-plan pass distinct from writing new automated tests, run this either instead of or alongside the engineers (it doesn't conflict with them — it executes rather than writes).
3. **bug-reporter** — once all of the above have reported, collect every real failure (a test that fails against current code, a test-plan scenario that failed) across all of them and hand the full list to bug-reporter in one call so it can deduplicate before writing. Do not call bug-reporter separately per upstream agent — batch it.

## Core rules

- A failing test that was **written test-first** against unimplemented behavior (TDD-style, e.g. testing a feature the dev team hasn't built yet) is not a bug — don't report it. Only report failures against code that's supposed to already work.
- If an agent reports it couldn't verify something (couldn't boot the app, no test database, etc.), don't silently drop that — tell the user and note it as a limitation of the run, since it means coverage is incomplete.
- Keep the user briefly informed between stages (one line per stage transition), and give a final summary: what was tested, what passed, what bugs were filed (with paths under `.claude/test-team-findings/`) and their severities.

## Handoff to dev-team

Bug reports live at `.claude/test-team-findings/<slug>.md` in the target project (see `bug-reporter`'s format). This is the same repo a `/dev-team` run operates in — its `project-manager` agent can be pointed at that directory to pull in open findings as input to a fix plan. This skill does not invoke dev-team itself; it only produces findings in a format dev-team knows how to consume. If the user wants fixes made immediately after this run, tell them to run `/dev-team` (or invoke the dev-team plugin) and mention the findings directory — don't cross-invoke automatically.
