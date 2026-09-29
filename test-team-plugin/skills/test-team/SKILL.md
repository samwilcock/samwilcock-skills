---
name: test-team
description: Test existing code and hunt for bugs with a specialist testing team - unit/integration/e2e test engineers write tests that try to break the target area, a test-plan runner executes any scripted/manual scenarios, and a bug reporter turns every real failure into a structured bug report file the dev-team plugin can consume. Use when the user asks to test, add tests to, run a test plan against, or find bugs in existing code with the "test team", or explicitly invokes /test-team. Not for building new features test-first; that's dev-team.
---

# Test Team

Orchestrate a small set of specialist testing subagents (defined in this plugin's `agents/` directory) to test an existing area of the codebase or a feature, hunt for bugs in it, and surface real findings as structured bug reports. This covers what dev-team doesn't: code it didn't build, bugs its builders didn't think of, flows that span several features, and test plans. You are the orchestrator: call each agent via the Agent tool, pass along what it needs, and use its report to decide what happens next. Do not write tests or run test plans yourself — delegate it.

## Findings directory

Bug reports live outside the project, under the user's global Claude config: `~/.claude/test-team-findings/<project key>/`. The key is the project root's absolute path with every character outside `A-Za-z0-9` replaced by `-` (the same key dev-team uses for its run directory), so each project, and each git worktree, gets its own. Work out the absolute path before dispatching anything:

```
root=$(git rev-parse --show-toplevel 2>/dev/null || pwd); echo "$HOME/.claude/test-team-findings/$(printf %s "$root" | sed 's/[^A-Za-z0-9]/-/g')"
```

Nothing is written inside the project for findings, so they never show up in `git status` and the project's `.gitignore` doesn't need to cover them. Pass `bug-reporter` the absolute path, never `~`.

If `<project root>/.claude/test-team-findings/` exists, it holds reports from earlier versions. Move each file into the findings directory, unless a file with the same name is already there, in which case leave it and mention it. Then delete the old directory if it's now empty. Tell the user in one line that findings moved out of the project, and that any `.claude/test-team-findings/` entry in its `.gitignore` is no longer needed.

## Scoping the run

Before dispatching agents, work out from the user's request:
- **Target**: a feature, module, flow, or "the whole app" — whatever was named or is clearly implied by conversation context.
- **Which test levels apply**: unit, integration, e2e, or a specific test plan — default to unit + integration for a code-level target, add e2e when the target is a user-facing flow, and use only test-plan-runner when the user hands you an explicit plan to execute rather than asking for new tests.
- If the request is to write tests for a feature that doesn't exist yet, don't start a run. Tell the user to use `/dev-team`, which builds features test-first, one criterion at a time.
- If genuinely ambiguous (e.g. "test the app" with no other context, in a large codebase), ask the user to scope it rather than guessing at the whole surface area.
- If the user hasn't provided a test plan but the run will include `test-plan-runner`, you can point them at this plugin's `${CLAUDE_PLUGIN_ROOT}/templates/test-plan.md` for the standard shape (target, preconditions, numbered scenarios with steps/expected result/priority) — worth mentioning once, not forcing; `test-plan-runner` derives one in that same shape if none is given.

## Pipeline

1. **Test engineers** (`unit-test-engineer`, `integration-test-engineer`, `e2e-test-engineer` as applicable) — dispatch in parallel when more than one level applies, since they typically touch disjoint files. Each writes tests, runs only those tests (never the full suite), and reports pass/fail plus any gaps it noticed.
   - **Batch a large target.** If the target area is broad enough that an engineer's workload would be open-ended (a whole feature or "the app" rather than a focused module/flow), split it into smaller batches — by sub-feature, module, or file area — and invoke that engineer once per batch, sequentially, checking its report before the next batch. This is the same call-bounding rule dev-team uses for its engineers: an unbounded single call can run for a long time and burn a lot of usage before ever reporting back.
   - **`integration-test-engineer` and `e2e-test-engineer` can collide if run together.** Both may exercise a real test database, a booted app instance, or a shared port. Before running them in parallel, check whether the project's tooling actually isolates test runs (separate ports/containers/DB namespaces per run) — if you can't tell, or you know it doesn't, run them sequentially instead of in parallel for this project rather than risking one run's state bleeding into the other's.
2. **test-plan-runner** — if a test plan was provided, or the request explicitly asks for a testing-plan pass distinct from writing new automated tests, run this either instead of or alongside the engineers (it doesn't conflict with them — it executes rather than writes).
3. **Full suite, once.** When every engineer has reported, run the project's full test suite yourself, once. It should be green apart from the bug tests marked skipped; if a new test breaks it or clashes with an existing one, send it back to the engineer that wrote it. Don't run it between agents or batches.
4. **bug-reporter** — once all of the above have reported, collect every real failure (a test that fails against current code, a test-plan scenario that failed) across all of them and hand the full list, plus the findings directory's absolute path, to bug-reporter in one call so it can deduplicate before writing. Do not call bug-reporter separately per upstream agent — batch it.

## Core rules

- The goal is finding bugs, not raising coverage. Engineers work out correct behavior from how the code is used (callers, UI, API, docs), not by mirroring the implementation, and test through public interfaces.
- Everything under test is supposed to already work, so a failing test is either a real bug or a mistake in the test. Have the engineer say which before anything is reported.
- A failing test that **is** a real bug against existing behavior should not be left red in the project's normal test run — that breaks the user's CI/local suite for something this skill's job is to report, not to break the build over. Have the engineer that wrote it mark the test skipped/pending with a comment referencing the bug report's slug (write the test and the skip together; `bug-reporter` runs after, so reference the slug you expect it to use), rather than leaving a failing assertion in place.
- If an agent reports it couldn't verify something (couldn't boot the app, no test database, etc.), don't silently drop that — tell the user and note it as a limitation of the run, since it means coverage is incomplete.
- Keep the user briefly informed between stages (one line per stage transition), and give a final summary: what was tested, what passed, what bugs were filed (with their paths in the findings directory) and their severities.

## Handoff to dev-team

Bug reports live at `<findings directory>/<slug>.md` (see `bug-reporter`'s format). A `/dev-team` run in the same project works out the same directory — its planning step checks it for open findings relevant to the request, folds them into the plan, and marks them fixed after review. This skill does not invoke dev-team itself; it only produces findings in a format dev-team knows how to consume. If the user wants fixes made immediately after this run, tell them to run `/dev-team` (or invoke the dev-team plugin) and mention the findings directory — don't cross-invoke automatically.
