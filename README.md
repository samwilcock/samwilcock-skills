# dev-team

A Claude Code plugin that gives you a specialist dev team, orchestrated via TDD:

1. **project-manager** — plans the feature from your request/chat
2. **test-engineer** — writes failing tests against the plan's acceptance criteria
3. **frontend-engineer** / **backend-engineer** — implement only the disciplines the tests require (run in parallel when both are needed)
4. **tester** — independently verifies everything passes
5. **reviewer** — final code review

## Install

```
/plugin marketplace add samuelwilcock/dev-team
/plugin install dev-team
```

(Replace `samuelwilcock/dev-team` with wherever you publish this repo, e.g. `<github-org>/<repo>` or a full URL.)

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
