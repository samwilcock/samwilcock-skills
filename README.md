# dev-team

A Claude Code plugin that gives you a specialist dev team, orchestrated via TDD:

1. **project-manager** (opus) — plans the feature from your request/chat; **you approve the plan before anything is built**. Can delegate quick lookups to `researcher` while planning.
2. **researcher** (haiku) — fast, cheap codebase lookups and external tool/method research; not a pipeline stage, called on demand
3. **designer** — (only if the plan calls for it) produces UI design via the `/design` skill
3. **test-engineer** — writes failing tests against the plan's acceptance criteria
4. **frontend-engineer** / **backend-engineer** — implement only the disciplines the tests require (run in parallel when both are needed)
5. **tester** — independently verifies everything passes
6. **reviewer** — final code review

Any specialist that hits an issue implying the plan itself was wrong (not just a code bug) sends it back to the project manager, who revises the plan — you approve the revision before the pipeline continues.

## Live visualization (optional)

A published Artifact — **Pipeline Control Room** — renders the pipeline as a live 3D tracker: each stage lights up as it starts/finishes, with a status ledger alongside.

To enable it:
1. Publish your own copy of the Pipeline Control Room artifact (ask Claude to do this, or open an existing one via `/artifacts`) with the `db` capability.
2. Save its URL to `~/.claude/dev-team-viz.json`:
   ```json
   { "url": "https://claude.ai/code/artifact/<your-artifact-id>" }
   ```
3. Run `/dev-team` as normal — the skill writes stage status to that artifact's shared data as it goes. Open the artifact URL to watch live.

This is per-user (the artifact's live data is scoped to its owner's organization) and entirely optional — without the config file, `/dev-team` runs exactly as before.

## Install

```
/plugin marketplace add samwilcock/samwilcock-skills
/plugin install dev-team@dev-team
```

## Use

In any project:

```
/dev-team Add a "forgot password" flow to the login page
```

The skill will call each specialist agent in turn, asking you only when it hits a genuine open question.

## Updating

```
/plugin marketplace update dev-team
/plugin update dev-team
```
