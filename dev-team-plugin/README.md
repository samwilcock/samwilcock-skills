# dev-team

A Claude Code plugin that builds features with TDD. You approve a plan before anything is built, and one independent reviewer verifies and reviews each phase.

## Two modes

**Light (default)** — the current session plans, writes a short context brief, and implements with TDD itself. Subagents are used only where they add something:
- **researcher** (Haiku) — cheap codebase lookups and external research
- **designer** — UI design via the `/design` skill, when the plan needs it
- **reviewer** — one independent pass per phase: runs the full suite, checks every criterion is tested, reviews the diff

**Full** — for well-specified work that needs two or more of database/frontend/backend/devops with changes that are mostly in separate files. It adds:
- **project-manager** (Sonnet; Opus if you ask) — plans the work and writes the context brief
- **database-engineer** — schema and migrations, run before the other engineers
- **frontend-engineer** / **backend-engineer** / **devops-engineer** — each writes its own failing tests, then the code, for one sub-feature at a time, running in parallel with each other

The mode is picked automatically and stated with the plan. Say "light" or "full" in your request to force one, or switch at the approval step.

Exploratory or tightly coupled work — reworking editor interactions, a tricky refactor, anything you'd figure out by iterating — is much cheaper in light mode. Every subagent starts cold and has to re-read the code it works on.

## How cost is kept down

- **Context brief** — `.claude/dev-team/context.md` maps the relevant files, conventions, the test command, and key contracts. Every agent reads it instead of re-exploring the codebase. Deviations and discoveries get appended as work goes on, so it doesn't go stale.
- **Fewer handoffs** — engineers write their own tests, and a single reviewer does both verification and review.
- **Batches are sub-features** — engineers run one coherent sub-feature per call, not arbitrary small chunks.
- **Phases for large requests** — each phase ships an increment and is a natural point to pause and `/compact`.

## Pausing and resuming

When a run stops before finishing — waiting on your approval, you ask to pause, or before a suggested `/compact` — it saves `.claude/dev-team/run.md` in the project. Run `/dev-team` again later and it offers to pick the run up where it stopped. The file is only written when the run stops, so if a session dies mid-step it resumes from the last stop. Finished runs clean up after themselves.

Add `.claude/dev-team/` to your project's `.gitignore`; these are local working files.

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
