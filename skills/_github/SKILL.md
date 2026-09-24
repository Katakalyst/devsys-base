---
name: _github
---
# GitHub

How GitHub is used in this system for a repo hosted there — what each feature means, how to work with it, conventions, and the full API reference. This mirrors `_gitlab`'s skill exactly in structure and intent; consult whichever one matches the platform the repo you're working in is actually on (run `devsys-platform` if unsure — prints `gitlab` or `github`).

---

## What GitHub is in this system

For any repo hosted on GitHub, GitHub is the single source of truth for that repo's activity, the same role GitLab plays for a GitLab-hosted repo. It holds:
- What needs to be done (issues)
- What is being done (assigned issues, open pull requests)
- What was done (closed issues, merged pull requests, releases)
- The code itself (repository)
- What was shipped (releases, tags)

If something is not in GitHub, it did not happen — same rule as GitLab, just enforced on this platform's record instead.

---

## Issues

Issues are the unit of work, same as on GitLab. Every piece of work — feature, bug fix, task — is an issue before it is code.

**Creating issues**
- Title: short, specific, in plain language. "Add user login" not "Login feature"
- Body: enough context that the issue is self-contained. Include links to relevant specs in `docs/specs/` if one exists.
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
3. PR opened with `Closes #N` — implementation done, in review
4. Issue auto-closes when the PR merges — done

**Milestones**
Use milestones to group issues that belong to the same release or feature set, the same as on GitLab. **Real platform gap, not glossed over: core `gh` has no built-in command to list or manage milestones.** The feature request for one (`cli/cli#1200`) was closed by GitHub CLI's own maintainers, labeled `extension-idea` — pointed toward a third-party extension (`gh-milestone`) instead of building it in. Not something to add a dependency on for this system; use the raw API directly instead: `GH_TOKEN=$(devsys-token) gh api repos/{owner}/{repo}/milestones?state=open`. `gh issue list --milestone "<name>"` can filter issues by a milestone you already know the name of, but nothing lists the milestones themselves. If the user defines a milestone (e.g. "v1.0"), assign issues to it via the GitHub web UI or `gh api` — do not create milestones yourself unless the user asks.

**When an issue is too large**
If during implementation you discover an issue is larger than expected, do not expand scope silently. Implement the core requirement, create follow-up issues for the rest, and reference them in the original issue's comments.

---

## Pull Requests

A PR is the gate between a branch and main — GitHub's name for what GitLab calls a Merge Request. Nothing goes to main without one.

**Creating PRs**
- Title follows Conventional Commits: `feat: add user login`
- Body must include:
  - `Closes #<number>` — links to the issue and auto-closes it on merge
  - What the change does, briefly
  - How to verify it works (steps to test)
- **Platform difference from GitLab, worth being precise about: `gh pr create` has no flag to remove the source branch at create time** (unlike `glab mr create --remove-source-branch`). Branch deletion on this platform happens at merge time instead: `gh pr merge <number> --delete-branch`. Don't look for a create-time equivalent — there isn't one.

**Reviewing your own PR**
Before merging, check:
- Does the diff match what the issue asked for — nothing more, nothing less?
- Are there any obvious mistakes — wrong logic, missing error handling, hardcoded values?
- Do the tests actually test the behaviour changed?
- Is the commit history clean and readable?

If any answer is no, fix it before merging.

**Draft PRs**
If you need to push a branch but it is not ready to merge, create it as a draft: `gh pr create --draft`. Mark it ready when it is: `gh pr ready <number>`.

---

## Releases

A release marks a point in time when something was shipped, same concept as GitLab. It consists of:
- A git tag (e.g. `1.2.0`)
- A GitHub release record with release notes describing what changed

The `/_release` skill handles this after every merge to main, the same way it does for GitLab, using `gh release create` on this platform instead of `glab release create`. Release notes live in the GitHub release record — there is no `CHANGELOG.md`. Do not create tags or release records manually.

---

## Conventions

