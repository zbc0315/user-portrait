#!/bin/bash
# user-portrait plugin — UserPromptSubmit hook.
# Runs on every user message:
#   (a) if this session never received the SessionStart injection (e.g. it
#       started while the plugin was paused and the user has since resumed),
#       inject the full portrait + standing instructions now;
#   (b) if the profile content changed since this session last saw it,
#       re-inject the latest version;
#   (c) always inject a compact standing reminder (its presence is also the
#       signal that the plugin is active; the standing instructions tell the
#       model to stop learning when it disappears).
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/common.sh"

# Learning paused by the user, or profile missing — inject nothing.
[ -f "${PAUSED}" ] && exit 0
[ -f "${PROFILE}" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"
SESSION_ID="$(extract_session_id "${INPUT}")"
[ -n "${SESSION_ID}" ] || SESSION_ID="unknown"

STATE_FILE="${STATE_DIR}/${SESSION_ID}"
CURRENT="$(profile_hash)"

if [ ! -f "${STATE_FILE}" ]; then
  # This session has no recorded state: SessionStart never ran for it (or
  # its state was cleaned up). Deliver the full block so it gets the
  # standing instructions, not just the raw profile.
  mkdir -p "${STATE_DIR}" 2>/dev/null
  printf '%s' "${CURRENT}" > "${STATE_FILE}" 2>/dev/null
  emit_full_injection
  echo
else
  LAST_SEEN="$(cat "${STATE_FILE}" 2>/dev/null || true)"
  if [ "${CURRENT}" != "${LAST_SEEN}" ]; then
    printf '%s' "${CURRENT}" > "${STATE_FILE}" 2>/dev/null
    emit_refresh
    echo
  fi
fi

# Compact per-message reminder (survives context compaction; its presence
# doubles as the "plugin is active" signal).
cat <<'EOF'
[user-portrait] Active. (1) If this message reveals a durable signal about the user — language, expertise, knowledge gaps, communication preferences — that the portrait does not already capture, update ~/.claude/user-portrait/profile.md after serving the request (Read first, then Edit; one batched pass; skip entirely if the portrait already reflects it). (2) Phrase your reply in the language and at the vocabulary level the portrait says this user understands.
EOF
exit 0
