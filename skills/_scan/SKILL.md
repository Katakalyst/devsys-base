---
name: _scan
---
# /scan

Run Trivy and Semgrep on the current project. Report findings. Block on critical issues.

### Step 0 — Preconditions

- `trivy --version` — if missing, tell the user the container's devsys-base image is broken or stale and to run `devsys rebuild` or `devsys update`, then stop.
- `semgrep --version` — if missing, same as above, then stop.
- `git rev-parse --is-inside-work-tree` — if it fails, tell the user to run this from inside a project directory and stop.

## Steps

### 1. Run Trivy

Scan the project filesystem for known vulnerabilities in dependencies:

```
trivy fs . --format json --output trivy-results.json
```

Parse `trivy-results.json`. Categorise findings by severity: CRITICAL, HIGH, MEDIUM, LOW, UNKNOWN.

### 2. Run Semgrep

Scan the source code for security issues and code quality problems:

```
semgrep --config auto --json --output semgrep-results.json .
```

Parse `semgrep-results.json`. Semgrep uses three severity levels: ERROR, WARNING, INFO.

### 3. Clean up result files

```
rm trivy-results.json semgrep-results.json
```

### 4. Report findings

Print a summary:

```
Trivy:   X critical, X high, X medium, X low
Semgrep: X error, X warning, X info
```

For Trivy CRITICAL and HIGH findings, and Semgrep ERROR and WARNING findings, list each one:
- What it is (CVE ID or rule name)
- Which file or dependency is affected
- What the fix is (upgrade version, code change)

For lower severity findings, give a count only unless the user asks for details.

### 5. Block on critical findings

If any Trivy CRITICAL findings or Semgrep ERROR findings exist:
- Do not allow the current work to be pushed or merged until they are resolved
- Tell the user exactly what needs to be fixed
- After fixes are applied, run `/_scan` again to confirm clean

If only Trivy HIGH or Semgrep WARNING findings exist:
- Report them and recommend fixing before release
- Do not block the current work

If no findings:
- Report: "Scan complete. No vulnerabilities or issues found."
