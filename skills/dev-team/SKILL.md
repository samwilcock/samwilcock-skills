---
name: dev-team
description: Run a feature request through a specialist dev team using TDD - project manager plans it (approved by the user before anything is built), a designer produces UI design when needed, a test engineer writes failing tests, frontend/backend engineers implement only the disciplines needed (in parallel when both apply), a tester verifies, and a reviewer does final code review. Any issue found along the way loops back to the project manager for re-planning. Use when the user asks to build/implement a feature with the "dev team", or explicitly invokes /dev-team.
---

# Dev Team

Orchestrate a fixed pipeline of specialist subagents (defined in this plugin's `agents/` directory) to take a feature request from discussion to reviewed, tested code using TDD. You are the orchestrator: call each agent via the Agent tool, pass along what it needs, and use its report to decide what happens next. Do not do the specialists' work yourself — delegate it, and keep the user informed with brief status updates between stages.

## Core rule: issues always go back to the project manager

Any specialist (designer, test-engineer, frontend-engineer, backend-engineer, tester, reviewer) can surface an issue that isn't a simple "fix this line" bug — a bad assumption in the plan, a missing/wrong acceptance criterion, an untestable requirement, a design that doesn't fit the implementation, a reviewer finding that implies a scope change. Whenever that happens:

1. Do not try to resolve it yourself or route it straight back to the engineer who hit it.
2. Send it to `project-manager` with: the original plan, which stage found the issue, and the issue itself.
3. `project-manager` returns a revised plan.
4. Present the revision to the user for approval (see gate below) before re-entering the pipeline at whatever stage the revised plan requires (may need to redo design, tests, or implementation — use judgment on how far back to rewind; don't redo stages the revision didn't affect).

Small, purely mechanical fixes an engineer can resolve within their own step (a typo, an off-by-one their own test caught) don't need this — only loop back when the issue implies the plan itself was wrong or incomplete.

## Pipeline

1. **Plan — `project-manager`**
   Summarize the feature request and relevant conversation context (the agent has no memory of this chat) and pass it to the `project-manager` agent. It returns a plan: summary, scope, acceptance criteria, required disciplines (`design`/`frontend`/`backend`, any combination), and open questions.
   - If it raises open questions, ask the user before continuing rather than guessing.

2. **User approval gate — required before any implementation**
   Present the full plan to the user (summary, scope, acceptance criteria, disciplines required) and ask them to accept it, request changes, or reject it. Do not proceed past this point without explicit approval.
   - If they request changes, send that feedback to `project-manager` as a revision (see Core rule above) and re-present the revised plan. Repeat until approved.
   - Only once approved does the plan's `design` flag get acted on and implementation begin.

3. **Design — `designer`** *(only if the approved plan requires `design`)*
   Pass the approved plan to `designer`. It uses the `design` skill to produce the design artifact and reports back key screens/states/components and implementation notes for the frontend engineer.
   - If it reports an issue with the plan (e.g. the request doesn't actually resolve into a coherent design), send it back to `project-manager` per the Core rule, then re-run the approval gate on any revision before continuing.

4. **Write failing tests — `test-engineer`**
   Pass the plan (and the designer's notes, if any) to `test-engineer`. It writes tests against the acceptance criteria and confirms they fail for the right reason. It reports which disciplines each failing test implies — use this, not just the plan's stated disciplines, to decide which engineers to invoke next.

5. **Implement — `frontend-engineer` / `backend-engineer`**
   Invoke only the engineer(s) the failing tests actually require. If both are required, invoke them **in parallel** in a single message (two Agent tool calls together) since their work is normally separable — each should get the plan (plus designer notes, if any) and only the tests/criteria relevant to their discipline. If only one discipline is required, invoke only that one.
   - If both engineers reported touching shared/overlapping code, check for conflicts (e.g. re-read the touched files) before moving on.

6. **Verify — `tester`**
   Pass the plan and a summary of what was implemented to `tester`. It independently runs the suite and reports a verdict.
   - Failures caused by the implementation (not the plan) go straight back to the relevant engineer(s) (step 5) for another pass, then re-run `tester`. Don't loop more than twice this way without surfacing the situation to the user.
   - Anything that suggests the plan itself was wrong or incomplete (untested/untestable acceptance criteria, a criterion that turned out to be unsatisfiable as written) goes to `project-manager` per the Core rule instead.

7. **Review — `reviewer`**
   Once `tester` gives a passing verdict, invoke `reviewer` on the final diff. Relay its findings to the user as-is — do not silently apply fixes on its behalf unless the user asks you to. If a finding implies the plan was wrong (not just a code-quality nit), route it to `project-manager` per the Core rule.

## Reporting back

After each stage, give the user a short (1-3 sentence) status update — not the full agent transcript. At the end, summarize: what was built, test results, and the reviewer's findings (or that it was clean). If the pipeline stopped early (pending approval, repeated failures), say why and what's needed to continue.
