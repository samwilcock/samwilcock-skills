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

## Install

```
/plugin marketplace add samwilcock/samwilcock-skills
/plugin install dev-team
```

## Use

In any project:

```
/dev-team Add a "forgot password" flow to the login page
```

The skill will call each specialist agent in turn, asking you only when it hits a genuine open question.

## Updating

```
/plugin marketplace update dev-team-marketplace
/plugin update dev-team
```
