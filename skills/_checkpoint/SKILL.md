---
name: _checkpoint
---
# /_checkpoint

Get every repo in the workspace to a committed-and-pushed state, right now, regardless of what else is in progress. This is the answer to "I need to leave now, save" — and the routine other skills fall back on when a session ends somewhere other than their own designed stopping point.

This is not a normal stopping point. Do not run tests, `/_scan`, or wait for review. The goal is that nothing is lost and nothing is left only on this machine — not that the work is finished or polished.

---

## When to run

- The user says anything to the effect of "I need to leave," "save," "save and stop," "checkpoint," or otherwise signals they're stepping away — from any skill, at any step, or with no skill active at all. Treat this as an interrupt: stop what you're doing and run this before anything else.
- Called by `/work`, `/talk`, or `/debug` at their own designed pause/exit points, instead of each re-implementing their own commit-and-push logic.
- Called as a last resort before a turn ends if you recognize the session is about to end unattended (e.g. you are approaching a context limit) and haven't checkpointed recently.

## What it does not do

- Does not run `/_scan` or the test suite — this is an emergency save, not `/work`'s Step 5/6.
- Does not open or merge an MR. Work saved by `/_checkpoint` stays on its branch.
- Does not decide the work is done. A `wip:` commit from `/_checkpoint` is expected to be amended or squashed later, per `_git`'s "Saving unfinished work" section.

---

## Step 1 — Discover every repo in the workspace

A project can contain more than one git repo. Find all of them, not just the one you happen to be in:

```
find /root/workspace -maxdepth 5 -name .git -type d 2>/dev/null
```

For each result, the repo root is its parent directory. Exclude anything under a dependency/vendor directory (`node_modules`, `vendor`, `.venv`, `target`, etc.) — those are not project repos even if one happens to contain a stray `.git`.

If none are found, tell the user there is nothing to save and stop.

## Step 2 — For each repo, assess state

Run inside that repo:
```
git status --porcelain
git log @{u}.. --oneline 2>/dev/null   # commits ahead of upstream, if any
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null   # has an upstream?
```

Classify the repo as one of:
- **Clean and pushed** — nothing to do, skip it.
- **Uncommitted changes** — needs a commit.
- **Committed but unpushed** (ahead of upstream, or no upstream configured) — needs a push.
- **Detached HEAD / no branch** — do not commit here silently; see Step 5.

## Step 3 — If `/work` is active in this repo, update state first

Check for `work-state/current.md`. If it exists and its `step` doesn't already reflect reality, update it to describe where things actually are before committing — the whole point of `work-state/` is that the *next* session (possibly on another machine) can read it and resume correctly. An out-of-date `current.md` committed alongside real progress is worse than no update at all, because it actively misleads the next session.

Do not invent a false step just to make it look finished. If implementation is half-done, the step is still `implement` — say so.

## Step 4 — Commit

Stage and commit what's there. Use judgment on granularity, but do not spend time crafting a clean commit history — that is not the point right now:

- If the working tree matches a natural commit boundary (e.g. you just finished a coherent chunk), commit it with a normal Conventional Commits message.
- Otherwise, commit as `wip: <brief description of where things are>`, per `_git`'s existing convention. One `wip:` commit covering everything outstanding in the repo is fine — do not split it into artificial pieces.

Never use `git add .`/`git add -A` blindly. Run `git status` first and check nothing unexpected (build output, secrets, `.env` files) is about to be staged. If something looks like it shouldn't be tracked, leave it out and flag it to the user in the final report rather than guessing.

## Step 5 — Push

Push every branch you just committed to, and any branch that was already ahead of its upstream before you started:

```
git push -u origin <branch>   # no upstream yet
git push                      # upstream already set
```

If a push is rejected (e.g. remote has diverged): do not force push. Do not attempt a rebase or merge to force it through right now — that's real work, not a save. Tell the user this repo's branch could not be pushed and why, so they know it only exists on this machine.

If a repo has no remote configured at all, or `devsys-token` fails to resolve a credential for it: same — report it plainly rather than silently leaving it un-pushed with no explanation.

If you found a repo in **detached HEAD** with real changes: do not commit to detached HEAD. Create a branch first (`git checkout -b wip/checkpoint-<date>`), commit there, push it, and say so explicitly in the report — this is unusual enough that the user should know it happened.

## Step 6 — Report

One short summary, per repo if there's more than one:

- What was committed (and as what kind of commit — normal or `wip:`)
- What was pushed, and to which branch
- Anything that could *not* be saved to the remote, and why (no upstream, push rejected, no credential, detached HEAD requiring a new branch)
- If nothing needed saving anywhere: say so plainly — "Already clean and pushed everywhere, nothing to save."

End with an explicit safe-to-leave confirmation, e.g.: "Everything's committed and pushed — safe to close this out." Do not say this if any repo failed to push; name which one didn't instead.

---

## Notes for skills calling into this

`/work`, `/talk`, and `/debug` should call `/_checkpoint` rather than restating commit/push steps inline. It is intentionally the single place that decides what "safe to stop" means, so that a user interrupt, a designed pause point, and a Stop-hook backstop (see `documents/TODO.md`) all produce the same guarantee instead of three slightly different ones.
