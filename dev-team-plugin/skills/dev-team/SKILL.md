---
name: dev-team
description: Build a feature with TDD, either in this session (light mode, the default) or through a pipeline of specialist subagents (full mode, for well-specified work spanning several separable disciplines). Plans are approved by the user before anything is built, a shared context brief stops agents re-exploring the codebase, one reviewer verifies and reviews each phase, and a run file lets a paused run be picked up in a later session. Use when the user asks to build/implement a feature with the "dev team", or explicitly invokes /dev-team.
---

# Dev Team

You run a feature request from discussion to tested, reviewed code using TDD. Most of the cost of multi-agent work is agents starting cold and re-reading the same code, so this skill only uses subagents where they genuinely pay for themselves.

## Working files

Both live in the run directory, outside the project, under the user's global Claude config: `~/.claude/dev-team/<project key>/`. The key is the project root's absolute path with every character outside `A-Za-z0-9` replaced by `-`, so each project (and each git worktree) gets its own. Work out the absolute path once, at step 0, and use it from then on:

```
root=$(git rev-parse --show-toplevel 2>/dev/null || pwd); echo "$HOME/.claude/dev-team/$(printf %s "$root" | sed 's/[^A-Za-z0-9]/-/g')"
```

Nothing is written inside the project, so the files never show up in `git status` and the project's `.gitignore` doesn't need to cover them. Always pass agents the brief's absolute path, never `~`.

Test-team bug reports use the same key under a different root, `~/.claude/test-team-findings/<project key>/`:

```
root=$(git rev-parse --show-toplevel 2>/dev/null || pwd); echo "$HOME/.claude/test-team-findings/$(printf %s "$root" | sed 's/[^A-Za-z0-9]/-/g')"
```

If `<project root>/.claude/test-team-findings/` exists, it holds reports from earlier test-team versions: move each file into the findings directory (leave any whose name is already taken there, and mention it), delete the old directory if it's now empty, and tell the user in one line.

- **`context.md` — the context brief.** Written by whoever plans (you in light mode, `project-manager` in full mode), in the format described in `${CLAUDE_PLUGIN_ROOT}/agents/project-manager.md`. It's the shared map of the relevant code: files and their roles, conventions, the test command, key contracts, gotchas, and a "Decisions & deviations" section. Every agent reads it first and only explores beyond it for what it doesn't cover. After planning, **you are its only writer**: when a report mentions a deviation, an assumption, or something important the agent had to discover, append one line to it. That keeps later batches, the reviewer, the next phase, and a resumed session working from what's actually true.
- **`run.md` — the run file.** Holds what's needed to pick up a paused run (see Stopping and resuming). It's written only when the run stops, not after every step.

## Modes

**Light (default).** You plan, write the brief, and implement everything yourself with TDD in this session. Your understanding of the code accumulates in one context instead of being rebuilt by each agent. Subagents are used only where they add something you can't: `researcher` for cheap lookups or external research, `designer` when the plan needs a visual design, and `reviewer` once per phase for an independent verify and review.

**Full.** `project-manager` plans and writes the brief, and specialist engineers implement in parallel. Use it only when both are true:
- the work needs two or more of `database`/`frontend`/`backend`/`devops`, with changes that are mostly in different files, so parallel engineers genuinely save time, and
- the request is well specified, so the plan can be written up front rather than discovered by iterating.

Exploratory, tightly coupled, or single-discipline work (e.g. reworking editor interactions, a tricky refactor) stays in light mode.

Pick the mode at step 1 from the request plus a quick look at the repo layout — don't read implementation code just to decide. State the mode and a one-line reason when you present the plan. The user can force a mode by saying "light" or "full" in the request, or switch at the approval gate.

## Pipeline

0. **Work out the run and findings directories** (see Working files) and **check for a run to pick up** (see Stopping and resuming) before anything else.

1. **Scope.** Summarize the request, choose the mode, and record the phase's starting commit (`git rev-parse HEAD`, if `git rev-parse --is-inside-work-tree` succeeds). If the project isn't a git repo, note that the reviewer will have to review the working tree without a baseline.

