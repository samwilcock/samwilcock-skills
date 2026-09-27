# Changelog

All notable changes to the test-team plugin. Each version is published as a GitHub release tagged `test-team-v<version>`.

## [1.1.0] - 2026-09-27

### Changed
- Every agent now runs on Opus instead of Sonnet, using the `opus` alias so it follows the current Opus model. (#21)

## [1.0.1] - 2026-09-16

### Changed
- Updated references to dev-team's `test-engineer` and `tester` agents, which dev-team 2.0.0 removed. (#20)

## [1.0.0] - 2026-09-16

### Changed
- Version raised to 1.0.0 alongside dev-team 1.0.0. test-team itself did not change. (#19)

## [0.3.0] - 2026-09-16

### Added
- The unit, integration and e2e test engineers can split a broad target into batches.
- The integration and e2e test engineers are warned that they share a test database and ports when they run in parallel.

### Changed
- A real bug found in existing behavior is marked skip or pending, with a link to its bug report, instead of being left failing in the project's test run.

### Fixed
- `test-plan-runner` found its template through a relative path that never resolved inside a target project. It now uses `${CLAUDE_PLUGIN_ROOT}`.
- `bug-reporter` was missing the Edit tool it needs to update existing reports. It also now only ever sets a report's status to open.

(#18)

## [0.2.0] - 2026-09-16

### Added
- A standard test plan template: target, preconditions, and numbered scenarios with steps, expected result and priority. `test-plan-runner` follows it when it writes a plan itself. (#16)

## [0.1.0] - 2026-09-16

### Added
- The first release: unit, integration and e2e test engineers, a test-plan runner, and a bug reporter, run through `/test-team`. Bug reports are written in a format dev-team's `project-manager` reads when planning fixes. (#15)
