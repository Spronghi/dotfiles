# Native Notifications for Claude Sessions — Design

Date: 2026-07-28
Status: approved

## Goal

macOS notification when a Claude Code session needs attention and
WezTerm is not the frontmost app. Extends the status hook system
(`2026-07-28-claude-status-bar-design.md`); no new components.

## Behavior

| Status    | Notification                                              |
|-----------|-----------------------------------------------------------|
| completed | title `✓ <workspace>`, body "task completed"              |
| blocked   | title `◆ <workspace>`, body = hook message (e.g. "Claude needs your permission to use Bash") |
| others    | none                                                      |

Suppressed when WezTerm is frontmost (`lsappinfo front` +
`lsappinfo info -only name` — no privacy permissions needed).

## Implementation

In `claude/claude-status-hook.sh`, after writing the state file, for
`completed`/`blocked` only:

1. Frontmost check: skip if LSDisplayName is `WezTerm`.
2. `osascript -e 'display notification ... with title ...'`, inputs
   passed via `osascript` argv (not string interpolation) to avoid
   quoting/injection issues with arbitrary message text.

Failures silent, hook still always exits 0.

## Testing

- Script invoked with fake JSON while another app is frontmost →
  notification appears; while WezTerm frontmost → none.
- Live: start a task, switch to browser, wait for completion.

## Out of scope

- Clickable notifications that focus the wezterm workspace.
- Linux/Windows notification backends.