2. **Plan and brief.**
   - *Light:* read `${CLAUDE_PLUGIN_ROOT}/agents/project-manager.md` for the plan and brief formats and the test-team findings check, explore the code you'll need to change, and write the plan and `context.md` yourself.
   - *Full:* invoke `project-manager` with the summarized request, anything you already learned while scoping, the brief's absolute path, and the findings directory's absolute path. It returns the plan and writes `context.md` there.
   - For a large request, the plan splits into phases (see Phases). Ask the user about any open questions before continuing.

3. **Approval gate.** Present the full plan: summary, scope, acceptance criteria, interface changes, disciplines, mode, and phases if any. Don't implement anything until the user approves it. On requested changes, revise (full mode: send the feedback and the prior plan to `project-manager`) and present it again.

4. **Design** *(only if the plan requires `design`)*. Invoke `designer` with the approved plan. Its artifact URL and full notes are build spec: in light mode read the artifact yourself, and in full mode pass both verbatim to `frontend-engineer`.

5. **Implement.**
   - *Light:* work through the acceptance criteria yourself, one at a time and in order. For each: write one test using the project's framework, run it and confirm it fails for the right reason, write the minimum code to pass it, and run it again. If a test passes straight away, the behavior already exists: confirm the test can fail by briefly breaking the code it covers, restore it, and keep the test as a guard. Don't write tests for later criteria ahead of their code, or code no test needs yet. When every criterion passes, refactor what you wrote without changing behavior and rerun the tests. Test through public interfaces (exported functions, endpoints, what a user sees), check results the same way rather than through the database or internal state, and mock only boundaries you don't control, like external services and time. Log deviations in the brief as you go.
   - *Full:* see Full-mode implementation below.

6. **Verify and review — `reviewer`.** Invoke it once the phase is implemented. Pass the plan's acceptance criteria, the starting commit (or "no baseline"), and the brief's path. It runs the full suite, checks every criterion has a real test, reviews the diff, and returns one verdict:
   - `pass` → step 7.
   - `fix` → implementation problems. Fix them yourself (light) or send them to the named engineers (full), then run `reviewer` again. After two fix rounds without a `pass`, stop and show the user where it's stuck.
   - `plan` → the plan itself is wrong or incomplete (see Plan issues).
   - Relay its findings to the user briefly. Don't apply fixes for non-blocking suggestions unless the user asks.

7. **Close out the phase.**
   - For each test-team finding the plan said this phase closes, change that file's frontmatter `status: open` to `status: fixed`.
   - **More phases left:** go straight to planning the next phase (step 2) without asking whether to continue. Record its starting commit, and pass the earlier phases' one-line summaries plus the brief. If the reviewer flagged a correctness or risk problem it didn't block on, check with the user first, since later phases build on this one.
   - **Last phase:** the run is finished. Give the final summary and delete the run directory.

## Full-mode implementation

- **Database first.** If the plan requires `database`, run `database-engineer` before the other engineers, since they build against its schema. Add the field-name contract it reports to the brief's key contracts.
- **Batches are sub-features, not counts.** `project-manager`'s plan groups each discipline's criteria into coherent sub-features. Each sub-feature is one batch; most disciplines have one or two. Never split related changes (a type and its only usage) across batches.
- **Rounds.** Run batch 1 of every required discipline together, in parallel, in one message. When all have reported, append any deviations and discoveries to the brief, then run batch 2 of each, and so on. If two disciplines' batches clearly touch the same files, run those two sequentially within the round. If a report mentions editing shared code, re-read those files before the next round.
- **Each engineer call gets:** the brief's path, its batch's acceptance criteria, the design notes (frontend) or database contract (backend) if any, and nothing else. Don't paste other agents' reports; anything worth sharing belongs in the brief.
- **Keep going.** Work through every round without pausing to ask the user, unless a plan issue comes up.

## Plan issues

When anything suggests the plan itself is wrong — a bad assumption, an untestable or unsatisfiable criterion, a design that doesn't fit, or a change needed outside the approved scope — don't patch around it:
- *Light:* revise the plan yourself.
- *Full:* send the prior plan, the brief's path, which step found the issue, and the issue itself to `project-manager`. It patches the plan and updates the brief rather than starting over.

