---
name: _git
---
# Git — How to Use It

This is not a slash command. It is a reference for how git is used in this system. Read this when you are uncertain about any git operation.

---

## Core rules

- **Never push directly to main.** All changes go through a branch and MR.
- **Never force push.** If a push is rejected, understand why before acting.
- **Never commit secrets.** If a secret is accidentally committed, tell the user immediately — do not try to quietly fix it.
- **One concern per branch.** Do not mix unrelated changes on the same branch.
- **Keep commits small and focused.** A commit should do one thing. If you find yourself writing "and" in a commit message, split it into two commits.

---

## Daily workflow

### Starting work on an issue

Always start from an up-to-date main:
```
git checkout main
git pull origin main
git checkout -b <type>/<issue-iid>-<short-description>
```

Branch naming: `<type>/<issue-iid>-<short-description>`
- `feat/5-user-login`
- `fix/12-null-pointer-on-logout`
- `chore/3-update-dependencies`

### Committing

Commit often. Small commits are easier to review and easier to revert if something goes wrong.

```
git add <specific files>
git commit -m "<type>: <short description>"
```

Never use `git add .` or `git add -A` without checking what you are staging first. Always run `git status` and `git diff --staged` before committing to confirm what is included.

Commit message types:
- `feat` — new feature
- `fix` — bug fix
- `chore` — maintenance, dependency updates, config changes
- `docs` — documentation only
- `refactor` — restructuring without behaviour change
- `test` — adding or fixing tests

### Pushing

First push on a new branch:
```
git push -u origin <branch>
```

Subsequent pushes:
```
git push
```

### Keeping a branch up to date with main

If main has moved on while you were working on a branch:
```
git checkout main
git pull origin main
git checkout <branch>
git rebase main
```

Use rebase, not merge, to keep the history linear. If there are conflicts, resolve them file by file, then:
```
git add <resolved files>
git rebase --continue
```

If the rebase becomes too complex, stop and tell the user.

---

## Saving unfinished work

If a session ends before the work on a branch is complete, commit and push the current state so it can be picked up from another machine.

```
git add <files in progress>
git commit -m "wip: <brief description of where things are>"
git push origin <branch>
```

Use the `wip` commit type to mark it clearly as unfinished. Before opening an MR, squash or amend the wip commit into a proper commit so it does not appear in the project history.

When resuming on another machine:
```
git fetch origin
git checkout <branch>
git pull origin <branch>
```

Then read the wip commit message and any issue comments to understand where things were left off.

---

## Undoing things

### Undo the last commit (keep changes)
```
git reset --soft HEAD~1
```

### Undo uncommitted changes to a file
```
git checkout -- <file>
```

### Undo all uncommitted changes
```
git checkout -- .
```

Only use this when you are certain you want to discard everything. There is no recovery.

---

## Reading history

### Recent commits
```
git log --oneline -20
```

### What changed in a commit
```
git show <commit-hash>
```

### What changed between two points
```
git diff main..<branch>
```

### Who changed a line
```
git blame <file>
```

---

## Tagging

Tags are created only by `/developer-system:_release`. Do not create tags manually.

---

## Merge conflicts

Resolving conflicts is the agent's responsibility — do not involve the user unless the conflict reveals a product-level contradiction.

When a rebase or merge produces conflicts:

1. Read both sides of each conflict — understand what each is trying to do
2. Resolve by producing the correct combined result, not by picking a side blindly
3. If the conflict reveals that two features contradict each other at a product level, stop and tell the user — that is a product decision
4. After resolving all conflicts:
```
git add <resolved files>
git rebase --continue   # or git merge --continue
```
5. Run the test suite after resolving — conflicts can introduce subtle bugs

Never use `git checkout --ours` or `git checkout --theirs` without understanding what you are discarding.

---

## When something goes wrong

Before doing anything drastic, stop and understand the situation:
```
git status
git log --oneline -10
```

If you are in a bad state and do not know how to recover cleanly, tell the user what happened rather than making it worse.