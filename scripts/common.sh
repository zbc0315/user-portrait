# user-portrait plugin — shared definitions, sourced by the hook scripts.
# Not executable on its own.

DATA_DIR="${HOME}/.claude/user-portrait"
PROFILE="${DATA_DIR}/profile.md"
STATE_DIR="${DATA_DIR}/.state"
PAUSED="${DATA_DIR}/paused"

# Content checksum of the profile (POSIX cksum: identical output on BSD/GNU).
# Content-based comparison avoids both the 1-second mtime granularity race
# and BSD/GNU stat flag differences.
profile_hash() {
  { cksum < "${PROFILE}"; } 2>/dev/null || echo "missing"
}

# $1 = raw hook input JSON. Inside JSON string values every double quote is
# backslash-escaped, so a raw "session_id" key sequence can only be the real
# top-level field — prompt text cannot spoof it. Same for "file_path".
extract_session_id() {
  printf '%s' "$1" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1
}

extract_file_path() {
  printf '%s' "$1" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1
}

# Full injection: current portrait + standing instructions. Used by
# SessionStart, and by UserPromptSubmit for sessions that never received it
# (e.g. started while paused, then resumed).
emit_full_injection() {
  cat <<'HEADER'
<user-portrait>
This user maintains a GLOBAL user portrait: a profile of their language,
knowledge, and communication preferences, shared across ALL Claude Code
projects and sessions. File: ~/.claude/user-portrait/profile.md

===== CURRENT PORTRAIT =====
HEADER
  cat "${PROFILE}"
  cat <<'FOOTER'
===== END PORTRAIT =====

Standing instructions, active only while the per-message [user-portrait]
reminder keeps arriving. If a user message ever arrives WITHOUT that
reminder, the user has paused or removed the plugin: stop updating the
portrait and stop applying these instructions until reminders reappear.

1. ADAPT EVERY REPLY to the portrait above.
   - Write in the user's primary language.
   - Match vocabulary to their expertise: for concepts the portrait marks as
     unfamiliar or needing explanation, explain in plain words first and give
     the technical term in parentheses; in domains where they are expert,
     skip the basics and use precise terminology.
   - Follow their recorded communication preferences (detail level, examples,
     analogies, format).
   - Where the portrait is empty or silent, infer the best fit from how the
     user writes, and default to plain, jargon-light language.

2. LEARN how this user understands language. The portrait exists for ONE
   purpose: phrasing replies the user understands. Record ONLY what changes
   how you phrase things:
   - the language they write in, or explicitly ask you to use;
   - expertise fields at COARSE granularity (e.g. "organic chemistry",
     "backend development") — just enough to know where jargon is safe.
     The portrait is a vocabulary calibrator, not a resume: never record
     project names, codebases, detailed stacks, roles, or accomplishments;
   - concept-level comprehension, observed passively: when the user asks
     what a term means, misuses one, or a term you used clearly did not
     land, add that concept to "Needs explanation"; when they correctly
     use a concept you once had to explain, move it to "Understands
     without explanation";
   - expression preferences ONLY: detail level, tone/register, examples
     and analogies, reader-facing style. NEVER record workflow rules, task
     preferences, technical decisions, or how the user wants work done —
     those are out of scope no matter how useful they seem; leave them to
     other memory systems.

   WHEN to write the file — only if ALL of these hold:
   - the signal is durable (about the person, not about today's task);
   - the portrait does not already capture it, or it contradicts/refines an
     existing entry;
   - you would be adding information, not rephrasing what is already there.
   If the portrait already reflects the signal, do NOT touch the file: no
   "Last updated" bumps, no cosmetic rewording, no near-duplicate evidence
   entries. Every write forces a full portrait re-injection into every other
   open session.

   HOW to update: serve the user's actual request first — profile bookkeeping
   never delays or displaces it. Then batch ALL new signals from the message
   into one edit pass: Read ~/.claude/user-portrait/profile.md, then Edit.
   Merge into existing sections; prefer refining an existing line over adding
   a new one; move items between sections as evidence changes (e.g. from
   "needs explanation" to "understands" once demonstrated); remove claims
   contradicted by new evidence. Keep the whole file under 60 lines —
   compress before it grows past that — and update the "Last updated" date.
   Do not keep an evidence or history log: the portrait states current
   conclusions only. NEVER store task details, project content, secrets,
   credentials, or one-off context.

   PERMISSIONS: the first portrait write in a session may trigger a
   permission prompt — that is expected. If the user DECLINES it, make no
   further portrait writes this session: mention once that they can either
   allow Read/Edit/Write on ~/.claude/user-portrait/** in
   ~/.claude/settings.json or pause learning via the user-portrait plugin's
   "portrait" skill, then drop the subject. Keep adapting your replies to
   the portrait either way. Otherwise, update quietly as a normal part of
   your work — no announcement needed — but answer honestly and show the
   file if the user asks.

3. The portrait belongs to the user. If they ask to see, correct, pause, or
   reset it, do so directly (the user-portrait plugin's "portrait" skill
   covers this).
</user-portrait>
FOOTER
}

# Refresh injection: the on-disk portrait differs from what this session
# last saw. Cause-neutral wording — the diff may be the session's own edit
# echoed back (if the PostToolUse sync did not run), another session, or a
# hand edit by the user.
emit_refresh() {
  cat <<'RHEADER'
<user-portrait-refresh>
The portrait file on disk differs from the version this session last saw.
Possible causes: another session updated it, the user edited it by hand, or
your own recent edit is being echoed back. Treat the version below as the
current authoritative portrait and adapt to it from now on. No re-learning,
no evidence logging, and no comment to the user is needed.

RHEADER
  cat "${PROFILE}"
  echo "</user-portrait-refresh>"
}
