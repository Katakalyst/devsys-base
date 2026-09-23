# devsys-git-remote.sh — shared remote-URL parsing helpers, sourced (never
# executed directly) by devsys-token and devsys-platform. Single source of
# truth for this logic so the two scripts can never drift apart on
# repo-id/platform derivation for the same repo — matches
# internal/workspace's Go implementation on the host exactly (RepoIDFromURL,
# PlatformFromURL — same test cases: HTTPS, HTTPS with embedded credentials,
# SCP-style SSH, ssh://, nested GitLab subgroups).
#
# POSIX sh. Not `set -e`/`set -u` here — that's each caller's own choice;
# this file only defines functions, it does nothing on its own when sourced.

# devsys_remote_url REPO_PATH — prints the repo's origin remote URL to
# stdout, or prints an error to stderr and returns non-zero if there isn't one.
devsys_remote_url() {
    _drr_path="${1:-.}"
    if ! _drr_url=$(git -C "$_drr_path" remote get-url origin 2>/dev/null); then
        echo "devsys: no 'origin' remote in $_drr_path" >&2
        return 1
    fi
    printf '%s\n' "$_drr_url"
}

# devsys_repo_id REMOTE_URL — prints the flattened owner/repo path used in
# Podman secret names (Git Remote & Credential Spec §7): the path segment
# after the host, "/" turned into "-". Handles SCP-style SSH
# (git@host:owner/repo.git) and any scheme://[user@]host/owner/repo(.git)
# form (HTTPS, HTTPS with an embedded token, ssh://).
devsys_repo_id() {
    _dri_url="$1"
    case "$_dri_url" in
        git@*)
            _dri_path=${_dri_url#*:}
            ;;
        *://*)
            _dri_path=$(printf '%s\n' "$_dri_url" | sed -E 's#^[a-zA-Z][a-zA-Z0-9+.-]*://([^/@]*@)?[^/]+/##')
            ;;
        *)
            echo "devsys: cannot parse remote URL: $_dri_url" >&2
            return 1
            ;;
    esac
    _dri_path=${_dri_path%.git}
    _dri_id=$(printf '%s\n' "$_dri_path" | tr '/' '-')
    if [ -z "$_dri_id" ]; then
        echo "devsys: could not derive a repo id from $_dri_url" >&2
        return 1
    fi
    printf '%s\n' "$_dri_id"
}

# devsys_host REMOTE_URL — prints just the hostname, lowercased, stripping
# scheme, userinfo (oauth2:TOKEN@, x-access-token:TOKEN@, etc.), and port.
# Mirrors internal/workspace's hostFromRemoteURL exactly.
devsys_host() {
    _dh_url="$1"
    case "$_dh_url" in
        git@*)
            _dh_rest=${_dh_url#git@}
            _dh_host=${_dh_rest%%:*}
            ;;
        *://*)
            _dh_after_scheme=${_dh_url#*://}
            _dh_before_path=${_dh_after_scheme%%/*}
            _dh_host_and_port=${_dh_before_path##*@}
            _dh_host=${_dh_host_and_port%%:*}
            ;;
        *)
            echo "devsys: cannot parse remote URL: $_dh_url" >&2
            return 1
            ;;
    esac
    printf '%s\n' "$_dh_host" | tr '[:upper:]' '[:lower:]'
}

# devsys_platform REMOTE_URL — prints "github" or "gitlab". Rule: host ==
# github.com -> github; everything else (gitlab.com, self-hosted GitLab, or
# any other host) -> gitlab. Matches internal/workspace.PlatformFromURL
# exactly. Self-hosted GitHub Enterprise is not distinguished from GitLab by
# this rule — documents/TODO.md tracks that as a known, undecided gap.
devsys_platform() {
    _dp_url="$1"
    _dp_host=$(devsys_host "$_dp_url") || return 1
    if [ "$_dp_host" = "github.com" ]; then
        echo "github"
    else
        echo "gitlab"
    fi
}
