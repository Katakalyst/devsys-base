FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        curl \
        ca-certificates \
        gnupg \
        nodejs \
        npm \
        procps \
        python3 \
        python3-pip \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key \
        | gpg --dearmor -o /usr/share/keyrings/trivy.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
        > /etc/apt/sources.list.d/trivy.list \
    && apt-get update && apt-get install -y --no-install-recommends trivy \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --break-system-packages --no-cache-dir semgrep

ARG GLAB_VERSION=1.118.0
RUN curl -fsSL -o /tmp/glab.deb \
        "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/${GLAB_VERSION}/glab_${GLAB_VERSION}_linux_amd64.deb" \
    && dpkg -i /tmp/glab.deb \
    && rm -f /tmp/glab.deb

# Caret range, not "latest": floats to the newest 2.x release automatically
# (bug fixes, new features) but stops at a 3.x major, where semver convention
# allows a breaking change. Nothing today argues for holding it back further
# than that — if a future 2.x release still breaks something devsys depends
# on, pin it back manually (e.g. "2.1.61").
ARG CLAUDE_CODE_VERSION=^2.1.61
RUN npm install -g @anthropic-ai/claude-code@"${CLAUDE_CODE_VERSION}"
ENV DISABLE_AUTOUPDATER=1

RUN mv /usr/local/bin/claude /usr/local/bin/_claude
COPY claude-wrapper.sh /usr/local/bin/claude
RUN chmod +x /usr/local/bin/claude

# Caret range, not "latest" — but note npm's caret is patch-only below 1.0.0:
# ^0.155.0 floats >=0.155.0 <0.156.0, not the full 0.x line. Deliberately
# narrower than Claude's range above, since Codex's pre-1.0 releases have
# been moving fast and are more likely to change flags/config devsys
# depends on. Nothing today argues for holding it back further than that —
# if a future patch release still breaks something, pin it back manually
# (e.g. "0.155.0").
ARG CODEX_VERSION=^0.155.0
RUN npm install -g @openai/codex@"${CODEX_VERSION}"

RUN mv /usr/local/bin/codex /usr/local/bin/_codex
COPY codex-wrapper.sh /usr/local/bin/codex
RUN chmod +x /usr/local/bin/codex

RUN mkdir -p /etc/claude-code /etc/codex
COPY managed-settings.json /etc/claude-code/managed-settings.json
COPY codex-config.toml /etc/codex/config.toml

COPY skills/ /opt/devsys/.claude/skills/
COPY skills/ /etc/codex/skills/
COPY CLAUDE.md /opt/devsys/CLAUDE.md
COPY AGENTS.md /opt/devsys/AGENTS.md

COPY watchdog.sh /usr/local/bin/watchdog
RUN chmod +x /usr/local/bin/watchdog

ENV SHELL=/bin/bash
WORKDIR /root/workspace
CMD ["/usr/local/bin/watchdog"]
