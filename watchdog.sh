#!/bin/sh
# Watchdog: runs as PID 1 to keep the container alive. Exits (stopping the
# container) when no bash sessions remain. This is a safety net for the case
# where a host-side devsys process is killed (crash, kill -9, power loss)
# after the shell exits but before it can call podman stop.
#
# In normal operation, devsys enter stops the container on shell exit before
# this loop ever fires. This only activates when the normal path fails.
while sleep 60; do
    pgrep -x bash > /dev/null 2>&1 || exit 0
done
