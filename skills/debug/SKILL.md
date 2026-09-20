---
name: debug
---
# /debug

The user has reported something is broken. The agent investigates and fixes it.

---

## Step 0 — Check for active work

Before anything else, check whether `/work` is currently paused:

```
cat work-state/current.md
```

If `work-state/current.md` exists, note the issue number, branch, and step. Do not modify this file. `/debug` operates entirely on its own branch and does not touch the paused work.

---

## Step 1 — Understand the problem

Ask the user one question: "What's broken? Describe what you expected to happen and what actually happened instead."

Wait for their answer. If the description is vague, ask one follow-up: "Can you show me exactly what you did and what the error or wrong behaviour was?"

Do not ask for more than two questions. Once you have enough to start investigating, begin — do not keep asking.

---

## Step 2 — Reproduce

Before touching any code, reproduce the problem yourself. If you cannot reproduce it, you cannot confirm you have fixed it.

Steps to reproduce:
1. Read the user's description carefully
2. Run the application or relevant code path
3. Confirm you see the same wrong behaviour

If you cannot reproduce it: ask the user once to walk you through the exact steps. If you still cannot reproduce it after their response, stop and tell them: "I can't reproduce this with the information available. To continue I'd need: [specific information missing]."

---

## Step 3 — Investigate

With a reproducible case in hand, investigate the cause:

- Read the relevant code paths
- Check recent commits that touched the affected area: `git log --oneline -20 -- <file>`
- Check for error messages, stack traces, or logs
- Write a failing test that captures the broken behaviour — this both proves you understand the bug and will confirm the fix

For unfamiliar errors, frameworks, or library behaviour: research before assuming. Check official documentation, changelogs, and issue trackers. An error message that looks obvious may have a non-obvious root cause, especially across library versions.

Read the code until you understand exactly why it is failing.

---

## Step 4 — Fix

Fix the root cause, not the symptom. If the bug is a symptom of a deeper structural issue, note the deeper issue as a follow-up (create a GitLab issue for it) but fix the immediate problem first.

Make the failing test pass. Run the full test suite to confirm nothing else broke.

---

## Step 5 — Ship

Create an issue for the bug if one does not already exist. Use it to track the fix.

Follow the normal MR flow defined in `/work`.

---

## Step 6 — Confirm with the user

Tell the user the fix is shipped. Ask them to try it: "Fixed in <version>. Can you try it and confirm it works as expected?"

Wait for their confirmation before considering this done.

If `/work` was active when `debug` started, remind the user: "Work on #N is still paused at step [step] — say 'continue' when you're ready to resume."
