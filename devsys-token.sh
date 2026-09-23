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
#
# See also: devsys-platform, which answers "gitlab or github?" for the same
# repo using the identical URL-parsing logic (devsys-git-remote.sh) — the
# two can never disagree on what repo you're actually in.
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/devsys-git-remote.sh"

REPO_PATH="${1:-.}"

REMOTE_URL=$(devsys_remote_url "$REPO_PATH")
REPO_ID=$(devsys_repo_id "$REMOTE_URL")

TOKEN_FILE=$(ls /run/secrets/*-"$REPO_ID"-gitlab-token /run/secrets/*-"$REPO_ID"-github-token 2>/dev/null | head -1)

if [ -z "$TOKEN_FILE" ]; then
    echo "devsys-token: no credential mounted for repo-id '$REPO_ID' — run 'devsys auth <project>' on the host" >&2
    exit 1
fi

cat "$TOKEN_FILE"
