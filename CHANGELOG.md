# Changelog

All notable changes to the plugins in this marketplace, newest first. Each heading is one plugin version, published as a GitHub release tagged `<plugin>-v<version>` (for example `dev-team-v2.1.0`). A change that touches both plugins has a heading for each.

## [dev-team 2.1.0] - 2026-09-27

### Changed
- Every agent that ran on Sonnet now runs on Opus, using the `opus` alias so it follows the current Opus model. `researcher` stays on Haiku, and `project-manager` no longer needs an opt-in to plan on Opus. (#21)

## [test-team 1.1.0] - 2026-09-27

### Changed
- Every agent now runs on Opus instead of Sonnet, using the `opus` alias so it follows the current Opus model. (#21)

## [dev-team 2.0.0] - 2026-09-16

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

## [test-team 1.0.1] - 2026-09-16

### Changed
- Updated references to dev-team's `test-engineer` and `tester` agents, which dev-team 2.0.0 removed. (#20)

## [dev-team 1.0.0] - 2026-09-16

### Changed
- A paused run saved by an older version is re-planned instead of resumed as-is. Its saved request and plan go back to `project-manager`, you approve the new plan, and implementation restarts. Run-state files now record a schema version. (#19)

## [test-team 1.0.0] - 2026-09-16

### Changed
- Version raised to 1.0.0 alongside dev-team 1.0.0. test-team itself did not change. (#19)

## [dev-team 0.10.0] - 2026-09-16

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

## [test-team 0.3.0] - 2026-09-16

### Added
- The unit, integration and e2e test engineers can split a broad target into batches.
- The integration and e2e test engineers are warned that they share a test database and ports when they run in parallel.

### Changed
- A real bug found in existing behavior is marked skip or pending, with a link to its bug report, instead of being left failing in the project's test run.

### Fixed
- `test-plan-runner` found its template through a relative path that never resolved inside a target project. It now uses `${CLAUDE_PLUGIN_ROOT}`.
- `bug-reporter` was missing the Edit tool it needs to update existing reports. It also now only ever sets a report's status to open.

(#18)

## [dev-team 0.9.0] - 2026-09-16

### Added
- Large engineer workloads are split into batches of about 6–8 tests, with one engineer call per batch. `project-manager` flags requests that should be split into separate plan-and-build passes.
- An amendments log in the run state, so later phases are planned with the deviations from earlier ones.
- The offer to pause or compact also appears every 8 agent calls, not only after loop-backs.

### Fixed
- Phased runs dropped every phase after the first, because the run state was archived at the end of phase one. The run state now records the phases and the current phase.

(#17)

## [test-team 0.2.0] - 2026-09-16

### Added
- A standard test plan template: target, preconditions, and numbered scenarios with steps, expected result and priority. `test-plan-runner` follows it when it writes a plan itself. (#16)

## [dev-team 0.8.4] - 2026-09-16

### Changed
- dev-team moved into the samwilcock-skills plugin marketplace. Install it with `/plugin install dev-team@samwilcock-skills`. (#15)

Versions before 0.8.4 were released from the single-plugin repo layout. See the git history before #15.

## [test-team 0.1.0] - 2026-09-16

### Added
- The first release: unit, integration and e2e test engineers, a test-plan runner, and a bug reporter, run through `/test-team`. Bug reports are written in a format dev-team's `project-manager` reads when planning fixes. (#15)
