## What changed and why

<!-- One or two sentences. Which plugin(s) does this touch (dev-team-plugin/test-team-plugin/both)? If this adds a new agent/skill, say what it specializes in and when it should be used. -->

## Checklist

- [ ] I bumped the version in the affected plugin's `.claude-plugin/plugin.json` (required if that plugin's `agents/`, `skills/`, `viz/`, `templates/`, or `.claude-plugin/` changed) — as a single semver step: **major** for a breaking change to an agent/skill's behavior or interface, **minor** for a new agent/skill/capability that's backwards compatible, **patch** for a fix or small tweak. A change touching both plugins bumps both.
- [ ] I ran `./scripts/validate-plugin.sh` locally and it passes
- [ ] I ran `BASE_REF=origin/main ./scripts/check-version-bump.sh` locally and it passes
- [ ] I tested this with a real `/dev-team` and/or `/test-team` run (not just read through it)
- [ ] If this touches the pipeline flow (`dev-team-plugin/skills/dev-team/SKILL.md` or `test-team-plugin/skills/test-team/SKILL.md`), I updated that plugin's `README.md` to match
- [ ] This does not remove or rename an existing agent/skill — if it does, say why below

## Notes for reviewers

<!-- Anything that isn't obvious from the diff: tradeoffs considered, what you deliberately left out, open questions. -->
