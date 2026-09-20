---
name: _gitlab
---
# GitLab

How GitLab is used in this system — what each feature means, how to work with it, conventions, and the full API reference.

---

## What GitLab is in this system

GitLab is the single source of truth for all project activity. It holds:
- What needs to be done (issues)
- What is being done (assigned issues, open MRs)
- What was done (closed issues, merged MRs, releases)
- The code itself (repository)
- Verification that the code works (CI pipelines)
- What was shipped (releases, tags)

If something is not in GitLab, it did not happen.

---

## Issues

Issues are the unit of work. Every piece of work — feature, bug fix, task — is an issue before it is code.

**Creating issues**
- Title: short, specific, in plain language. "Add user login" not "Login feature"
- Description: enough context that the issue is self-contained. Include links to relevant specs in `docs/specs/` if one exists.
- Never start implementing something that does not have an issue. If the user asks for something in chat, create the issue first, then implement it.

**Labels**
Use labels to communicate state:
- `in-progress` — you are actively working on this
- `blocked` — cannot proceed, waiting for user input
- No label — open and not yet started

Do not invent new labels. Keep it simple.

**Issue lifecycle**
1. Open — work not started
2. Assigned + `in-progress` label — you are working on it
3. MR opened with `Closes #N` — implementation done, in review
4. Issue auto-closes when MR merges — done

**Milestones**
Use milestones to group issues that belong to the same release or feature set. If the user defines a milestone (e.g. "v1.0"), assign issues to it as you create them. Do not create milestones yourself unless the user asks.

**When an issue is too large**
If during implementation you discover an issue is larger than expected, do not expand scope silently. Implement the core requirement, create follow-up issues for the rest, and reference them in the original issue's comments.

---

## Merge Requests

An MR is the gate between a branch and main. Nothing goes to main without one.

**Creating MRs**
- Title follows Conventional Commits: `feat: add user login`
- Description must include:
  - `Closes #<iid>` — links to the issue and auto-closes it on merge
  - What the change does, briefly
  - How to verify it works (steps to test)
- Always set `remove_source_branch: true` — clean up after merge
- Never merge without CI passing

**Reviewing your own MR**
Before merging, check:
- Does the diff match what the issue asked for — nothing more, nothing less?
- Are there any obvious mistakes — wrong logic, missing error handling, hardcoded values?
- Do the tests actually test the behaviour changed?
- Is the commit history clean and readable?

If any answer is no, fix it before merging.

**Draft MRs**
If you need to push a branch but it is not ready to merge, prefix the title with `Draft:`. Remove the prefix when it is ready.

---

## CI Pipelines

The CI pipeline runs automatically on every push. It is the final check before merging.

**What CI does in this system**
Runs the project's test suite. Nothing else — Trivy and Semgrep run locally before push, not in CI.

**Reading pipeline results**
- `success` — tests pass, safe to merge
- `failed` — tests failed, do not merge. Fetch the job log and fix the failure before pushing again.
- `running` — wait for it to finish before merging

**When CI fails**
1. Fetch the failing job log
2. Read the error — understand what failed and why
3. Fix it on the branch and push again
4. If you cannot fix it after two attempts, stop and tell the user

Never merge a failing pipeline. Never skip CI.

---

## Releases

A release marks a point in time when something was shipped. It consists of:
- A git tag (e.g. `1.2.0`)
- A GitLab release record with release notes describing what changed

The `/_release` skill handles this after every merge to main. It determines whether a release is warranted, asks the user for approval, then creates the tag and release record via `glab release create`. Release notes live in the GitLab release record — there is no `CHANGELOG.md`. Do not create tags or release records manually.

---

## Conventions

- **Never push directly to main.** All changes go through a branch and MR.
- **Branch naming:** `<type>/<issue-iid>-<short-description>` e.g. `feat/5-user-login`
- **Commit messages:** Conventional Commits — `feat`, `fix`, `chore`, `docs`, `refactor`, `test`
- **One issue per branch.** Do not put multiple unrelated changes on the same branch.
- **Close issues through MRs.** Use `Closes #N` in the MR description — do not close issues manually.
- **Comment before stopping.** If you are blocked on an issue, comment on it with your question before telling the user. The comment is the permanent record; the chat is not.

---

## Command Reference

`glab` is the tool for all GitLab operations. It reads the GitLab remote from the current git repository automatically — no project ID needed. Run all commands from inside `/root/workspace`.

**Current user**
```
glab api user
```

**List open issues**
```
glab issue list --state opened
```

**Get a single issue**
```
glab issue view <iid>
```

**Create an issue**
```
glab issue create --title "..." --description "..."
```

**Update an issue (assign, label, close)**
```
glab issue update <iid> --assignee @me
glab issue update <iid> --label "in-progress"
glab issue update <iid> --state close
```

**Comment on an issue**
```
glab issue note <iid> --message "..."
```

**Create an MR**
```
glab mr create \
  --source-branch <branch> \
  --target-branch main \
  --title "feat: my feature" \
  --description "Closes #<iid>

<description>" \
  --remove-source-branch
```

**List open MRs**
```
glab mr list --state opened
```

**View an MR**
```
glab mr view <mr_iid>
```

**Merge an MR**
```
glab mr merge <mr_iid>
```

**CI pipeline status for the current branch**
```
glab ci status
```

**View job logs**
```
glab ci view
```

**List active milestones**
```
glab milestone list --state active
```

**Create a release**
```
glab release create <tag> --name "<tag>" --notes "<changelog markdown>"
```

**Arbitrary API calls (for anything not covered above)**
```
glab api <path>
```
Example: `glab api "projects/:id/pipelines?ref=main&per_page=1"`