If the revision changes scope or acceptance criteria, it goes back through the approval gate. Then re-enter at the earliest step the revision affects, without redoing unaffected work. Purely mechanical problems (a typo, an off-by-one) are fixed in place and never loop back.

## Phases

For a request too large for one focused pass, the plan names ordered phases, each shipping an independently useful increment toward the overall goal. The user approves the phase breakdown once, alongside phase 1's plan. Each later phase gets its own short plan and approval, since its criteria are new, but move from one phase into planning the next without asking whether to continue. Phases are the natural points to offer a pause (see below).

## Stopping and resuming

**When to write `run.md`:** whenever the run stops before finishing:
- your turn ends waiting on the user (approval gate, open questions, the fix-round cap, a plan issue needing a decision)
- the user asks to pause
- you're about to suggest a `/compact`

Don't write it during uninterrupted work. That means a session that dies mid-turn resumes from the last stop, so write it before anything that could plausibly end the session.

**Format:**
```
---
schemaVersion: 3
mode: light | full
phase: <N> of <M>
step: scope | plan | approval | design | implement | review | close
startCommit: <sha or none>
updated: <real UTC from `date -u +%Y-%m-%dT%H:%M:%SZ`>
---
## Request
<the summarized feature request>
## Phases
- <name> — done | current | pending — <one-line summary for done phases>
## Current phase plan
Approved: yes | no
<full plan text>
## Progress
<what's done in this phase; in full mode, which batches are done and which remain, by sub-feature name>
## Next step
<exactly what to do first on resume>
```

**On `/dev-team` (step 0):**
- **Run from 2.x versions that stored it in the project:** if `<project root>/.claude/dev-team/` exists, move its `run.md` and `context.md` into the run directory (unless the run directory already has a `run.md`, in which case leave the old files and mention them), then delete `.claude/dev-team/` if it's now empty. Tell the user in one line that the run's files moved out of the project, and that any `.claude/dev-team/` entry in its `.gitignore` is no longer needed. Then carry on as below.
- **`run.md` exists:** tell the user what was found (request, phase N of M, step) and ask whether to resume it or discard it — never silently pick. Resume means read `run.md` and `context.md` and continue from "Next step" (an approved plan isn't re-approved). Discard means delete the run directory and start fresh.
- **Legacy run, from plugin versions before 2.0.0:** the file is `~/.claude/dev-team-runs/<slug>.json`, where the slug is the project directory's basename lowercased, with characters outside `a-z0-9-` replaced by `-` and repeats collapsed. Don't try to resume it — its pipeline no longer exists. Tell the user in one line that you're re-planning it for the current version. Take its `feature` and `plan` as the request and run steps 1–3 normally, framed as "same scope, re-planned", not as new scope. Then move the old file into `~/.claude/dev-team-runs/.archive/`. If both a legacy file and `run.md` exist, `run.md` wins; mention the legacy file.
- **Neither:** start at step 1.

**Offering a pause.** At a phase boundary, after a second plan revision in one run, or when your own context is clearly getting heavy (long light-mode implementation, many large reports), offer once: "Context is getting heavy — want to pause here and `/compact`? I'll save the run so `/dev-team` picks it up." Only offer at a boundary (between phases, steps, or rounds), never mid-step. If they say yes, write `run.md` and stop.

## Reporting to the user

- One line per step, past tense, no preamble: "Phase 1 implemented, 6 tests green." Don't narrate agent invocations.
- Never paste an agent's report. Pass on only the facts that change what happens next.
- Show the plan in full at the approval gate.
- Final summary: 2–4 lines covering what was built, the test result, and the reviewer verdict.

## Keeping cost down

- Agents read the brief instead of being handed context. If an agent reports it had to explore a lot, add what it learned to the brief so the next one doesn't repeat it.
- Use `researcher` (Haiku) for "does X exist / where is Y" questions instead of broad exploration.
- Don't ask agents to explain their reasoning. Their instructions already ask for short reports.
- Cap fix rounds at two, and loop back only for real plan issues.
