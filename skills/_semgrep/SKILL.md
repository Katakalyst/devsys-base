---
name: _semgrep
---
# Semgrep — How to Use It

This is not a slash command. It is a reference for how Semgrep is used in this system.

---

## What Semgrep is

Semgrep is a static analysis tool. It reads your source code and checks it against a set of rules that catch common security vulnerabilities, bugs, and code quality issues.

Unlike Trivy which checks dependencies, Semgrep checks the code you write. It catches things like: SQL injection patterns, hardcoded secrets, unsafe function calls, missing input validation, and common logic errors.

---

## When to run it

Run Semgrep before opening any MR. The `/_scan` skill does this automatically. Do not push code for review without a clean (or reviewed) Semgrep result.

---

## How to run it

**Scan the project using the auto ruleset (recommended):**
```
semgrep --config auto --json --output semgrep-results.json .
```

The `auto` config selects rules appropriate for the languages detected in the project. It covers security, correctness, and best practices.

**Quick scan with output directly to terminal:**
```
semgrep --config auto .
```

---

## Reading the results

Each finding includes:

- **Rule ID** — identifies which rule fired (e.g. `python.lang.security.audit.exec-detected`)
- **Severity** — ERROR, WARNING, or INFO
- **File and line** — exactly where the issue is
- **Message** — what the rule detected and why it matters
- **Fix suggestion** — often included, showing what the code should look like instead

| Severity | Meaning | Action |
|----------|---------|--------|
| ERROR | High confidence issue — likely a real bug or vulnerability | Fix before opening MR |
| WARNING | Probable issue — worth reviewing, may be a false positive | Investigate. Fix if confirmed real. Note in MR if intentionally accepted. |
| INFO | Style or best practice suggestion | Use your judgement. No action required. |

---

## Fixing findings

Read the rule message carefully — it explains what the pattern is and why it is dangerous. Then:

1. Understand whether it is a true positive (real issue) or false positive (rule fired incorrectly)
2. If true positive: fix the code to eliminate the pattern
3. If false positive: add an inline suppression comment and explain why

**Suppressing a false positive:**
```python
result = some_function(user_input)  # nosemgrep: rule-id
```

Use suppressions sparingly. If you suppress a finding, leave a comment explaining why it is safe.

---

## Common findings and what they mean

**Hardcoded secrets**
A string in the code looks like a password, API key, or token. Fix: move it to an environment variable.

**SQL injection**
User input is being interpolated directly into a SQL query. Fix: use parameterised queries.

**Command injection**
User input is being passed to a shell command. Fix: use safe APIs that do not invoke a shell, or sanitise input strictly.

**Unsafe deserialisation**
Data from an untrusted source is being deserialised without validation. Fix: validate the source or use a safer format.

**Missing error handling**
A function that can fail is being called without checking the error. Fix: handle the error explicitly.

---

## What a clean result looks like

```
semgrep --config auto .
...
Findings:
  0 findings.
```

Zero ERROR and WARNING findings is the goal. INFO findings can be left unaddressed. If a WARNING is a confirmed false positive, suppress it with a comment.