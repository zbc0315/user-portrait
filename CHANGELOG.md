# Changelog

## 0.2.1 — 2026-08-18

- Removed the Evidence log entirely (template, instructions, and skill actions): the portrait states current conclusions only, keeping no history. File size cap tightened from 100 to 60 lines.

## 0.2.0 — 2026-08-18

Scope tightened after real-world use: the portrait is a vocabulary calibrator, not a resume or preference store.

- Expertise is now recorded at coarse field granularity only (e.g. "organic chemistry") — project names, codebases, detailed stacks, roles, and accomplishments are explicitly out of scope.
- Workflow rules, task preferences, and technical decisions are explicitly excluded from Communication preferences; only expression preferences (detail level, tone, examples, reader framing) are kept.
- New passive comprehension channel: concepts the user asks about / misuses go to "Needs explanation"; concepts they later use correctly move to "Understands without explanation".
- Evidence log entries must name signals in the abstract — no filenames, commands, project names, or job specifics.
- Template comments and the OpenClaw skill variant updated to match.

## 0.1.0 — 2026-08-08

Initial release.

- SessionStart hook: injects the global portrait plus standing instructions (adapt every reply; learn only durable, not-yet-captured signals; privacy rules; permission-denial backoff; pause coupling).
- UserPromptSubmit hook: compact per-message reminder; content-checksum change detection re-injects the portrait when it was modified elsewhere; delivers the full instruction block to sessions that started while paused.
- PostToolUse hook: syncs a session's own profile edits into its state file so they are not re-injected back to it.
- `portrait` skill: show, correct, pause/resume, reset (reset restores the canonical bundled template).
- Global profile at `~/.claude/user-portrait/profile.md`, bounded to 100 lines, bilingual template.
- POSIX `cksum`-based change detection (portable across BSD/GNU userlands; immune to 1-second mtime granularity).
