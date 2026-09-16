<!--
Test plan template for the test-team plugin's test-plan-runner agent.

Copy this file, fill in the sections below, and hand it to /test-team
(paste it in, or point at the file). If you don't have a filled-in plan,
test-plan-runner will derive one from a feature's acceptance criteria
instead — this template just gives it (and you) a standard shape when
you already know what should be checked.
-->

# Test Plan: <feature/flow name>

**Target:** <URL, app, branch, or environment this plan runs against>
**Owner:** <who wrote this plan>
**Date:** <YYYY-MM-DD>

## Preconditions

<Anything that must be true before running this plan: seeded data, a
logged-in user, a feature flag, a specific environment. Leave blank if none.>

## Scenarios

Copy this block per scenario. Number them so results can reference them
(`Scenario 1`, `Scenario 2`, ...).

### Scenario 1: <short name>

- **Steps:**
  1. <concrete, numbered step — exact input, click, command, or request>
  2. ...
- **Expected result:** <what should happen, stated concretely enough to
  be judged pass/fail without interpretation>
- **Priority:** critical | high | medium | low

### Scenario 2: <short name>

- **Steps:**
  1. ...
- **Expected result:** ...
- **Priority:** ...

## Out of scope

<Anything explicitly not covered by this plan, so a "gap" isn't
mistaken for a miss later.>
