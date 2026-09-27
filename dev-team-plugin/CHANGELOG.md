# Changelog

All notable changes to the dev-team plugin. Each version is published as a GitHub release tagged `dev-team-v<version>`.

## [2.1.0] - 2026-09-27

### Changed
- Every agent that ran on Sonnet now runs on Opus, using the `opus` alias so it follows the current Opus model. `researcher` stays on Haiku, and `project-manager` no longer needs an opt-in to plan on Opus. (#21)

## [2.0.0] - 2026-09-16

This release cuts the cost of a run. A real run of 1.0.0 used a full 5-hour usage window in two hours, mostly because every specialist started cold and re-read the same code. (#20)

### Added
- Light mode, now the default. The current session plans and implements with TDD itself, and uses subagents only for lookups, design, and one reviewer pass per phase. Full mode is for well-specified work that spans two or more separable disciplines.
- A shared context brief, `.claude/dev-team/context.md`, written once during planning. Every agent reads it instead of re-exploring the codebase, and deviations are appended to it as work goes on.

### Changed
- Engineers write their own failing tests before the code.
- The reviewer also runs the full test suite and checks that every acceptance criterion is tested.
- `project-manager` runs on Sonnet by default and groups each discipline's work into sub-feature batches.
- A paused run is saved as `run.md` in the project, written only when a run stops. Runs saved by earlier versions are re-planned from their saved request and plan.
- The dev-team skill is about 60% shorter.

### Removed
- The `test-engineer` and `tester` agents. Their work moved to the engineers and the reviewer.
- The live pipeline visualization.
- The amendments log, replaced by the context brief.

## [1.0.0] - 2026-09-16

### Changed
- A paused run saved by an older version is re-planned instead of resumed as-is. Its saved request and plan go back to `project-manager`, you approve the new plan, and implementation restarts. Run-state files now record a schema version. (#19)

## [0.10.0] - 2026-09-16

### Added
- `project-manager` checks `.claude/test-team-findings/` for open reports that relate to the request and adds them to the plan's acceptance criteria. A finding is marked fixed once its phase passes review.
- Test-engineer work can be split into batches, like engineer work.
- Each phase records its starting commit, so the reviewer's diff covers only that phase.

### Changed
- Engineer batches run in rounds: in parallel within a round, one round after another. Batch progress is saved, so a resumed run doesn't restart a discipline.
- The offer to pause for heavy context only appears between rounds or stages.
- Engineers running in parallel flag likely file overlap, so those batches run one at a time.

### Fixed
- `designer` was missing the Write and Artifact tools the `/design` skill needs to publish.
- `update-plugin` assumed the old single-plugin repo layout. It now detects an install from before the restructure and says so.
- `database-engineer`, `reviewer`, `test-engineer` and `tester` described only frontend and backend work.

(#18)

## [0.9.0] - 2026-09-16

### Added
- Large engineer workloads are split into batches of about 6–8 tests, with one engineer call per batch. `project-manager` flags requests that should be split into separate plan-and-build passes.
- An amendments log in the run state, so later phases are planned with the deviations from earlier ones.
- The offer to pause or compact also appears every 8 agent calls, not only after loop-backs.

### Fixed
- Phased runs dropped every phase after the first, because the run state was archived at the end of phase one. The run state now records the phases and the current phase.

(#17)

## [0.8.4] - 2026-09-16

### Changed
- dev-team moved into the samwilcock-skills plugin marketplace. Install it with `/plugin install dev-team@samwilcock-skills`. (#15)

Versions before 0.8.4 were released from the single-plugin repo layout. See the git history before #15.
