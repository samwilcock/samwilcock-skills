# samwilcock-skills

A Claude Code plugin marketplace with specialist agent teams:

- **[dev-team](dev-team-plugin)** — plans, tests, implements, and reviews features via TDD through `/dev-team`, in the current session by default or with parallel specialist engineers for multi-discipline work.
- **[test-team](test-team-plugin)** — writes unit/integration/e2e tests and runs test plans, filing structured bug reports via `/test-team`. `dev-team` reads open findings when planning, so they can be fixed in a follow-up run.

Each plugin is self-contained (its own agents, skills, and version); see its README for details, and its `CHANGELOG.md` for what changed in each version.

## Install

```
/plugin marketplace add samwilcock/samwilcock-skills
/plugin install dev-team@samwilcock-skills
/plugin install test-team@samwilcock-skills
```

## Repo layout

```
.claude-plugin/marketplace.json   # lists every plugin in this repo
dev-team-plugin/                  # dev-team plugin (agents, skills)      
test-team-plugin/                 # test-team plugin (agents, skills)
scripts/                          # validation, version-bump and release scripts, run across every plugin
.github/                          # CI: runs scripts/ checks on every PR, publishes releases on merge
```

## Contributing

Any change under a plugin's `agents/`, `skills/`, `templates/`, or `.claude-plugin/` requires a version bump in that plugin's `.claude-plugin/plugin.json` (single-step semver — major/minor/patch), enforced by CI. Run `./scripts/validate-plugin.sh` locally before opening a PR.

Each version bump also needs a `## [<version>] - <date>` section in that plugin's `CHANGELOG.md`, which CI checks too. When the PR merges, the release workflow tags the version as `<plugin>-v<version>` (for example `dev-team-v2.1.0`) and publishes a GitHub release with that changelog section as its notes.
