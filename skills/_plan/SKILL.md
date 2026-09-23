---
name: _plan
---
# plan

Review and organise the work before it is built — backlog health, scope, gaps, order.

Run this at the start of every `/work` session after orientation, and any time the project feels unclear or disorganised.

The user is not involved in this process unless a product decision surfaces that only they can make.

---

## What this skill does

1. Checks that the backlog reflects reality
2. Identifies scope drift — work that has grown beyond what was specced
3. Finds gaps — things that need to happen but have no issue
4. Breaks down issues that are too large to implement in one go
5. Orders work by dependency and priority
6. Flags anything that requires a product decision before it can proceed

---

## Step 1 — Read the current state

If running as part of `/work`, use the project state already established in orientation — do not re-read files already loaded this session.

If running standalone, read in this order:
- `CLAUDE.md` — project context and conventions
- All files in `docs/specs/` — what was agreed to be built
- All files in `docs/decisions/` — technical and product decisions already made; do not re-open these unless a spec has changed
- All open issues in GitLab — what is currently tracked as work
- Recent git log — what has actually been built

Build a mental model of: what was specced, what is tracked, and what exists in the code.

---

## Step 2 — Check backlog health

For each open issue, ask:

**Is it clear enough to implement?**
An issue is implementable if a developer could pick it up with no further questions and know exactly what done looks like. If not, rewrite the issue description to add the missing clarity. Reference the relevant spec if one exists.

**Is it too large?**
If an issue would take more than two hours of focused work, break it into smaller issues that each deliver something concrete. Close the original and reference the new ones in its closing comment.

**Is it a duplicate?**
If two issues describe the same work, close the weaker one with a comment pointing to the one being kept.

**Is it still relevant?**
If a spec changed or a decision was made that makes an issue obsolete, close it with an explanation.

---

## Step 3 — Check for scope drift

If `docs/specs/` is empty or does not exist: the project has no agreed requirements to validate against. Stop. Tell the user: "There are no specs yet — I'll run `/talk` first to establish what's being built before planning the work." Then run `/talk`.

Compare what is in the specs against what is in the issue backlog.

**Issues with no spec backing:**
An issue that was added without a corresponding spec requirement may be scope creep. For each one, determine:
- Is this clearly implied by an existing spec? If yes, note the link in the issue.
- Is this a technical necessity (infrastructure, refactoring) that does not need a spec? If yes, label it `chore`.
- Is this new scope that the user has not agreed to? If yes, run `/talk` and flag it to the user — do not implement it silently.

**Specs with no issues:**
A spec requirement that has no corresponding issue has fallen through the cracks. Create the missing issues.

---

## Step 4 — Find gaps

Read the code and the specs together. Ask: is there anything the product needs that is not yet specced and not yet in the backlog?

Common gaps:
- Error handling that was not specced but is clearly required
- Configuration that needs to exist for the feature to work
- Tests for behaviour that exists but is untested
- Documentation that needs to be written

Create issues for genuine gaps. Do not create issues for things that are nice-to-have — only things the product actually needs to function correctly.

---

## Step 5 — Review milestones

Check if any milestones exist:
```
GITLAB_TOKEN=$(devsys-token) glab milestone list --state active
```

For each active milestone, check how many of its issues are closed vs open. If a milestone is close to complete (80%+ issues closed), tell the user: "Milestone '<title>' is nearly done — N issues remaining. Want to review what's been built before it closes?"

If no milestones exist and the backlog has more than 10 issues, suggest creating one to the user: "There are N open issues with no milestone grouping them. Want to define a first milestone so we have a clear target?"

Milestones are always defined with the user — the agent does not create them unilaterally. The agent tracks progress against them and flags when they are reached.

---

## Step 6 — Order the backlog

Look at dependencies between issues. An issue depends on another if it cannot be implemented without the other being done first.

For each dependency, add a note to the issue description: "Depends on #N".

If milestones exist, prioritise issues belonging to the nearest milestone first. Within a milestone, order by dependency then by complexity — smaller issues first to build momentum.

Produce the final order for the remaining work. This becomes the sequence `/work` will follow.

---

## Step 7 — Report to the user

Give the user a short summary:
- How many issues are open and roughly how much work remains
- Milestone progress if any milestones exist
- Any scope drift that requires their input
- Any blockers or dependencies worth knowing about
- What will be worked on next

If anything was closed or rewritten during Steps 2–3, list it explicitly so the user can correct mistakes:

> "I also made these backlog changes: closed #12 (duplicate of #8), closed #15 (obsolete — spec removed this requirement), rewrote #9 description to clarify the acceptance criteria."

The user does not need to approve these changes upfront, but they should know what happened so they can reopen or correct anything that was wrong.
