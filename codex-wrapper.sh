#!/bin/sh
set -e

if [ ! -f "${CODEX_HOME}/AGENTS.md" ] && [ ! -f "${CODEX_HOME}/AGENTS.override.md" ]; then
    cp /opt/devsys/AGENTS.md "${CODEX_HOME}/AGENTS.md" 2>/dev/null || true
fi

# --dangerously-bypass-approvals-and-sandbox applies to "codex and most
# subcommands" per the CLI's own docs/help text, not literally all of them.
# Deny-list the subcommands confirmed NOT to run agent turns (auth, MCP/plugin
# management, diagnostics, session bookkeeping) rather than allow-list the
# ones that do — new agentic subcommands are more likely to appear over time
# than this deny-list changing, so defaulting to "inject the flag" is the
# safer failure mode going forward.
case "$1" in
    login|logout|mcp|plugin|app|app-server|remote-control|doctor|update|\
    completion|features|debug|sandbox|execpolicy|archive|unarchive|delete|\
    apply|cloud|agents|queue|migrate-rollouts)
        exec /usr/local/bin/_codex "$@"
        ;;
    *)
        exec /usr/local/bin/_codex --dangerously-bypass-approvals-and-sandbox "$@"
        ;;
esac
