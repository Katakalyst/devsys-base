#!/bin/sh
# devsys-platform — resolves which platform (gitlab or github) the given
# remote of the repo at $1 (default: current directory) is hosted on, and
# prints it to stdout.
#
# Usage:
#   devsys-platform                     # platform of the repo in the current directory (its "origin")
#   devsys-platform frontend            # platform of a non-default repo
#   devsys-platform . release-mirror    # platform of a non-default remote
#
# Why this exists: before running a glab or gh command, or picking which of
# _gitlab's/_github's skill to consult, you need to know which platform a
# given repo (or, once it has more than one remote, which remote — Git
# Remote & Credential Spec §7's multi-remote decision) is actually on.
# Previously the only way to answer that was to run `git remote get-url
# origin` and eyeball the host — manual, and repeated identically in three
# places (AGENTS.md/CLAUDE.md, _github's own preamble). This does it in one
# step, sharing the exact same remote-URL parsing devsys-token uses
# (devsys-git-remote.sh), so the two can never give inconsistent answers for
# the same (repo, remote).
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/devsys-git-remote.sh"

REPO_PATH="${1:-.}"
REMOTE_NAME="${2:-origin}"

REMOTE_URL=$(devsys_remote_url "$REPO_PATH" "$REMOTE_NAME")
devsys_platform "$REMOTE_URL"
