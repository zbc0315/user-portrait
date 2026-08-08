#!/bin/bash
# user-portrait plugin — SessionStart hook.
# Injects the global user portrait plus standing instructions into the new
# session's context, seeds the profile from the template on first run, and
# records the profile content hash this session has seen (change detection
# for prompt-submit.sh).
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/common.sh"
TEMPLATE="${SCRIPT_DIR}/../templates/profile-template.md"

# Learning paused by the user (portrait skill: pause) — inject nothing.
[ -f "${PAUSED}" ] && exit 0

mkdir -p "${DATA_DIR}" "${STATE_DIR}" 2>/dev/null

# Seed the profile on first ever run.
if [ ! -f "${PROFILE}" ] && [ -f "${TEMPLATE}" ]; then
  cp "${TEMPLATE}" "${PROFILE}" 2>/dev/null
fi
[ -f "${PROFILE}" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"
SESSION_ID="$(extract_session_id "${INPUT}")"
[ -n "${SESSION_ID}" ] || SESSION_ID="unknown"

# Record the profile version this session is being shown.
profile_hash > "${STATE_DIR}/${SESSION_ID}" 2>/dev/null

# Housekeeping: drop per-session state files untouched for 7+ days.
find "${STATE_DIR}" -type f -mtime +7 -delete 2>/dev/null

# Plain stdout with exit 0 is added to the session context.
emit_full_injection
exit 0
