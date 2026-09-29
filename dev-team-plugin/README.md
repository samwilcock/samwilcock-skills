# dev-team

A Claude Code plugin that builds features with TDD. You approve a plan before anything is built, and one independent reviewer verifies and reviews each phase.

## Two modes

**Light (default)** — the current session plans, writes a short context brief, and implements with TDD itself. Subagents are used only where they add something:
- **researcher** (Haiku) — cheap codebase lookups and external research
- **designer** — UI design via the `/design` skill, when the plan needs it
- **reviewer** — one independent pass per phase: runs the phase's tests (the full suite once, on the last phase), checks every criterion is tested, reviews the diff

**Full** — for well-specified work that needs two or more of database/frontend/backend/devops with changes that are mostly in separate files. It adds:
- **project-manager** (Opus) — plans the work and writes the context brief
- **database-engineer** — schema and migrations, run before the other engineers
- **frontend-engineer** / **backend-engineer** / **devops-engineer** — each builds one sub-feature at a time with TDD, running in parallel with each other

The mode is picked automatically and stated with the plan. Say "light" or "full" in your request to force one, or switch at the approval step.

Exploratory or tightly coupled work — reworking editor interactions, a tricky refactor, anything you'd figure out by iterating — is much cheaper in light mode. Every subagent starts cold and has to re-read the code it works on.

## How TDD works here

Whoever implements, the session in light mode or an engineer in full mode, works through the acceptance criteria one at a time:

1. Write one test for the criterion and watch it fail.
2. Write the minimum code to make it pass.
3. Move to the next criterion.

Once every criterion passes, they refactor with the tests staying green. Writing all the tests first tends to produce tests of imagined behavior. Going one criterion at a time means each test is checked against real code as soon as it's written.

Tests check behavior through public interfaces: exported functions, API endpoints, what a user sees. They mock only what the project doesn't control, like external services and time. That way a refactor that doesn't change behavior doesn't break them. The reviewer flags tests that reach into internals.

## How cost is kept down

- **Context brief** — `context.md` maps the relevant files, conventions, the test command, and key contracts. Every agent reads it instead of re-exploring the codebase. Deviations and discoveries get appended as work goes on, so it doesn't go stale.
- **Fewer handoffs** — engineers write their own tests, and a single reviewer does both verification and review.
- **Batches are sub-features** — engineers run one coherent sub-feature per call, not arbitrary small chunks.
- **Phases for large requests** — each phase ships an increment and is a natural point to pause and `/compact`.

## Pausing and resuming

When a run stops before finishing — waiting on your approval, you ask to pause, or before a suggested `/compact` — it saves `run.md` alongside the context brief. Run `/dev-team` again later and it offers to pick the run up where it stopped. The file is only written when the run stops, so if a session dies mid-step it resumes from the last stop. Finished runs clean up after themselves.

Both files live outside your project, in `~/.claude/dev-team/<project key>/`, where the key is the project root's path with non-alphanumeric characters replaced by `-`. Nothing is written into the repo, so there's nothing to add to `.gitignore`. Runs paused by 2.x versions, which saved them in the project's `.claude/dev-team/`, are moved there automatically the next time you run `/dev-team`; you can then drop `.claude/dev-team/` from your `.gitignore`.

Paused runs from versions before 2.0.0 (saved under `~/.claude/dev-team-runs/`) can't be resumed as-is. `/dev-team` re-plans them from their saved request and plan, then archives the old file.

## Install

```
/plugin marketplace add samwilcock/samwilcock-skills
/plugin install dev-team@samwilcock-skills
```

## Use

In any project:

```
/dev-team Add a "forgot password" flow to the login page
```

## Updating

```
/plugin marketplace update samwilcock-skills
/plugin update dev-team
```

## Upgrading to 2.0.0

- `test-engineer` and `tester` are gone: engineers write their own tests, and `reviewer` verifies.
- The live pipeline visualization is removed. You can delete `~/.claude/dev-team-viz.json` and the published Pipeline Control Room artifact if you set them up.
- Run state moved from `~/.claude/dev-team-runs/<project>.json` to `.claude/dev-team/run.md` in each project.
