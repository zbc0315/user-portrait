# user-portrait — 用户画像插件

**一句话：学习总结用户画像，输出用户能看懂的语言。**

[English documentation / 英文文档](README.md)

user-portrait 是一个 [Claude Code](https://claude.com/claude-code) 插件。Claude 在收到你的每一条消息时，都会从中学习你的画像——你的语言习惯、知识体系、哪些概念你熟、哪些需要解释、你偏好的沟通方式——并存入一个**全局配置文件**（所有项目、所有会话共享）。之后 Claude 的每一次输出，都会依据这份画像，使用你能看懂的语言和详略程度来表达。

## 工作原理

```
新会话开始 ──► SessionStart hook ──► 注入完整画像 + 本会话常驻指令
你发消息 ──► UserPromptSubmit hook ──► 注入简短提醒：从这条消息学习画像 + 按画像输出
                                       （画像内容有变化时，自动注入最新版）
Claude 发现新信号 ──► Edit 更新画像文件 ──► PostToolUse hook 同步本会话状态
                                          （避免把自己刚写的内容再注入给自己）
```

- **画像文件**：`~/.claude/user-portrait/profile.md` — 全局唯一，纯 Markdown，你可以随时手动编辑。
- **学习内容**：只记录关于"你这个人"的持久性事实（语言、专业领域、知识盲区、沟通偏好），且只在画像**尚未记录**该信号时才写入；**不记录**任务细节、项目内容、密钥或一次性上下文。
- **多会话同步**：通过内容校验和检测变化。画像被任何一个会话更新后，其他会话在你下一条消息时会自动收到最新版；本会话自己的更新不会重复注入。
- **体积上限**：画像被约束在 100 行以内，模型会合并压缩而不是无限追加。

## 安装

从 GitHub 安装：

```
/plugin marketplace add zbc0315/user-portrait
/plugin install user-portrait@user-portrait
```

默认安装到 user 作用域（`~/.claude/settings.json`），即**所有项目全局生效**。

### OpenClaw agent（ClawHub）

[`openclaw/`](openclaw/) 目录提供无 hooks 的 skill 变体，已发布到 ClawHub——规则相同、画像文件相同（与插件并存时共享同一份画像），无需 Claude Code：

```
clawhub install user-portrait
```

基于 hooks 的每条消息自动学习是 Claude Code 插件独有的；skill 变体通过常驻指令实现同样的实践。

### 本地开发

本地开发调试（仅当前会话）：

```bash
git clone https://github.com/zbc0315/user-portrait.git
claude --plugin-dir ./user-portrait
```

### 推荐的权限配置（免除每次写画像的确认弹窗）

在 `~/.claude/settings.json` 中加入：

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

不加也能用，只是 Claude 每个会话第一次更新画像时会请求一次写文件权限（如果你拒绝，模型会停止本会话的画像写入，不会反复纠缠）。

## 使用

装好后无需任何操作——正常聊天即可，画像会自动积累。管理画像用 skill：

| 你说 | 效果 |
|---|---|
| `/user-portrait:portrait` 或"看看我的画像" | 展示当前画像 |
| "我的画像里 X 不对，改成 Y" | 纠正画像 |
| "暂停画像学习" | 注入立即停止；已打开的其他会话从各自下一条消息起停止学习；画像保留 |
| "恢复画像学习" | 全部会话从下一条消息起恢复 |
| "重置我的画像" | 恢复为空白模板（会先确认） |

手动等价操作：直接编辑/删除 `~/.claude/user-portrait/profile.md`；`touch ~/.claude/user-portrait/paused` 暂停，删除该文件恢复。

## 成本与隐私

- 每条消息约多注入 ~100 token 的提醒。完整画像（≤100 行，约 1–2K token）在每次 SessionStart 时注入一次——注意 startup / resume / clear / compact 都会触发 SessionStart。画像内容变化时（通常是其他会话或你手动编辑），下一条消息会重新注入一次最新版；本会话自己的编辑已通过 PostToolUse 同步，不会触发重复注入。
- 画像只存在你本机 `~/.claude/user-portrait/`，不会上传到任何地方（对话本身发给模型时画像内容会随上下文一起发送——这正是它起作用的方式）。
- 画像是全局共享的：任何项目里透露的个人背景信号都会写入同一份文件。如果某些项目不想启用，用 `/plugin` 面板在该项目禁用插件，或暂停学习。

## 卸载

```
/plugin uninstall user-portrait@user-portrait
```

画像数据不会被删除；如需彻底清理：`rm -rf ~/.claude/user-portrait`。

## 目录结构

```
user-portrait/
├── .claude-plugin/
│   ├── plugin.json               # 插件元数据
│   └── marketplace.json          # 使本仓库可直接作为 marketplace 添加
├── hooks/hooks.json              # SessionStart + UserPromptSubmit + PostToolUse
├── scripts/common.sh             # 共享：路径、校验和、注入文案
├── scripts/session-start.sh      # 会话开始：注入画像 + 常驻指令
├── scripts/prompt-submit.sh      # 每条消息：提醒 + 变更检测重注入
├── scripts/post-tool.sh          # 本会话编辑画像后同步状态，避免自我重注入
├── templates/profile-template.md # 画像初始模板（首次运行自动生成）
├── skills/portrait/SKILL.md      # /user-portrait:portrait 管理技能
├── openclaw/                     # 无 hooks 的 skill 变体（已发布到 ClawHub）
├── CHANGELOG.md                  # 更新日志
├── LICENSE                       # MIT 许可证
├── README.md                     # 英文文档（默认）
└── README.zh-CN.md               # 本文件
```

## 许可证

[MIT](LICENSE)
