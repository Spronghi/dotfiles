# Claude Code Session Status in Wezterm Tab Bar — Design

Date: 2026-07-28
Status: approved

## Goal

Show open Claude Code sessions in the bottom-right corner of the wezterm
tab bar (right status of the bottom tab bar): one entry per workspace
with the session's current status.

Example render:

```
dotfiles |  1:nvim  2:zsh                    dotfiles ● running  api ◆ blocked
```

## Statuses

| Status    | Meaning                                                        |
|-----------|----------------------------------------------------------------|
| running   | Claude is working on a turn                                    |
| blocked   | Claude waits for permission / user input (Notification hook)   |
| completed | Turn finished, user has not visited that workspace yet         |
| idle      | Session open, nothing happening, nothing unread                |

`completed` behaves like an unread marker: it becomes `idle` as soon as
the user switches to that workspace.

Multiple Claude sessions in the same workspace are aggregated into one
entry; the worst status wins: `blocked > running > completed > idle`.

## Architecture

Claude Code hooks write tiny state files; wezterm polls and renders.

```
Claude Code hooks ──write──▶ /tmp/claude-wezterm-status/<session_id>
                                        │
wezterm update-status (~1s) ──read──────┘──▶ set_right_status()
```

### Component 1 — hook script (`claude/claude-status-hook.sh` in dotfiles)

- Invoked by Claude Code hooks with the status as `$1`; hook JSON on stdin
  (used for `session_id`).
- Writes `/tmp/claude-wezterm-status/<session_id>` containing:
  `<workspace>\t<status>\t<unix_timestamp>`
- `SessionEnd` deletes the file instead.
- Workspace resolution: `$WEZTERM_PANE` → `wezterm cli list --format json`
  → workspace of that pane. Fallback: basename of `$PWD`.
- Never blocks Claude: always exits 0, does its work quickly.

Hook mapping in `~/.claude/settings.json`:

| Hook event       | Status action      |
|------------------|--------------------|
| UserPromptSubmit | running            |
| PreToolUse       | running            |
| Notification     | blocked            |
| Stop             | completed          |
| SessionStart     | idle               |
| SessionEnd       | delete state file  |

### Component 2 — wezterm module (`wezterm/claude_status.lua`)

- Registers an `update-status` handler (coexists with the existing ones
  in `theme.lua` and `workspaces.lua`; only this one calls
  `set_right_status`).
- Reads all files in `/tmp/claude-wezterm-status/`, parses
  workspace/status/timestamp, skips unparseable files.
- Aggregates per workspace, worst status wins.
- Completed→idle: if an entry's workspace equals the active workspace
  and its status is `completed`, rewrite the state file to `idle`.
- Stale files (timestamp older than 12h) are deleted and ignored.
- Renders entries sorted by workspace name with rose-pine colors:

| Status    | Icon | Color              |
|-----------|------|--------------------|
| running   | ●    | `#f6c177` (gold)   |
| blocked   | ◆    | `#eb6f92` (love)   |
| completed | ✓    | `#9ccfd8` (foam)   |
| idle      | ○    | `#6e6a86` (muted)  |

### Error handling

- Status dir missing → empty right status, no error.
- `wezterm cli` failure in hook → fallback to `$PWD` basename.
- Malformed state file → skipped (and deleted as stale eventually).
- Hook script failures never surface to Claude (exit 0).

## Testing

1. Hand-write fake state files in `/tmp/claude-wezterm-status/`, verify
   bar renders each status, aggregation, and completed→idle on focus.
2. Live: run Claude Code in a workspace, watch running → blocked (ask
   permission) → completed → idle transitions; close session, entry
   disappears.

## Out of scope

- Floating on-screen overlay window (may revisit later).
- Per-session (non-aggregated) display.
- Non-wezterm terminals.
