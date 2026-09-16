# samwilcock-skills

A Claude Code plugin marketplace with specialist agent teams:

- **[dev-team](dev-team-plugin)** — plans, tests, implements, and reviews features via TDD, orchestrated through `/dev-team`.
- **[test-team](test-team-plugin)** — writes unit/integration/e2e tests and runs test plans, filing structured bug reports via `/test-team`. Findings are written in a format `dev-team`'s project-manager can consume for a fix loop.

Each plugin is self-contained (its own agents, skills, and version); see its README for details.

## Install

```
/plugin marketplace add samwilcock/samwilcock-skills
/plugin install dev-team@samwilcock-skills
/plugin install test-team@samwilcock-skills
```

## Repo layout

```
.claude-plugin/marketplace.json   # lists every plugin in this repo
dev-team-plugin/                  # dev-team plugin (agents, skills, viz)
test-team-plugin/                 # test-team plugin (agents, skills)
scripts/                          # validation + version-bump checks, run across every plugin
.github/                          # CI: runs scripts/ checks on every PR
```

## Contributing

Any change under a plugin's `agents/`, `skills/`, `viz/`, or `.claude-plugin/` requires a version bump in that plugin's `.claude-plugin/plugin.json` (single-step semver — major/minor/patch), enforced by CI. Run `./scripts/validate-plugin.sh` locally before opening a PR.
