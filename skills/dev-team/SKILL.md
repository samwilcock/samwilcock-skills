---
name: dev-team
description: Run a feature request through a specialist dev team using TDD - project manager plans it, a test engineer writes failing tests, frontend/backend engineers implement only the disciplines needed (in parallel when both apply), a tester verifies, and a reviewer does final code review. Use when the user asks to build/implement a feature with the "dev team", or explicitly invokes /dev-team.
---

# Dev Team

Orchestrate a fixed pipeline of specialist subagents (defined in this plugin's `agents/` directory) to take a feature request from discussion to reviewed, tested code using TDD. You are the orchestrator: call each agent via the Agent tool, pass along what it needs, and use its report to decide what happens next. Do not do the specialists' work yourself — delegate it, and keep the user informed with brief status updates between stages.

## Pipeline

1. **Plan — `project-manager`**
   Summarize the feature request and relevant conversation context (the agent has no memory of this chat) and pass it to the `project-manager` agent. It returns a plan: summary, scope, acceptance criteria, required disciplines (frontend/backend/both), and open questions.
   - If it raises open questions that materially change scope, ask the user before continuing (AskUserQuestion or plain question) rather than guessing.
   - Otherwise proceed with its stated assumptions.

2. **Write failing tests — `test-engineer`**
   Pass the full plan to `test-engineer`. It writes tests against the acceptance criteria and confirms they fail for the right reason. It reports which disciplines each failing test implies — use this, not just the PM's guess, to decide which engineers to invoke next.

3. **Implement — `frontend-engineer` / `backend-engineer`**
   Invoke only the engineer(s) the failing tests actually require. If both are required, invoke them **in parallel** in a single message (two Agent tool calls together) since their work is normally separable — each should get the plan plus only the tests/criteria relevant to their discipline. If only one discipline is required, invoke only that one.
   - If both engineers reported touching shared/overlapping code, check for conflicts (e.g. re-read the touched files) before moving on.

4. **Verify — `tester`**
   Pass the plan and a summary of what was implemented to `tester`. It independently runs the suite and reports a verdict.
   - If it reports failures caused by the implementation, send the specific failures back to the relevant engineer(s) (step 3) for another pass, then re-run `tester`. Don't loop more than twice without surfacing the situation to the user.
   - If it reports untested acceptance criteria, loop back to `test-engineer` to add coverage, then re-run the affected engineer(s) and `tester`.

5. **Review — `reviewer`**
   Once `tester` gives a passing verdict, invoke `reviewer` on the final diff. Relay its findings to the user as-is — do not silently apply fixes on its behalf unless the user asks you to.

## Reporting back

After each stage, give the user a short (1-3 sentence) status update — not the full agent transcript. At the end, summarize: what was built, test results, and the reviewer's findings (or that it was clean). If the pipeline stopped early (open questions, repeated test failures), say why and what's needed to continue.
