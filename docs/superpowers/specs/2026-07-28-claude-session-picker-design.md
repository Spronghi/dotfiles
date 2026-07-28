# Claude Session Picker (Ctrl+I) — Design

Date: 2026-07-28
Status: approved

## Goal

Ctrl+I opens an fzf modal listing all open Claude Code sessions
(workspace + status, colored like the tab bar); selecting one navigates
directly to the pane running claude — workspace, tab, and pane.

Builds on the claude status system
(`2026-07-28-claude-status-bar-design.md`).

## Decisions

- Key: **Ctrl+I** (accepted trade-off: steals Ctrl+I-as-Tab from TUIs;
  the Tab key itself is unaffected).
- Sort: urgency first — `blocked > running > completed > idle`,
  alphabetical within the same status.
- One entry per claude pane; status is the workspace's aggregated
  status (same aggregation as the bar).
- Current workspace's sessions are included.

## Architecture

### 1. `wezterm/claude_status.lua` — refactor to a module

Extract the internals shared by bar and picker:

- `M.sessions()` → `{ { workspace, pane_id?, status }, ... }`
  - presence scan (existing `claude_workspaces` logic, extended to
    return pane objects) supplies claude panes with `pane_id`;
  - state files supply per-workspace status, worst wins;
  - claude pane without state file → `idle`;
  - state file without a visible claude pane → entry with
    `pane_id = nil`.
- `update-status` handler (the bar) renders from the same data.
- `M.pick` — action callback for the keybinding.

### 2. Picker

`M.pick` builds entries and delegates to `sessionizer.show_fzf`:

- same modal styling as Ctrl+E: background `#1f1d2e`,
  `--no-input --info=hidden j/k` bindings;
- labels `<workspace> <icon> <status>` colored with the bar's palette
  (fzf already runs with `--ansi`);
- entry id encodes the target: `pane:<pane_id>` or `ws:<workspace>`;
- zero sessions → `window:toast_notification`, no modal.

### 3. Navigation callback

- `pane:<id>` → `wezterm.mux.get_pane(id)`; SwitchToWorkspace to the
  pane's workspace, then `tab:activate()` and `pane:activate()`.
- `ws:<name>` → plain SwitchToWorkspace.
- Pane died between render and pick → fall back to workspace switch.
- All wrapped in pcall; a failure never breaks the keybinding.

### 4. Keybinding

`configs/keys.lua`: `{ key = "i", mods = "CTRL", action = claude_status.pick }`.

## Error handling

- `wezterm.mux.get_pane` failure or nil → workspace-switch fallback.
- Malformed/stale state files already handled by the status module.
- Empty session list → toast, no modal spawn.

## Testing

1. `M.sessions()` inspected via the debug overlay (Leader+D).
2. Live: three claude sessions open, Ctrl+I, pick each entry, verify
   landing on the exact pane; kill one session, verify fallback and
   list refresh.

## Out of scope

- Preview pane in fzf (session transcript, etc.).
- Actions other than navigation (kill session, etc.).
