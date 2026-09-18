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
- A changelog entry in `CHANGELOG.md`
- A GitLab release record with the changelog as its description

Releases are created automatically by the `release` skill after every merge to main that contains a `feat` or `fix` commit. Do not create tags or release records manually.

---

## Conventions

- **Never push directly to main.** All changes go through a branch and MR.
- **Branch naming:** `<type>/<issue-iid>-<short-description>` e.g. `feat/5-user-login`
- **Commit messages:** Conventional Commits — `feat`, `fix`, `chore`, `docs`, `refactor`, `test`
- **One issue per branch.** Do not put multiple unrelated changes on the same branch.
- **Close issues through MRs.** Use `Closes #N` in the MR description — do not close issues manually.
- **Comment before stopping.** If you are blocked on an issue, comment on it with your question before telling the user. The comment is the permanent record; the chat is not.

---

## API Reference

All API calls require the header `PRIVATE-TOKEN: $GITLAB_TOKEN`. The project ID is in `CLAUDE.md`. The base URL is `https://gitlab.com/api/v4`.

**Authentication**
```
GET /user
```

**List open issues**
```
GET /projects/:id/issues?state=opened&order_by=priority&sort=asc
```

**Get a single issue**
```
GET /projects/:id/issues/:iid
```

**Create an issue**
```
POST /projects/:id/issues
{ "title": "...", "description": "...", "labels": "..." }
```

**Update an issue**
```
PUT /projects/:id/issues/:iid
{ "assignee_id": <id>, "state_event": "close", "labels": "in-progress" }
```

**Comment on an issue**
```
POST /projects/:id/issues/:iid/notes
{ "body": "..." }
```

**Create a branch**
```
POST /projects/:id/repository/branches
{ "branch": "feat/my-feature", "ref": "main" }
```

**Create an MR**
```
POST /projects/:id/merge_requests
{
  "source_branch": "feat/my-feature",
  "target_branch": "main",
  "title": "feat: my feature",
  "description": "Closes #<iid>\n\n<description>",
  "remove_source_branch": true
}
```

**Merge an MR**
```
PUT /projects/:id/merge_requests/:mr_iid/merge
{ "merge_when_pipeline_succeeds": true }
```

**Get latest pipeline for a branch**
```
GET /projects/:id/pipelines?ref=<branch>&per_page=1
```

**Get pipeline status**
```
GET /projects/:id/pipelines/:pipeline_id
```
Status values: `created`, `pending`, `running`, `failed`, `success`, `canceled`, `skipped`

**Get job log**
```
GET /projects/:id/jobs/:job_id/trace
```

**Create a release**
```
POST /projects/:id/releases
{ "name": "X.Y.Z", "tag_name": "X.Y.Z", "description": "<changelog markdown>" }
```

**Notes**
- `:id` is the numeric project ID — not the project name
- `:iid` is the issue/MR number shown in the UI (e.g. `#5`) — not the global ID
- All write operations require the `api` scope on the PAT
- Rate limit: 2000 requests per minute on GitLab.com
