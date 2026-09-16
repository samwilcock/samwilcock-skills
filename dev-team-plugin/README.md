# dev-team

A Claude Code plugin that gives you a specialist dev team, orchestrated via TDD:

1. **project-manager** (opus) — plans the feature from your request/chat; **you approve the plan before anything is built**. Can delegate quick lookups to `researcher` while planning.
2. **researcher** (haiku) — fast, cheap codebase lookups and external tool/method research; not a pipeline stage, called on demand
3. **designer** — (only if the plan calls for it) produces UI design via the `/design` skill
4. **test-engineer** — writes failing tests against the plan's acceptance criteria
5. **database-engineer** — (only if the plan calls for it) schema/migrations, run before the engineers below since they typically build against it
6. **frontend-engineer** / **backend-engineer** / **devops-engineer** — implement only the disciplines the tests require (run in parallel with each other when more than one is needed)
7. **tester** — independently verifies everything passes
8. **reviewer** — final code review

Any specialist that hits an issue implying the plan itself was wrong (not just a code bug) sends it back to the project manager, who revises the plan — you approve the revision before the pipeline continues.

## Live visualization (optional)

A published Artifact — **Pipeline Control Room** — renders the pipeline as a house being built: each stage is a room that rises from a blueprint footprint to full walls and a roof as it completes. It opens on a dashboard — a card per project currently running `/dev-team`, showing what it's building, its progress at a glance, and when it last updated — click a card to enter that project's live floorplan and stage ledger, with a rail at the top to jump straight to another project without going back.

To enable it:
1. Publish your own copy of the Pipeline Control Room artifact — the source lives at [`viz/pipeline-control-room.html`](viz/pipeline-control-room.html) in this repo — with the `db` capability (ask Claude to publish it for you).
2. Save its URL to `~/.claude/dev-team-viz.json`:
   ```json
   { "url": "https://claude.ai/code/artifact/<your-artifact-id>" }
   ```
3. Run `/dev-team` as normal — the skill writes stage status to that artifact's shared data as it goes. Open the artifact URL to watch live.

This is per-user (the artifact's live data is scoped to its owner's organization) and entirely optional — without the config file, `/dev-team` runs exactly as before.

## Pausing and resuming

Every run's progress is saved to `~/.claude/dev-team-runs/<project>.json` as it goes — not just when you ask. On a long run (a couple of loop-backs, say), Claude will offer to pause and suggest a `/compact` once your context is getting heavy; say yes, `/compact`, then run `/dev-team` again in the same project and it'll pick up exactly where it left off — no need to re-approve a plan you already approved or redo finished stages. You can also ask to pause at any point yourself.

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
