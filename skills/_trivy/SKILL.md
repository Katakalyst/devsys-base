---
name: _trivy
---
# Trivy — How to Use It

This is not a slash command. It is a reference for how Trivy is used in this system.

---

## What Trivy is

Trivy is a vulnerability scanner. It checks your project's dependencies against a database of known vulnerabilities (CVEs) and reports which ones are present, how severe they are, and what version fixes them.

It does not analyse your code — it analyses what your code depends on. A clean Trivy result means no known vulnerabilities in your dependency tree. It does not mean your code is secure.

---

## When to run it

Run Trivy before opening any MR. The `/_scan` skill does this automatically. Do not push code for review without a clean (or reviewed) Trivy result.

---

## How to run it

**Scan the project's dependency files (most common):**
```
trivy fs . --format json --output trivy-results.json
```

This scans package manifests (`package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, etc.) and lock files in the current directory.

**Scan a container image (if the project builds one):**
```
trivy image <image-name>:<tag>
```

**Quick scan with output directly to terminal:**
```
trivy fs .
```

---

## Reading the results

Each finding has a severity level:

| Severity | Meaning | Action |
|----------|---------|--------|
| CRITICAL | Actively exploitable, high impact | Fix before proceeding. Do not open MR. |
| HIGH | Serious vulnerability, likely exploitable | Fix before release. Note in MR description. |
| MEDIUM | Moderate risk, specific conditions required | Fix when convenient. Note if relevant to the project's threat model. |
| LOW | Minor risk, unlikely to be exploited | Informational. No action required unless volume is high. |
| UNKNOWN | Severity not yet assessed | Treat as MEDIUM until clarified. |

Each finding shows:
- **CVE ID** — the identifier of the vulnerability (e.g. `CVE-2023-12345`)
- **Package** — which dependency is affected
- **Installed version** — what version you have
- **Fixed version** — what version fixes it (if a fix exists)

---

## Fixing findings

The fix is almost always: upgrade the dependency to the fixed version.

1. Find the affected package in your dependency file
2. Update it to at least the fixed version
3. Run your test suite — confirm nothing broke
4. Run Trivy again — confirm the finding is gone

If no fixed version exists yet:
- For CRITICAL/HIGH: tell the user. This is a blocker. Options are: wait for a fix, find an alternative package, or accept the risk with the user's explicit approval.
- For MEDIUM/LOW: note it in the MR description and continue.

---

## What a clean result looks like

```
trivy fs .
...
Total: 0 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)
```

Zero findings across all severities is the goal. In practice, LOW and MEDIUM findings in transitive dependencies are common and acceptable. CRITICAL and HIGH are not.