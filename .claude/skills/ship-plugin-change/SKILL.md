---
name: ship-plugin-change
description: Ship a change to a plugin in this repo - choose the semver bump, bump the version, write the CHANGELOG.md entry, run the repo checks, and open the PR. Use when a change under a plugin's agents/, skills/, templates/ or .claude-plugin/ is ready to ship, when the user asks to bump a plugin version or update the changelog, or when they invoke /ship-plugin-change.
---

# Ship a plugin change

Every change to a plugin's `agents/`, `skills/`, `templates/` or `.claude-plugin/` ships as a new version of that plugin, with a section in the root `CHANGELOG.md`. That section becomes the version's GitHub release notes when the PR merges, so it is written for people who install the plugin, not for reviewers.

## Steps

1. **Find what changed.** Compare against `origin/main` (committed and uncommitted changes) and map each file to a plugin using `.claude-plugin/marketplace.json`.
   - Only files outside those four directories changed (a README, `CHANGELOG.md`, `scripts/`, `.github/`)? No bump is needed. Say so and skip to step 5.
   - A plugin's `plugin.json` version already differs from `origin/main`? It was already bumped on this branch. Don't bump it again; update its existing changelog section in step 4.

2. **Choose the bump level for each plugin.** Use the same rules as the PR template:
   - **major:** a breaking change to an agent's or skill's behavior or interface, including removing or renaming an agent or skill.
   - **minor:** a new agent, skill or capability that is backwards compatible, or a change to how existing ones behave that users will notice (such as the model they run on).
   - **patch:** a fix or small tweak.

   Tell the user the level and the reason in one line. Ask only if it's genuinely between major and minor.

3. **Bump.** Run `./scripts/bump-version.sh <plugin> <level>` for each plugin. It updates `plugin.json` and adds an empty section at the top of `CHANGELOG.md`.

4. **Write the entry.** Read the three or four newest sections in `CHANGELOG.md` first and match them.
   - Keep only the headings you use, and delete the rest:
     - `### Added` for new agents, skills or capabilities.
     - `### Changed` when existing behavior works differently.
     - `### Fixed` when something was broken.
     - `### Removed` when an agent, skill or behavior is gone. Say where its work moved.
   - One bullet per change a user would notice, in full sentences. Put agent, skill and file names in backticks. Describe the effect, not the implementation.
   - A major version opens with one short paragraph, above the headings, saying why the release breaks compatibility.
   - A change to both plugins gets a section for each, each describing what changed for that plugin.
   - Leave off the PR number for now; step 6 adds it.

5. **Check.** Run `./scripts/validate-plugin.sh` and `BASE_REF=origin/main ./scripts/check-version-bump.sh`. Fix anything they report.

6. **Ship.** Show the user the new changelog sections and ask before committing.
   - If you're on `main`, create a branch first.
   - Commit, push, and open the PR with `gh pr create`. Fill in `.github/pull_request_template.md` and tick only the items that are actually true.
   - Add the PR number to each new section. With one bullet, append ` (#<number>)` to it. With several, add a last line `(#<number>)` to the section. Commit and push that as well.
   - Give the user the PR link.
