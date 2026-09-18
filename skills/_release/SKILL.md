---
name: _release
---
# /release

Automatically triggered after every merge to main. Determines whether a release is warranted, and if so creates one. The user is not involved unless a MAJOR version bump is detected.

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
git log <last-tag>..HEAD --pretty=format:"%H %s"
```

If no previous tag: `git log --pretty=format:"%H %s"`

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

**If MAJOR:** Tell the user: "This is a MAJOR release (X.Y.Z) because [reason]. This indicates a breaking change. Confirm to proceed." Wait for confirmation before continuing.

**If MINOR or PATCH:** Proceed automatically. Tell the user what version is being released and why, but do not wait for confirmation.

### 5. Run a scan

Run `/_scan`. If any CRITICAL findings exist, stop and tell the user. Do not release with known critical vulnerabilities.

### 6. Write the changelog entry

Append to `CHANGELOG.md` at the top (below any existing header):

```markdown
## X.Y.Z — YYYY-MM-DD

### Features
- <feat commit messages, cleaned up into readable sentences>

### Bug Fixes
- <fix commit messages, cleaned up>

### Other
- <chore, docs, refactor commits — only if meaningful>
```

Omit empty sections. Clean up commit messages — do not paste them verbatim, rewrite them as readable changelog entries.

### 7. Commit the changelog

```
git add CHANGELOG.md
git commit -m "chore: release X.Y.Z"
git push origin main
```

### 8. Create the git tag

```
git tag -a X.Y.Z -m "Release X.Y.Z"
git push origin X.Y.Z
```

### 9. Create the GitLab release record

```
POST https://gitlab.com/api/v4/projects/<id>/releases
{
  "name": "X.Y.Z",
  "tag_name": "X.Y.Z",
  "description": "<changelog entry for this version as markdown>"
}
```

### 10. Report

Tell the user the release is live:
`https://gitlab.com/<namespace>/<project>/-/releases/X.Y.Z`

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

### 5. Determine version bump and write changelog

Follow step 4 and step 6 of the normal release flow. The bump applies to the tag being patched, not to HEAD on main.

### 6. Commit the changelog on the hotfix branch

```
git add CHANGELOG.md
git commit -m "chore: release X.Y.Z"
```

Do not push to main — the hotfix branch is not main.

### 7. Create the git tag from the hotfix branch

```
git tag -a X.Y.Z -m "Release X.Y.Z"
git push origin X.Y.Z
```

### 8. Create the GitLab release record

Follow step 9 of the normal release flow.

### 9. Merge the hotfix back to main

```
git checkout main
git merge hotfix/<description>
git push origin main
git branch -d hotfix/<description>
```
