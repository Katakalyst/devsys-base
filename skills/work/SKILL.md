---
name: work
---
# /work

The core autonomous development loop. Pick up the next open issue, implement it, ship it, and repeat until there is nothing left or a blocker requires the user.

The user starts this skill. After that, proceed autonomously; pause only when a stop condition is met.

**Platform note:** the commands below use `glab` (GitLab). If the repo you're working in is hosted on GitHub instead (run `devsys-platform` if unsure), use the equivalent `gh` command at each step — see `_github`'s skill for the exact mapping (`gh issue`/`gh pr` cover what `glab issue`/`glab mr` do here). Either way, prefix the command with its token — see `_gitlab`'s or `_github`'s skill for why.

---

## Session start

At the start of every session, greet the user briefly: tell them what project you are on and what you are about to do. One or two sentences. Then begin orientation.

---

## Phase 1 — Orient

Before touching any code, build a complete picture of the project. Do this at the start of every session, even if you have worked on this project before — the state may have changed.

**1. Read CLAUDE.md if it exists**
If `CLAUDE.md` exists at the project root, read it for project-specific context. If it does not exist, proceed — context will be established from specs, issues, and the codebase.

**2. Read all specs and decisions**
List and read every file in `docs/specs/`. Understand what is specified, what each spec covers, and how specs relate to each other. Then read every file in `docs/decisions/`. These record why past choices were made — do not re-litigate them unless a spec has changed.

**3. Understand the codebase**
Walk the directory structure. Read key files — entry points, core modules, test files. You need to know where things are before you can change them. Do not skip this step on the assumption you remember from a previous session.

**4. Check recent history**
```
git log --oneline -20
```
Understand what has been done recently. If there are open branches, note them.

**5. Review the full issue backlog**
```
GITLAB_TOKEN=$(devsys-token) glab issue list --state opened
```
Read every open issue. Note which are blocked, which reference a spec, which are already assigned.

**6. Check for open MRs**
```
GITLAB_TOKEN=$(devsys-token) glab mr list --state opened
```
If an MR is open from a previous session: review it (same checklist as Step 9 below) and merge it before starting new work.

After completing all steps, run `/_plan`. It will review the backlog, fix any issues with it, and produce the order in which to work. Only after `/_plan` completes should you begin the loop.

---

## State tracking

The agent tracks its position in the loop using a `work-state/` folder in the project repo, committed to git so it survives session ends and machine switches.

- Before each step: read `work-state/current.md` to confirm where you are
- After each step: update `current.md` to the next step and commit it alongside any code changes; commit the state file alone if there are no code changes
- When the issue is fully done (after `/_release` completes): delete the entire `work-state/` folder and commit the deletion
- On session start: if `work-state/current.md` exists, read it before orientation and skip straight to the right step

---

## Phase 2 — The loop

Confirm you are on `main` and it is up to date: `git pull origin main`.

Repeat the following until a stop condition is met.

### Step 0 — Re-read this skill

Read `${CLAUDE_SKILL_DIR}/SKILL.md` in full before each iteration.

### Step 1 — Pick the next issue

Fetch open issues:
```
GITLAB_TOKEN=$(devsys-token) glab issue list --state opened --assignee none
```

Pick the first unassigned issue following the order `/_plan` produced. If all open issues are already assigned to you from a previous session, pick the oldest one.

If there are no open issues: stop. Tell the user all issues are done and list what was completed this session.

Assign the issue to yourself and add the label `in-progress`:
```
GITLAB_TOKEN=$(devsys-token) glab issue update <iid> --assignee @me --label "in-progress"
```

Tell the user: "Working on #N — <title>"

Create `work-state/` if it does not exist. Write `work-state/current.md` with step `understand`. Commit: `state: start #N`.

### Step 2 — Understand the issue

Read the issue title, description, and all comments. If the issue references a spec in `docs/specs/`, read it. If the area touched by this issue has relevant decision records in `docs/decisions/`, read those too — they explain constraints and choices that must not be silently undone.

If the issue is too vague to implement without guessing at requirements: comment on the issue with your specific questions, then stop and tell the user which issue is blocked and what you need. Do not guess.

Only ask about product gaps — what should happen in a given situation, who is affected, what success looks like. Never ask the user a technical question. Technical uncertainty is yours to resolve through research and judgment.

Write the understanding notes into `work-state/current.md` (what the issue requires, what approach you will take). Update step to `implement`. Commit.

### Step 3 — Create a branch

Branch name from the issue: `<type>/<issue-iid>-<short-description>`

```
git checkout main && git pull origin main
git checkout -b <branch>
```

### Step 4 — Implement

Write the code. Follow the conventions in `CLAUDE.md`.

- Make small, focused commits as you work
- Each commit message follows Conventional Commits
- If you discover the issue is larger than expected, implement the core requirement and create follow-up issues for the rest — do not expand scope silently

**When uncertain about a technical approach, library, API, or platform behaviour — look it up before writing code.** Do not rely on your training data alone; it has a cutoff and may be wrong about versions, edge cases, and recent changes. Prefer primary sources: official documentation, changelogs, source code.

**When implementation reveals a spec gap** — an unspecified edge case, ambiguous boundary behaviour, an error state the spec does not address — do not fill it silently. Make your assumption explicit in a code comment and create a GitLab issue: "Spec gap: [describe the unspecified behaviour and what was assumed]." This makes the choice visible and correctable.

**When implementation reveals a spec is wrong** — not just incomplete, but actively incorrect — do not implement to the wrong spec. If it is a clarification, update the spec and continue. If it is a product-level contradiction, stop and tell the user before writing any code.

