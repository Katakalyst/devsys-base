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

# Nothing currently requires pinning, so stay on latest. If a future
# release breaks something, switch to: ARG CLAUDE_CODE_VERSION=^2.1.61
RUN npm install -g @anthropic-ai/claude-code@latest
ENV DISABLE_AUTOUPDATER=1

RUN mv /usr/local/bin/claude /usr/local/bin/_claude
COPY claude-wrapper.sh /usr/local/bin/claude
RUN chmod +x /usr/local/bin/claude

# Nothing currently requires pinning, so stay on latest. If a future
# release breaks something, switch to: ARG CODEX_VERSION=^0.155.0
RUN npm install -g @openai/codex@latest

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

COPY devsys-token.sh /usr/local/bin/devsys-token
RUN chmod +x /usr/local/bin/devsys-token

ENV SHELL=/bin/bash
WORKDIR /root/workspace
CMD ["/usr/local/bin/watchdog"]
