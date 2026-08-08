---
name: portrait
description: Manage the global user portrait maintained by the user-portrait plugin — view, correct, pause/resume learning, or reset. Use when the user asks what Claude has learned about them, wants to view or correct their profile, pause or resume portrait learning, or reset the portrait (user profile / portrait / 我的画像 / 用户画像 / 暂停画像学习 / 重置画像).
---

# Manage the user portrait

Files (all global — shared by every project and session):

- Portrait: `~/.claude/user-portrait/profile.md`
- Pause marker: `~/.claude/user-portrait/paused` (its existence silences the plugin's hooks)
- Canonical empty template: `${CLAUDE_PLUGIN_ROOT}/templates/profile-template.md`
- Session state (internal, safe to delete): `~/.claude/user-portrait/.state/`

Pick the action from the user's request (`$ARGUMENTS` if provided). Default action when unclear: **show**. Always respond in the user's own language.

## show

Read `~/.claude/user-portrait/profile.md` and present its content faithfully in the user's language. Tell them the file path and that they may edit it by hand at any time. If the file does not exist yet, say the portrait is empty and will build up automatically as they chat.

## correct

Apply the user's correction to the file with Edit, exactly as they stated it: reword, move between sections, or delete entries as asked. Then:

- add one line to the Evidence log: `YYYY-MM-DD — user correction (用户手动纠正): <what changed>`
- update the "Last updated" date
- show the affected section afterwards so they can confirm.

## pause

Run: `touch ~/.claude/user-portrait/paused`

Then, for the rest of THIS session, stop following the portrait standing instructions yourself: no more portrait updates and no more portrait-based adaptation until resumed.

Confirm to the user accurately — do not overpromise:

- portrait injections stop immediately in every session;
- this session stops learning and portrait-based adaptation right now;
- other sessions **already open** stop learning from their next message (they are instructed to stop when the per-message reminder disappears);
- sessions started while paused load no portrait content at all;
- the portrait file itself is kept untouched and can be resumed at any time.

## resume

Run: `rm -f ~/.claude/user-portrait/paused`

Confirm that learning resumes from the next message in every session. A session that was started while paused will automatically receive the full portrait and instructions on its next user message.

## reset

This is destructive. Unless the user has already explicitly said to reset (reset / 重置 / 清空), confirm first. Then restore the profile from the plugin's canonical template:

1. Read `${CLAUDE_PLUGIN_ROOT}/templates/profile-template.md` (the template ships inside the plugin — do not reconstruct it from memory).
2. Write its exact content to `~/.claude/user-portrait/profile.md` (Read the profile first if required by the Write tool).

Afterwards confirm the reset and mention that learning starts over from the next message.
