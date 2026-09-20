# devsys-base

The shared meta-tooling image every `devsys`-managed project's container is
built `FROM`: git, `glab`, Trivy, Semgrep, Claude Code, Codex. No language
runtimes — those live in each project's own `.devsys/Containerfile`.

Not published yet. See `Containerfile` for what's confirmed vs. still
needs verification before a real build.
