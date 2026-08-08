# user-portrait

**Learn a portrait of the user; speak in language they understand.**

[中文文档 / Chinese documentation](README.zh-CN.md)

user-portrait is a [Claude Code](https://claude.com/claude-code) plugin. On every message you send, Claude learns durable facts about you — your language, your areas of expertise, the concepts you know cold and the ones that need explaining, and your communication preferences — into a single **global profile** shared across all projects and sessions. Every reply is then phrased at a vocabulary level and in a language that profile says you understand.

## How it works

```
Session starts ──► SessionStart hook ──► injects the full portrait + standing instructions
You send a message ──► UserPromptSubmit hook ──► injects a short reminder:
                                                 learn from this message + adapt the reply
                                                 (re-injects the portrait if it changed)
Claude spots a new signal ──► edits the profile file ──► PostToolUse hook syncs
                                                         this session's state
                                                         (no self re-injection)
```

- **Profile file**: `~/.claude/user-portrait/profile.md` — one global Markdown file you can edit by hand at any time.
- **What gets learned**: only durable facts about *you* (language, expertise, knowledge gaps, communication preferences), and only when the portrait does not already capture the signal. Task details, project content, secrets, and one-off context are never stored.
- **Multi-session sync**: change detection uses content checksums. When any session updates the profile, every other session receives the latest version with your next message; a session's own edits are not re-injected back to it.
- **Bounded size**: the profile is kept under 100 lines — Claude merges and compresses instead of appending forever.

## Installation

From GitHub:

```
/plugin marketplace add zbc0315/user-portrait
/plugin install user-portrait@user-portrait
```

By default the plugin installs at user scope (`~/.claude/settings.json`), so it is active in **all** your projects.

For local development (current session only):

```bash
git clone https://github.com/zbc0315/user-portrait.git
claude --plugin-dir ./user-portrait
```

### Recommended permission rules

Add this to `~/.claude/settings.json` to skip the confirmation prompt for profile writes:

```json
{
  "permissions": {
    "allow": [
      "Read(~/.claude/user-portrait/**)",
      "Edit(~/.claude/user-portrait/**)",
      "Write(~/.claude/user-portrait/**)"
    ]
  }
}
```

The plugin works without these rules; Claude simply asks once per session before the first profile write (and backs off for the rest of the session if you decline).

## Usage

Nothing to do — chat normally and the portrait builds up on its own. Manage it with the bundled skill:

| Say | Effect |
|---|---|
| `/user-portrait:portrait` or "show my portrait" | Display the current portrait |
| "X in my portrait is wrong, it should be Y" | Correct the portrait |
| "pause portrait learning" | Injections stop immediately; other open sessions stop learning from their next message; the file is kept |
| "resume portrait learning" | All sessions resume from their next message |
| "reset my portrait" | Restore the blank template (asks for confirmation first) |

Manual equivalents: edit or delete `~/.claude/user-portrait/profile.md` directly; `touch ~/.claude/user-portrait/paused` to pause, delete that file to resume.

## Cost and privacy

- Each message carries a ~100-token reminder. The full portrait (≤100 lines, roughly 1–2K tokens) is injected once per SessionStart — note that startup, resume, clear, and compact each fire SessionStart. When the profile content changes (typically another session or a hand edit), the latest version is re-injected once with your next message; a session's own edits are synced via the PostToolUse hook and do not re-inject.
- The profile lives only on your machine under `~/.claude/user-portrait/`. It is never uploaded anywhere — though, like all context, its content is sent to the model with your conversations; that is precisely how it works.
- The profile is global: personal background revealed in any project is written to the same file. To keep a project out, disable the plugin for that project in the `/plugin` panel, or pause learning.

## Uninstall

```
/plugin uninstall user-portrait@user-portrait
```

Profile data is not deleted. To remove it completely: `rm -rf ~/.claude/user-portrait`.

## Repository layout

```
user-portrait/
├── .claude-plugin/
│   ├── plugin.json               # plugin manifest
│   └── marketplace.json          # lets this repo be added as a marketplace directly
├── hooks/hooks.json              # SessionStart + UserPromptSubmit + PostToolUse
├── scripts/common.sh             # shared: paths, checksums, injection text
├── scripts/session-start.sh      # session start: inject portrait + standing instructions
├── scripts/prompt-submit.sh      # every message: reminder + change-detection re-injection
├── scripts/post-tool.sh          # sync state after this session's own profile edits
├── templates/profile-template.md # initial profile template (seeded on first run)
├── skills/portrait/SKILL.md      # /user-portrait:portrait management skill
├── CHANGELOG.md                  # release history
├── LICENSE                       # MIT
├── README.md                     # this file
└── README.zh-CN.md               # Chinese documentation
```

## License

[MIT](LICENSE)
