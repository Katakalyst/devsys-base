---
name: _release
---
# /release

Called by `/work` after every merge to main. Determines whether a release is warranted, and if so asks the user for approval before creating one.

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

### 5. Ask the user for approval

Tell the user the proposed release and why. Wait for their response before continuing.

**For MINOR or PATCH:**
> "Ready to release vX.Y.Z (MINOR — 2 new features, 1 bug fix). Shall I proceed?"

**For MAJOR, add the breaking change reason:**
> "Ready to release vX.Y.Z (MAJOR — breaking change: [reason]). This will signal a breaking change to anyone depending on this project. Shall I proceed?"

If the user says no or asks to wait: tell them "Noted, will not release now." Stop here. Do not release until explicitly asked.

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

### 9. Report

Tell the user: "Released X.Y.Z — <one line summary of what changed>."

Derive the release URL from the git remote:
```
git remote get-url origin
```
Strip `.git` suffix if present, then append `/-/releases/X.Y.Z`. Include the URL in the report.

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
