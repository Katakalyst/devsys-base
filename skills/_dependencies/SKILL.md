---
name: _dependencies
---
# Dependencies

How to manage project dependencies. Adding, updating, and removing them is the agent's responsibility — the user is not involved unless a dependency choice has product consequences (e.g. licensing restrictions, cost).

---

## The principle

Every dependency is a liability as well as an asset. It adds capability but also adds maintenance burden, security surface, and potential for future breakage. Add dependencies deliberately and remove them when they are no longer needed.

Before adding a dependency, ask: can this be done in a reasonable amount of code without one? If yes, do it without the dependency.

---

## Adding a dependency

**Runtime install directories** (`.venv`, `node_modules`, target/, etc.) must live inside `/root/workspace`. The container's writable layer is discarded on rebuild — only bind-mounted paths survive. Installing dependencies outside `/root/workspace` means they vanish on the next `devsys rebuild`.

**Download caches** (package registries, compiled artifacts, fetched modules) should live in `$DEVSYS_CACHE/<tool>` — a persistent volume that survives rebuilds. Use a separate subdirectory per tool. Common paths and the environment variable or flag to set them:

| Tool | Cache path | How to configure |
|------|-----------|-----------------|
| pip | `$DEVSYS_CACHE/pip` | `pip install --cache-dir $DEVSYS_CACHE/pip` or `PIP_CACHE_DIR=$DEVSYS_CACHE/pip` |
| npm / pnpm | `$DEVSYS_CACHE/npm` | `npm config set cache $DEVSYS_CACHE/npm` |
| Go modules | `$DEVSYS_CACHE/go` | `GOMODCACHE=$DEVSYS_CACHE/go go ...` or `export GOMODCACHE=$DEVSYS_CACHE/go` |
| Cargo | `$DEVSYS_CACHE/cargo` | `export CARGO_HOME=$DEVSYS_CACHE/cargo` |
| Maven | `$DEVSYS_CACHE/maven` | `mvn -Dmaven.repo.local=$DEVSYS_CACHE/maven ...` |
| Gradle | `$DEVSYS_CACHE/gradle` | `export GRADLE_USER_HOME=$DEVSYS_CACHE/gradle` |

Any other tool that downloads things: put it under `$DEVSYS_CACHE/<tool-name>`. Creating the subdirectory is not required — tools create it automatically on first use.

Before adding any new dependency:

1. **Check if it already exists** — read the dependency manifest (`package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, etc.). Do not add what is already there.

2. **Check if the standard library covers it** — many things that seem to need a library can be done with the language's built-in tools. Prefer the standard library.

3. **Evaluate the candidate:**
   - Is it actively maintained? (recent commits, open issues being responded to)
   - Does it have a reasonable number of users? (a library with 3 stars and no tests is a risk)
   - What is its license? (must be compatible with the project's license)
   - How large is it? (a 50MB dependency for a utility function is not justified)
   - Does it bring in many transitive dependencies? (check before adding)

4. **Add it and run `/_scan`** — Trivy will flag any known vulnerabilities in the new dependency immediately.

5. **Record the decision** if the choice between two options was non-obvious. Write a brief decision record in `docs/decisions/`.

---

## Removing a dependency

When refactoring, completing a feature, or noticing something unused:

1. Search the codebase for all usages of the dependency
2. If it has zero usages: remove it from the manifest and lock file
3. If it has usages that are no longer needed: remove the usages first, then remove the dependency
4. Run the test suite after removing — dependencies sometimes have side effects that nothing explicitly imports

Unused dependencies are dead weight. Remove them.

---

## Updating dependencies

Dependencies are updated by the agent as part of routine maintenance — not by a bot, not on a schedule, by the agent reading and deciding.

When working on an area of the code, check if the dependencies it uses have newer versions available. If a newer version is available:

1. Check the changelog for breaking changes
2. If no breaking changes: update and run tests
3. If breaking changes exist: assess the effort to migrate; if small, do it; if large, create an issue

Run `/_scan` after any dependency update — new versions can introduce new vulnerabilities as well as fix them.

---

## Security vulnerabilities in dependencies

When `/_scan` reports a vulnerability in a dependency:

- **CRITICAL / HIGH with a fix available:** Update to the fixed version immediately. Do not ship with known critical vulnerabilities.
- **CRITICAL / HIGH with no fix:** Tell the user. Assess whether the vulnerability is exploitable in this project's context. Options: find an alternative dependency, apply a patch, or accept the risk explicitly with the user's knowledge.
- **MEDIUM / LOW:** Note it. Fix it when convenient, before the next release.
