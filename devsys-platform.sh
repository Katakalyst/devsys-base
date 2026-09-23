#!/bin/sh
# devsys-platform — resolves which platform (gitlab or github) the repo at
# $1 (default: current directory) is hosted on, and prints it to stdout.
#
# Usage:
#   devsys-platform            # platform of the repo in the current directory
#   devsys-platform frontend   # platform of a non-default repo
#
# Why this exists: before running a glab or gh command, or picking which of
# _gitlab's/_github's skill to consult, you need to know which platform a
# given repo is actually on. Previously the only way to answer that was to
# run `git remote get-url origin` and eyeball the host — manual, and
# repeated identically in three places (AGENTS.md/CLAUDE.md, _github's own
# preamble). This does it in one step, sharing the exact same remote-URL
# parsing devsys-token uses (devsys-git-remote.sh), so the two can never
# give inconsistent answers for the same repo.
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/devsys-git-remote.sh"

REPO_PATH="${1:-.}"

REMOTE_URL=$(devsys_remote_url "$REPO_PATH")
devsys_platform "$REMOTE_URL"
