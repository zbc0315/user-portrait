# Changelog

## 0.1.0 — 2026-08-08

Initial release.

- SessionStart hook: injects the global portrait plus standing instructions (adapt every reply; learn only durable, not-yet-captured signals; privacy rules; permission-denial backoff; pause coupling).
- UserPromptSubmit hook: compact per-message reminder; content-checksum change detection re-injects the portrait when it was modified elsewhere; delivers the full instruction block to sessions that started while paused.
- PostToolUse hook: syncs a session's own profile edits into its state file so they are not re-injected back to it.
- `portrait` skill: show, correct, pause/resume, reset (reset restores the canonical bundled template).
- Global profile at `~/.claude/user-portrait/profile.md`, bounded to 100 lines, bilingual template.
- POSIX `cksum`-based change detection (portable across BSD/GNU userlands; immune to 1-second mtime granularity).