Identical to GitLab's, just enforced against GitHub's record instead:
- **Never push directly to main.** All changes go through a branch and PR.
- **Branch naming:** `<type>/<issue-number>-<short-description>` e.g. `feat/5-user-login`
- **Commit messages:** Conventional Commits — `feat`, `fix`, `chore`, `docs`, `refactor`, `test`
- **One issue per branch.** Do not put multiple unrelated changes on the same branch.
- **Close issues through PRs.** Use `Closes #N` in the PR body — do not close issues manually.
- **Comment before stopping.** If you are blocked on an issue, comment on it with your question before telling the user. The comment is the permanent record; the chat is not.

---

## Command Reference

`gh` is the tool for all GitHub operations. Unlike `glab`, it does not always auto-detect the repo from `.git/config` for every subcommand the same way — pass `-R owner/repo` explicitly if a command errors without it. Run all commands from inside the repo they're about.

**Every command below needs a credential** — exactly the same reason as `_gitlab`'s skill: a project can have more than one repo, each with its own token, so there is no fixed `GH_TOKEN` that always works. Prefix every command with `GH_TOKEN=$(devsys-token)`, exactly as shown (see `CLAUDE.md`/`AGENTS.md`'s "`glab`/`gh` credentials" section for why).

**Current user**
```
GH_TOKEN=$(devsys-token) gh api user
```

**List open issues**
```
GH_TOKEN=$(devsys-token) gh issue list --state open
```

**Get a single issue**
```
GH_TOKEN=$(devsys-token) gh issue view <number>
```

**Create an issue**
```
GH_TOKEN=$(devsys-token) gh issue create --title "..." --body "..."
```

**Update an issue (assign, label)**
```
GH_TOKEN=$(devsys-token) gh issue edit <number> --add-assignee @me --add-label "in-progress"
```

**Close an issue**
```
GH_TOKEN=$(devsys-token) gh issue close <number>
```

**Comment on an issue**
```
GH_TOKEN=$(devsys-token) gh issue comment <number> --body "..."
```

**Create a PR**
```
GH_TOKEN=$(devsys-token) gh pr create \
  --base main \
  --head <branch> \
  --title "feat: my feature" \
  --body "Closes #<number>

<description>"
```

**List open PRs**
```
GH_TOKEN=$(devsys-token) gh pr list --state open
```

**View a PR**
```
GH_TOKEN=$(devsys-token) gh pr view <number>
```

**Merge a PR (and delete the branch — no create-time equivalent on this platform, see Pull Requests above)**
```
GH_TOKEN=$(devsys-token) gh pr merge <number> --merge --delete-branch
```

**List milestones (no native subcommand — see Issues above)**
```
GH_TOKEN=$(devsys-token) gh api repos/{owner}/{repo}/milestones?state=open
```

**Create a release**
```
GH_TOKEN=$(devsys-token) gh release create <tag> --title "<tag>" --notes "<changelog markdown>"
```

**Arbitrary API calls (for anything not covered above)**
```
GH_TOKEN=$(devsys-token) gh api <path>
```
Example: `GH_TOKEN=$(devsys-token) gh api "repos/{owner}/{repo}/actions/runs?per_page=1"`

**In a multi-repo project, run these from inside the specific repo the command is about** — `devsys-token` resolves the credential for whichever repo the current directory is in. From outside any repo, pass its path instead: `GH_TOKEN=$(devsys-token frontend) gh issue list`.

**A repo can also have more than one remote** (platform migration, a mirror, a fork/upstream pair — `devsys auth` sets these up the same way as a normal remote). `devsys-token`/`devsys-platform` default to `origin`; pass the remote name as a second argument only when you're deliberately targeting `gh`/`glab` at a different one: `GH_TOKEN=$(devsys-token . release-mirror) gh release create --repo owner/mirror-repo`. Plain `git push`/`fetch`/`pull` against any remote needs none of this — the credential already travels embedded in that remote's own URL.
