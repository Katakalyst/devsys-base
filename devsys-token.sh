#!/bin/sh
# devsys-token — resolves the per-repo git credential mounted for the repo
# at $1 (default: current directory) and prints it to stdout.
#
# Usage:
#   GITLAB_TOKEN=$(devsys-token) glab issue list --state opened
#   GH_TOKEN=$(devsys-token) gh issue list
#   GITLAB_TOKEN=$(devsys-token frontend) glab issue list   # non-default repo
#
# Why this exists: a project can have more than one repo, each on its own
# platform, each with its own token mounted as a file at
# /run/secrets/devsys-<project>-<repo-id>-<platform>-token (Git Remote &
# Credential Spec §7). glab/gh only read a single host-scoped env var, so
# there is no one fixed GITLAB_TOKEN/GH_TOKEN that works for every repo in
# a multi-repo project — this script picks the right file for whichever
# repo you are actually in, every time you run it.
#
# It does not need to know the exact project name: this container only
# ever has one project's secrets mounted, so matching on the repo-id
# suffix alone is unambiguous.
set -eu

REPO_PATH="${1:-.}"

REMOTE_URL=$(git -C "$REPO_PATH" remote get-url origin 2>/dev/null) || {
    echo "devsys-token: no 'origin' remote in $REPO_PATH" >&2
    exit 1
}

# Derive the repo-id the same way devsys itself does (Git Remote &
# Credential Spec §7): the owner/repo path after the host, with "/" turned
# into "-". Handles SCP-style SSH (git@host:owner/repo.git) and any
# scheme://[user@]host/owner/repo(.git) form (HTTPS, HTTPS with an embedded
# token, ssh://).
case "$REMOTE_URL" in
    git@*)
        REPO_PATH_PART=${REMOTE_URL#*:}
        ;;
    *://*)
        REPO_PATH_PART=$(printf '%s\n' "$REMOTE_URL" | sed -E 's#^[a-zA-Z][a-zA-Z0-9+.-]*://([^/@]*@)?[^/]+/##')
        ;;
    *)
        echo "devsys-token: cannot parse remote URL: $REMOTE_URL" >&2
        exit 1
        ;;
esac
REPO_PATH_PART=${REPO_PATH_PART%.git}
REPO_ID=$(printf '%s\n' "$REPO_PATH_PART" | tr '/' '-')

if [ -z "$REPO_ID" ]; then
    echo "devsys-token: could not derive a repo id from $REMOTE_URL" >&2
    exit 1
fi

TOKEN_FILE=$(ls /run/secrets/*-"$REPO_ID"-gitlab-token /run/secrets/*-"$REPO_ID"-github-token 2>/dev/null | head -1)

if [ -z "$TOKEN_FILE" ]; then
    echo "devsys-token: no credential mounted for repo-id '$REPO_ID' — run 'devsys auth <project>' on the host" >&2
    exit 1
fi

cat "$TOKEN_FILE"
