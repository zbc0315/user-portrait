#!/bin/bash
# user-portrait plugin — PostToolUse hook (matcher: Edit|Write|MultiEdit|NotebookEdit).
# When THIS session edits the profile, immediately record the new content
# hash in the session's own state file, so the next user message does not
# re-inject a profile the session already has in context. Genuinely external
# changes (other sessions, hand edits) still trigger the refresh.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/common.sh"

[ -f "${PROFILE}" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"

FILE_PATH="$(extract_file_path "${INPUT}")"
case "${FILE_PATH}" in
  */.claude/user-portrait/profile.md) ;;
  *) exit 0 ;;
esac

SESSION_ID="$(extract_session_id "${INPUT}")"
[ -n "${SESSION_ID}" ] || exit 0

mkdir -p "${STATE_DIR}" 2>/dev/null
profile_hash > "${STATE_DIR}/${SESSION_ID}" 2>/dev/null
exit 0
