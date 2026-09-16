---
name: dev-team
description: Run a feature request through a specialist dev team using TDD - project manager plans it (with researcher support, approved by the user before anything is built), a designer produces UI design when needed, a test engineer writes failing tests, a database engineer builds schema/migrations when needed, frontend/backend/devops engineers implement only the disciplines needed (in parallel where possible), a tester verifies, and a reviewer does final code review. Any issue found along the way loops back to the project manager for re-planning. Progress persists to disk so a run can be paused and resumed (e.g. around a /compact) without losing state. Use when the user asks to build/implement a feature with the "dev team", or explicitly invokes /dev-team.
---

# Dev Team

Orchestrate a fixed pipeline of specialist subagents (defined in this plugin's `agents/` directory) to take a feature request from discussion to reviewed, tested code using TDD. You are the orchestrator: call each agent via the Agent tool, pass along what it needs, and use its report to decide what happens next. Do not do the specialists' work yourself — delegate it, and keep the user informed with brief status updates between stages.

`researcher` is a fast, cheap lookup agent (not a pipeline stage) — `project-manager` can call it directly for quick codebase questions or external tool/method research while planning. You (the orchestrator) may also call it directly if you need a quick answer to route the pipeline correctly.

## Live visualization (optional)

If `~/.claude/dev-team-viz.json` exists and has a `url` field, it points to a published "Pipeline Control Room" Artifact — a live 3D dashboard that tracks every project currently running `/dev-team` at once, each in its own lane. If the file is missing, skip this entirely — visualization is optional and never blocks the pipeline.

**Timestamps must be real.** Every `startedAt`/`updatedAt` you write (viz doc and the local run-state file below) is the actual current UTC time — get it with `date -u +%Y-%m-%dT%H:%M:%SZ` (Bash) at the moment of the write, never a placeholder, a guess, or a value reused from an earlier stage. The viz artifact renders these in the viewer's own local timezone automatically — that only works if the stored value is genuinely correct UTC.

When a viz URL is configured:
1. Compute a project doc id from the current working directory: take its basename, lowercase it, replace any character outside `a-z0-9-` with `-`, and collapse repeats (e.g. `/Users/sam/Dev/checkout-flow` → `checkout-flow`). This keeps concurrent runs in different projects from colliding — each writes to `runs/<that id>`, never `runs/current`.
2. At the start of a run, use the Artifact tool (`action: "write_db"`, `db_op: "set"`, that `url`, `collection: "runs"`, `doc_id: "<project id>"`) to write the initial document: `projectName` (the same basename, unslugified), `feature`, a generated `runId`, `startedAt` (ISO), `updatedAt`, `current: "plan"`, and a `stages` object with every stage key (`plan`, `approval`, `design`, `tests`, `database`, `frontend`, `backend`, `devops`, `verify`, `review`, `researcher`) set to `{status: "pending"}`.
3. Immediately before invoking each specialist, `update` that document: set that stage's status to `"running"` and `current` to its key, `updatedAt` to now.
4. Immediately after a specialist reports back, `update` again: status to `"done"` (or `"blocked"` if it raised an issue per the Core rule, or `"skipped"` for `design`/`database`/`frontend`/`backend`/`devops` when the plan doesn't require that discipline), plus a one-sentence `summary` of what it reported, and `updatedAt`.
5. On a loop back to `project-manager`, reset the stages being redone to `"pending"` before re-running them.
6. Use `if_version` (from the last read/write of that document) on every update to avoid clobbering a concurrent write — this matters more now that multiple runs may write to the same artifact's database (different docs, but still worth pinning).

Keep this lightweight: one or two short tool calls per stage transition, never more, and never let a failed viz write block or slow down the actual pipeline — but don't swallow the failure silently either. The **first** time a viz write fails in a run, tell the user in one line ("live viz isn't syncing — continuing without it") and keep going; don't mention it again for the rest of that run, and don't retry. The local run-state file (see below) is unaffected either way — it's written directly, not through the viz path, so pipeline progress is never at risk even when viz is broken.

**Announcing the URL and keeping writes going are standalone rules, not tied to any one pipeline step:**
- The **first time** you're about to invoke a specialist in a given session — whether that's the normal flow (right after the plan is approved, step 2) or a resumed run jumping straight into a later stage (step 0) — say "Watch live: `<url>`" once, in that same turn, before or alongside your first status update. Don't gate this on which step got you there; check it independently every time a run is about to start doing work.
- The **per-stage `update` calls** (steps 3–4 above) apply on every stage transition, full stop, regardless of whether the pipeline reached that stage by normal step-by-step progression or by jumping in via resume. A resumed run picking up at `verify` still writes `verify`'s `"running"`/`"done"` updates exactly as a fresh run would — resuming changes where you start, not whether you keep writing.

## Run state, pausing, and resuming

A long run (several agents, possibly a loop-back or two) can grow your own context enough that a `/compact` becomes worth doing mid-pipeline. Since compaction summarizes the conversation, the pipeline's actual progress needs to live somewhere durable that isn't your context — so every run persists its state to a local file, independent of whether visualization is configured:

`~/.claude/dev-team-runs/<project-id>.json` (same slugging rule as the viz doc id — see above), written directly with the Write/Edit tools (this is local state, not the Artifact tool's db — that's only for the optional viz). Update it at exactly the same moments you'd update the viz doc (run start, before/after each stage, on loop-back), whether or not a viz URL is configured — including a fresh real `date -u` timestamp each time (see above). It holds: `feature`, the full current `plan` text, `approved` (bool), `stages` (status + summary per stage, same shape as the viz doc), `current`, `loopCount` (times sent back to `project-manager`), `createdAt`, `updatedAt`.

**`current` is always one of the fixed stage keys** — `plan`, `approval`, `design`, `tests`, `database`, `frontend`, `backend`, `devops`, `verify`, `review`, or `researcher`. Never invent a pseudo-stage name for a loop-back or a scoped fix (e.g. don't write `current: "backend-contract-patch"`) — resume matches `current` against this fixed list, and an unrecognized value breaks it silently. If a `project-manager` revision only requires redoing part of one stage, that's still just that stage: reset it to `"pending"` and put whatever extra detail the redo needs (what changed, why, what to fix) in that stage's own `note` field, not in `current` or a new top-level field.

**At the start of every `/dev-team` invocation:** check whether this file already exists for the current project. If it does and isn't finished, tell the user a paused run was found (feature + current stage) and ask whether to resume it or discard it and start fresh — don't silently pick one. Resuming means: load the plan (skip re-planning and re-approval if `approved` is already true), skip every stage already `"done"`/`"skipped"`, and continue from `current`.
- If the stage named by `current` has status `"running"`, the previous session was interrupted mid-call — no result was ever recorded, so treat it as **not started**: re-invoke that specialist from scratch (with that stage's `note`, if any) rather than assuming partial progress.
- If `current` doesn't match one of the fixed stage keys (an older or corrupted state file), don't restart the whole pipeline — fall back to the earliest stage, in pipeline order, whose status isn't `"done"`/`"skipped"`, and resume there.

**Pausing:** if the user asks to pause (or you're about to suggest a `/compact`, see below), finish or abandon the in-flight specialist call cleanly, make sure the state file is fully up to date, then tell them in one line that it's safe to `/compact` or end the session now, and that running `/dev-team` again in this project will pick up right where it left off. Don't keep going past that point in the same turn.

**Finishing:** once the run reaches a terminal state (`reviewer` reports, or the user explicitly abandons it), **archive** the state file rather than deleting it outright — move it to `~/.claude/dev-team-runs/.archive/<project-id>-<UTC timestamp from date -u>.json` (same content, just relocated). This keeps a stale "paused run found" prompt from showing up on the next invocation (the active file is gone from the main directory) while leaving a recovery trail if this call was ever wrong — a run marked finished when it wasn't, or an interrupted session where the file's true state is ambiguous. Never treat "the user seems to have moved on" or "this session is ending" alone as abandonment — abandonment is the user explicitly saying so, or `reviewer` actually reporting.
- Opportunistically prune the archive when it's convenient (e.g. while already touching this directory at the start of a run): delete archived files older than 7 days. Don't make a special trip to do this — it's just tidiness, not correctness.
- If the paused-run check (Pipeline step 0) finds nothing active for this project but an archived file exists, mention it in passing ("no active run, though there's an archived one from <date> if you want to look at it") rather than silently saying nothing.

**Flagging heavy context:** after the 2nd loop-back to `project-manager` in a single run (Core rule below), say so explicitly and suggest pausing: "This is the Nth time we've looped back — context is growing. Want to pause here and `/compact` before continuing?" Don't force it — just offer, using the pause flow above if they say yes.

## Core rule: issues always go back to the project manager

Any specialist (designer, test-engineer, database-engineer, frontend-engineer, backend-engineer, devops-engineer, tester, reviewer) can surface an issue that isn't a simple "fix this line" bug — a bad assumption in the plan, a missing/wrong acceptance criterion, an untestable requirement, a design that doesn't fit the implementation, a reviewer finding that implies a scope change. Whenever that happens:

1. Do not try to resolve it yourself or route it straight back to the engineer who hit it.
2. Send it to `project-manager` with: the original plan, which stage found the issue, and the issue itself.
3. `project-manager` returns a revised plan.
4. Present the revision to the user for approval (see gate below) before re-entering the pipeline at whatever stage the revised plan requires (may need to redo design, tests, or implementation — use judgment on how far back to rewind; don't redo stages the revision didn't affect).

Small, purely mechanical fixes an engineer can resolve within their own step (a typo, an off-by-one their own test caught) don't need this — only loop back when the issue implies the plan itself was wrong or incomplete.

## Pipeline

0. **Check for a paused run** (see Run state above) before doing anything else. If one exists for this project, ask the user whether to resume or discard it. Resuming jumps straight to the saved `current` stage; discarding archives the old state file (per Finishing, below) and proceeds to step 1 as normal — the user explicitly choosing to discard is exactly the "abandoned" case. If none is active but an archived one exists, mention it briefly.
   - Resuming counts as "about to start work" — see the standalone URL-announcement rule in Live visualization above. Don't assume the user still has last session's tab open.

1. **Plan — `project-manager`**
   Summarize the feature request and relevant conversation context (the agent has no memory of this chat) and pass it to the `project-manager` agent. It returns a plan: summary, scope, acceptance criteria, required disciplines (`design`/`database`/`frontend`/`backend`/`devops`, any combination), and open questions.
   - If it raises open questions, ask the user before continuing rather than guessing.

2. **User approval gate — required before any implementation**
   Present the full plan to the user (summary, scope, acceptance criteria, disciplines required) and ask them to accept it, request changes, or reject it. Do not proceed past this point without explicit approval.
   - If they request changes, send that feedback to `project-manager` as a revision (see Core rule above) and re-present the revised plan. Repeat until approved.
   - Only once approved does the plan's `design` flag get acted on and implementation begin.
   - Approval counts as "about to start work" — see the standalone URL-announcement rule in Live visualization above.

3. **Design — `designer`** *(only if the approved plan requires `design`)*
   Pass the approved plan to `designer`. It uses the `design` skill to produce the design artifact and reports back key screens/states/components and implementation notes for the frontend engineer.
   - If it reports an issue with the plan (e.g. the request doesn't actually resolve into a coherent design), send it back to `project-manager` per the Core rule, then re-run the approval gate on any revision before continuing.

4. **Write failing tests — `test-engineer`**
   Pass the plan (and the designer's notes, if any) to `test-engineer`. It writes tests against the acceptance criteria and confirms they fail for the right reason. It reports which disciplines each failing test implies — use this, not just the plan's stated disciplines, to decide which engineers to invoke next.

5. **Database — `database-engineer`** *(only if the approved plan requires `database`)*
   Pass the plan and the relevant failing tests to `database-engineer`. It designs and applies the schema/migration change and reports the field-name contract the backend needs. Run this **before** step 6 — `backend-engineer` typically builds against the schema it produces, so don't invoke them in parallel with each other.
   - If it reports an issue with the plan (ambiguous or contradictory data requirements), send it back to `project-manager` per the Core rule, then re-run the approval gate on any revision before continuing.

6. **Implement — `frontend-engineer` / `backend-engineer` / `devops-engineer`**
   Invoke only the engineer(s) the failing tests actually require. Their work is normally separable, so invoke however many of the three are required **in parallel**, in a single message (one Agent tool call per engineer, together) — each should get the plan (plus designer notes and the database contract, if any) and only the tests/criteria relevant to their discipline. If only one discipline is required, invoke only that one.
   - If `design` ran, `frontend-engineer` must get the design artifact's URL and the designer's full notes (key screens/states/components, interaction notes) verbatim — this is required build spec, not a summarizable status update. The "Reporting back" section's terseness rules apply to what you tell the *user*, never to what you hand an engineer.
   - If multiple engineers reported touching shared/overlapping code, check for conflicts (e.g. re-read the touched files) before moving on.

7. **Verify — `tester`**
   Pass the plan and a summary of what was implemented to `tester`. It independently runs the suite and reports a verdict.
   - Failures caused by the implementation (not the plan) go straight back to the relevant engineer(s) (step 5 or 6) for another pass, then re-run `tester`. Don't loop more than twice this way without surfacing the situation to the user.
   - Anything that suggests the plan itself was wrong or incomplete (untested/untestable acceptance criteria, a criterion that turned out to be unsatisfiable as written) goes to `project-manager` per the Core rule instead.

8. **Review — `reviewer`**
   Once `tester` gives a passing verdict, invoke `reviewer` on the final diff. Relay its findings to the user as-is — do not silently apply fixes on its behalf unless the user asks you to. If a finding implies the plan was wrong (not just a code-quality nit), route it to `project-manager` per the Core rule.

## Reporting back

Concise throughout — this pipeline runs several agents per feature, so verbosity compounds fast.

- Per stage: one line, past tense, no preamble. "Tests written, 4 cases, confirmed red." not "Great, now let's move on to the testing phase, where the test-engineer will...". Skip stages the user doesn't need narrated (e.g. don't announce "invoking test-engineer now" — just report its result).
- Never paste an agent's full report verbatim **to the user**. Extract the one or two facts that change what happens next (status, what changed, the number that matters) and drop the rest — the ledger/viz artifact (if configured) already carries the detail. This applies only to what you tell the user, not to what you hand the next agent — an engineer needing another agent's full output (e.g. `frontend-engineer` needing `designer`'s complete notes, per step 6 above) still gets it in full.
- The plan (step 2) is the one exception — present it in full since the user is approving it.
- At the end: 2-4 lines total — what was built, test result, reviewer verdict (or "clean"). If it stopped early, say why and what's needed, in one line.

## Reducing token usage

This pipeline's cost is dominated by (a) how much context each agent is handed and (b) how much it reads before acting. Keep both tight:

- **Hand agents only what they need.** Don't forward an entire prior agent's report to the next one — extract the relevant fields (e.g. pass `test-engineer`'s failing-test list to the right engineer, not its full reasoning). Never forward your own conversation history; agents don't need it and can't use it.
- **Prefer `researcher` over ad-hoc exploration.** Any agent facing "does X exist / where does Y live" should delegate to `researcher` (haiku, cheap) rather than Grep/Read-ing around itself. This is already in `project-manager`'s instructions — apply the same instinct yourself as orchestrator.
- **Don't re-plan on every loop.** When `project-manager` revises a plan after an issue, it should patch the existing plan, not regenerate it from scratch — pass it the prior plan, not the original request again.
- **Don't redo unaffected stages.** A loop-back only reruns the stages the revision actually touches (Core rule already says this — it's also the token-cheap choice).
- **Keep agent reports short by design.** Each agent's own instructions ask for a report, not a transcript — don't ask an agent to "explain your reasoning" or "walk through what you did" unless actually debugging a failure.
- **Cap retry loops.** The two-loop cap on `tester` failures (step 7) exists partly for cost: an unbounded fix-verify loop burns tokens without new information after a couple of tries — surface it to the user instead.
- **Skip the viz write on failure, don't retry it.** A failed visualization update is not worth spending a retry's tokens on — catch and drop it (already stated above).
