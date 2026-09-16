# test-team

A Claude Code plugin that gives you a specialist testing team:

1. **unit-test-engineer** — writes isolated unit tests for functions/modules/components
2. **integration-test-engineer** — writes tests across real seams (services, database, modules composed together)
3. **e2e-test-engineer** — writes full-flow tests against the real running app
4. **test-plan-runner** — executes a manual/scripted test plan and records pass/fail per scenario
5. **bug-reporter** — turns every real failure surfaced above into a structured bug report file

Test engineers run in parallel where more than one level applies; `bug-reporter` runs last, batching every real finding into one pass so it can deduplicate.

## Test plan template

[`templates/test-plan.md`](templates/test-plan.md) is the standard shape for a manual/scripted test plan — target, preconditions, numbered scenarios (steps, expected result, priority), and out-of-scope notes. Copy it, fill it in, and hand it to `/test-team` to get consistent, structured runs out of `test-plan-runner`. If you don't provide one, `test-plan-runner` derives a plan in this same shape from a feature's acceptance criteria instead.

## Handoff to dev-team

Bug reports are written to `.claude/test-team-findings/<slug>.md` in the target project — see [`agents/bug-reporter.md`](agents/bug-reporter.md) for the exact format. This is the same format the [dev-team](../dev-team-plugin) plugin's `project-manager` agent can be pointed at to plan fixes from. The two plugins don't call each other automatically — run `/test-team` to find and file bugs, then `/dev-team` to fix them.

## Install

```
/plugin marketplace add samwilcock/samwilcock-skills
/plugin install test-team@samwilcock-skills
```

## Use

In any project:

```
/test-team Cover the checkout flow with tests and find any bugs
```

The skill scopes the run (which test levels apply), dispatches the relevant specialists, and reports back a summary plus any filed bug reports.

## Updating

```
/plugin marketplace update samwilcock-skills
/plugin update test-team
```
