# samwilcock-skills

A Claude Code plugin marketplace with specialist agent teams:

- **[dev-team](dev-team-plugin)** — plans, tests, implements, and reviews features via TDD through `/dev-team`, in the current session by default or with parallel specialist engineers for multi-discipline work.
- **[test-team](test-team-plugin)** — writes unit/integration/e2e tests and runs test plans, filing structured bug reports via `/test-team`. `dev-team` reads open findings when planning, so they can be fixed in a follow-up run.

Each plugin is self-contained (its own agents, skills, and version); see its README for details. [CHANGELOG.md](CHANGELOG.md) lists what changed in each plugin version.

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
CHANGELOG.md                      # every plugin version, newest first; becomes the release notes
scripts/                          # validation, version-bump and release scripts, run across every plugin
.claude/skills/                   # skills for contributors to this repo (not installed with the plugins)
.github/                          # CI: runs scripts/ checks on every PR, publishes releases on merge
```

## Contributing

Any change under a plugin's `agents/`, `skills/`, `templates/`, or `.claude-plugin/` ships as a new version of that plugin, with a section in `CHANGELOG.md` describing it.

### With Claude Code

Once your change is ready, run `/ship-plugin-change` in your clone of this repo. It chooses the bump level, bumps the version, writes the changelog entry, runs the checks, and opens the PR, asking you before it commits. The skill lives in `.claude/skills/`, so it's available only when working in this repo, not to people who install the plugins.

### By hand

1. Bump the version and add an empty changelog section:

   ```
   ./scripts/bump-version.sh <plugin> <major|minor|patch>
   ```

   - **major:** a breaking change to an agent's or skill's behavior or interface, including removing or renaming one
   - **minor:** a new agent, skill or capability that's backwards compatible
   - **patch:** a fix or small tweak

   A change to both plugins bumps both.
2. Fill in the new section at the top of `CHANGELOG.md`. Keep only the Added / Changed / Fixed / Removed headings you use, write for people who install the plugin, and end with the PR number, e.g. `(#23)`.
3. Run the checks:

   ```
   ./scripts/validate-plugin.sh
   BASE_REF=origin/main ./scripts/check-version-bump.sh
   ```

4. Open a PR and fill in the template.

### What CI checks

On every PR, CI runs both scripts. It fails if a plugin changed without a single-step version bump, if a bumped version has no changelog section, or if a changelog section is badly formatted: a wrong heading, an empty heading, or no bullet points.

When the PR merges, the release workflow tags each new version as `<plugin>-v<version>` (for example `dev-team-v2.1.0`) and publishes a GitHub release with its changelog section as the notes.
