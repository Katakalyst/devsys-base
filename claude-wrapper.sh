#!/bin/sh
if [ ! -f "${CLAUDE_CONFIG_DIR}/CLAUDE.md" ]; then
    cp /opt/devsys/CLAUDE.md "${CLAUDE_CONFIG_DIR}/CLAUDE.md"
fi
exec /usr/local/bin/_claude --add-dir /opt/devsys "$@"
