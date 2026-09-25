---
name: _release
---
# /release

Called by `/work` after every merge to main. Determines whether a release is warranted, and if so cuts it — on its own judgment, without waiting for the user. Release cutting must never block the work loop. Every release cut this way is logged to a pending-announcements file and surfaced the next time the user is actually present, rather than interrupting the loop to ask permission per release (see "Reporting to the user" below).

**Platform note:** commands below use `glab` (GitLab). For a GitHub-hosted repo, use the `gh` equivalent — see `_github`'s skill (its `gh pr create` has no create-time "remove source branch" flag, unlike `glab mr create` — that happens at merge time instead: `gh pr merge --delete-branch`).

## When to run

Run this automatically after every MR merge to main.

## Steps

### 1. Get the last release tag

```
git tag --sort=-version:refname | head -1
```

If no tags exist, the previous version is `0.0.0` and all commits are included.

### 2. Read commits since the last tag

```
git log <last-tag>..HEAD --pretty=format:"%H %s" --invert-grep --grep="^state:"
```

If no previous tag: `git log --pretty=format:"%H %s" --invert-grep --grep="^state:"`

### 3. Determine whether a release is needed

Only release if the commits since the last tag include at least one `feat` or `fix` commit.

If there are no `feat` or `fix` commits — do not release. Tell the user: "No release needed — no features or fixes since last release." Stop here.

### 4. Determine version bump

| Condition | Bump |
|-----------|------|
| Any commit contains `BREAKING CHANGE` in body, or type is `feat!` / `fix!` | MAJOR |
| Any commit type is `feat` | MINOR |
| Only `fix` commits | PATCH |

Calculate the new version by applying the bump to the last tag (or `0.0.0`).

### 5. Proceed — do not ask for approval

Do not stop and ask the user before cutting the release. Step 3 already decided a release is warranted and Step 4 already determined the bump — that is the judgment call, and it belongs to the agent, same as every other technical decision. Waiting for a synchronous yes/no here is exactly what turns `/work` from an autonomous loop into one that silently blocks on the user being present, which defeats the point of `/work`.

Write down the one-line reason you'll use later when this gets reported (mirrors the old approval message, just not sent as a question):

**MINOR or PATCH:** "vX.Y.Z (MINOR — 2 new features, 1 bug fix)"
**MAJOR:** "vX.Y.Z (MAJOR — breaking change: [reason])"

Continue to Step 6.

### 6. Run a scan

Run `/_scan`. If any CRITICAL findings exist: do not release. The code is already on main so reverting is not the right move — instead, treat it as a hotfix. Tell the user:

> "Scan found a critical vulnerability: [finding]. I'll fix this before releasing. Creating a hotfix issue now."

Create a GitLab issue labelled `hotfix` describing the vulnerability. Then follow the hotfix flow in `/work` to fix it, ship it, and return here to retry the release.

### 7. Create the git tag

```
git tag -a X.Y.Z -m "Release X.Y.Z"
git push origin X.Y.Z
```

### 8. Create the GitLab release record

Generate the release notes as markdown — the same content that would go into a changelog entry. Clean up commit messages into readable sentences; do not paste them verbatim.

```
GITLAB_TOKEN=$(devsys-token) glab release create X.Y.Z \
  --name "X.Y.Z" \
  --notes "## What changed

### Features
- <feat commits, rewritten as readable sentences>

### Bug Fixes
- <fix commits, rewritten as readable sentences>

### Other
- <chore, docs, refactor commits — only if meaningful>"
```

Omit empty sections.

### 9. Record it as pending announcement

This step is what replaces the old approval prompt — it's how the release still reaches the user, just not synchronously.

Derive the release URL from the git remote:
```
git remote get-url origin
```
Strip `.git` suffix if present, then append `/-/releases/X.Y.Z`.

Append one line to `.devsys/pending-releases.md` (create it if it doesn't exist) with the version, the one-line reason from Step 5, and the URL:
```
- vX.Y.Z (MINOR — 2 new features, 1 bug fix) — https://.../-/releases/X.Y.Z
```

Commit this alongside the tag work (`docs: record pending release announcement vX.Y.Z`) and push it — treat it the same as any other state that must survive a machine switch, same reasoning as `work-state/`.

If you are also in a position to tell the user something right now anyway (not blocking on it, just already talking to them), mention it in passing: "Released vX.Y.Z — <summary>." That's a courtesy, not the mechanism — `.devsys/pending-releases.md` is what guarantees it eventually gets surfaced even if no one's reading this session live.

---

## Reporting to the user

`/_release` itself never waits for the user. Instead, whenever `/work` is about to address the user at a point where they're actually likely to be present — not a cron-driven auto-continue — that's when pending releases get surfaced and cleared:

- The user responds to a Step 11 "Done: #N" message (a real reply, not the cron firing)
- Session end, for any reason (all done, blocker, or the user ending the session)
- The greeting at the start of a new session (Phase 1), if `.devsys/pending-releases.md` exists

At that point: read `.devsys/pending-releases.md`. If it has entries, list them for the user — "Also shipped since you were last around: vX.Y.Z (...), vX.Y.Z (...)." Then clear the file (or delete it if empty afterward) and commit that.

Do not clear it just because `/_release` itself ran — clearing means "the user has now seen this," and a cron-driven loop iteration doesn't mean anyone saw anything.

---

## Hotfix releases

A hotfix release patches a specific older version without including unreleased work from main. Use this when a critical bug is found in a released version and main already has unreleased changes that should not ship yet.

### 1. Identify the target version

Find the tag to patch:
```
git tag --sort=-version:refname
```

### 2. Create a hotfix branch from the tag

```
git checkout -b hotfix/<description> <tag>
```

### 3. Apply the fix

Cherry-pick the fix commit from main if it already exists there, or implement it directly on the hotfix branch.

```
git cherry-pick <commit-hash>
```

### 4. Run scan and tests

Run `/_scan`. Run the test suite. Fix any failures.

### 5. Determine version bump and ask for approval

Follow step 4 of the normal release flow. The bump applies to the tag being patched, not to HEAD on main.

Then follow step 5: ask the user for approval before continuing.

### 6. Create the git tag from the hotfix branch

```
git tag -a X.Y.Z -m "Release X.Y.Z"
git push origin X.Y.Z
```

### 7. Create the GitLab release record

Follow step 8 of the normal release flow.

### 8. Merge the hotfix back to main

Open an MR from the hotfix branch to main and merge it:

```
GITLAB_TOKEN=$(devsys-token) glab mr create \
  --source-branch hotfix/<description> \
  --target-branch main \
  --title "chore: merge hotfix <description> back to main" \
  --description "Brings hotfix X.Y.Z changes back into main." \
  --remove-source-branch
GITLAB_TOKEN=$(devsys-token) glab mr merge <mr_iid>
```