**When making a significant technical decision** — choosing between architectures, selecting a library where alternatives exist, committing to a data model — write a brief decision record in `docs/decisions/`. What was decided, why, what was rejected. Small obvious choices do not need records. Decisions that would be hard to understand or costly to reverse later do.

Update `work-state/current.md` step to `test`. (This update can ride in any implementation commit.)

### Step 5 — Test

Run the project's test suite. Fix any failures before continuing.

If tests do not exist yet for the changed code, write them. See the `/_testing` skill for guidance.

Update `work-state/current.md` step to `scan`. Commit alongside the test commit.

### Step 6 — Scan

Run `/_scan`. Fix any CRITICAL findings before continuing. Note HIGH findings in the MR description.

### Step 7 — Open an MR

Push the branch and create the MR:
```
GITLAB_TOKEN=$(devsys-token) glab mr create \
  --source-branch <branch> \
  --target-branch main \
  --title "<conventional commit title>" \
  --description "Closes #<iid>

## What this does
<brief description>

## How to test
<steps to verify the change works>" \
  --remove-source-branch
```

Update `work-state/current.md` step to `mr-open`. Commit and push.

### Step 8 — Review and merge

Read the full diff. Review it as if you were a second developer who did not write this code.

**Correctness**
- Does the implementation actually do what the issue requires?
- Are there edge cases that are not handled?
- Is there any logic that is wrong or will produce incorrect results?

**Code quality**
- Is the code readable? Would someone unfamiliar with this area understand it?
- Is anything unnecessarily complex? Can it be simplified?
- Is there dead code, commented-out code, or leftover debug output?

**Tests**
- Do the tests cover the core behaviour?
- Do the tests cover failure cases and edge cases?
- Would a test catch a regression if this code were broken later?

**Security**
- Does the code introduce any obvious security issues — unsanitised input, exposed credentials, unsafe operations?

**Consistency**
- Does the code follow the conventions in `CLAUDE.md` and the rest of the codebase?
- Are naming, structure, and patterns consistent with what already exists?

If any issue is found: fix it on the branch, push, then re-read the diff before merging. Do not merge code you would not approve from someone else.

If satisfied, merge:
```
GITLAB_TOKEN=$(devsys-token) glab mr merge <mr_iid>
```

Tell the user: "Done: #N — <title>"

### Step 10 — Release

Run `/_release`. It reads commits since the last tag, determines whether a release is warranted, and asks the user for approval before proceeding.

### Step 11 — User feedback

Update `work-state/current.md` step to `waiting-feedback`. Commit and push.

Tell the user: "Done: #N — <title>. Say something if you want to review it first — otherwise I'll continue in 5 minutes."

Schedule a one-shot cron 5 minutes out with the prompt: "Resume `/work` from `work-state/current.md`." (see `CLAUDE.md`/`AGENTS.md`'s "Continuing without the user" section for why this step, specifically the cron, is what makes the 5 minutes real.)

If the user responds before it fires, handle their feedback first and cancel the scheduled cron. If feedback is a bug, fix it on a new branch immediately. If feedback changes requirements, run `/talk` to capture it properly, then continue.

Delete `work-state/` entirely and commit the deletion to main before proceeding.

### Step 12 — Loop

Before going back to Step 1: check whether what was learned implementing this issue changes the plan. If the issue turned out significantly larger or smaller than expected, if dependencies between issues shifted, or if the codebase looks materially different from what `/_plan` assumed, re-run `/_plan` before picking the next issue. Do not continue on a stale plan.

Go back to Step 1.

---

## Hotfixes

If the user reports an urgent bug that must be fixed immediately — regardless of what else is in the backlog:

1. Stop the current loop
2. Create an issue labelled `hotfix`
3. Find the last release tag (`git tag --sort=-version:refname | head -1`) and create a branch from it: `fix/<iid>-<description>`
   ```
   git checkout -b fix/<iid>-<description> <last-tag>
   ```
4. Fix the bug, write a test that would have caught it, run `/_scan`
5. Open an MR, merge, run `/_release`
6. Return to the normal loop

A hotfix bypasses normal priority ordering. Do not defer it.

---

## Requirement changes mid-work

If the user changes a requirement while work is in progress:

1. Stop and assess: does the change affect the current branch?
2. If yes: commit the current work as a `wip:` commit, push the branch, then run `/talk` to capture the new requirement properly
3. After `/talk` completes and any affected specs are updated, either amend the current branch or close it and start fresh depending on the extent of the change
4. Run `/_plan` again before continuing — the backlog may need reordering

Do not silently adapt to verbal requirement changes. Every change to requirements must go through `/talk` and be recorded.

---

## Session end

When stopping — whether all done, blocker hit, or user ends the session — give a brief summary:
- What was completed this session (issues closed, releases made)
- What is in progress (if anything)
- What is next

One short paragraph. Then stop.

---

## Stop conditions

| Condition | What to tell the user |
|-----------|----------------------|
| No more open issues | List what was completed this session |
| Issue too vague to implement | "Issue #N is blocked — I need: ..." |
| Release ready | `/_release` asks the user — wait for their response |
| Product decision needed | "I need your input on #N: ..." |
| Critical scan finding blocks scope | "Critical vulnerability in [dep]. Fix requires [change]. Confirm?" |
| User ends the session | Give session summary and stop |

After reporting, stop. Do not continue until the user responds.

---

## Reference — work-state format

```
work-state/
  .gitkeep
  current.md
```

`current.md`:
```
issue: #N
title: <title>
branch: <branch>
step: <step>

## understanding
<condensed notes from step 2 — what this issue requires and how to implement it>
```

Valid step values: `understand`, `implement`, `test`, `scan`, `mr-open`, `waiting-feedback`
