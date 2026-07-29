#!/bin/sh
# Claude Code hook: records this session's status so wezterm can render
# it in the tab bar (see wezterm/claude_status.lua).
#
# Usage: claude-status-hook.sh <running|blocked|completed|idle|end>
# Hook JSON arrives on stdin; only session_id is used. Never fails:
# a broken status bar must not break Claude.

STATUS="$1"
DIR="/tmp/claude-wezterm-status"
WEZTERM_BIN="/Applications/WezTerm.app/Contents/MacOS/wezterm"
JQ="/usr/bin/jq"

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | "$JQ" -r '.session_id // empty' 2>/dev/null)
[ -n "$SESSION_ID" ] || exit 0

# Notification fires both for permission requests and for plain
# "waiting for your input" idle nags; only the former is "blocked".
if [ "$STATUS" = "blocked" ]; then
  MESSAGE=$(printf '%s' "$INPUT" | "$JQ" -r '.message // empty' 2>/dev/null)
  case "$MESSAGE" in
    *waiting*) exit 0 ;;
  esac
fi

NOTIFIER="/opt/homebrew/bin/terminal-notifier"

if [ "$STATUS" = "end" ]; then
  rm -f "$DIR/$SESSION_ID"
  # session gone → its notification is stale
  [ -x "$NOTIFIER" ] && "$NOTIFIER" -remove "claude-$SESSION_ID" >/dev/null 2>&1
  exit 0
fi

# Workspace (wezterm session name) of the pane Claude runs in. Not
# inside wezterm, or lookup fails → no entry at all.
WORKSPACE=""
if [ -n "$WEZTERM_PANE" ] && [ -x "$WEZTERM_BIN" ]; then
  WORKSPACE=$("$WEZTERM_BIN" cli list --format json 2>/dev/null \
    | "$JQ" -r --argjson pane "$WEZTERM_PANE" \
        '.[] | select(.pane_id == $pane) | .workspace' 2>/dev/null)
fi
[ -n "$WORKSPACE" ] || exit 0

mkdir -p "$DIR"
# WEZTERM_PANE is guaranteed non-empty here (workspace lookup needs it);
# it lets wezterm show per-session status instead of per-workspace.
printf '%s\t%s\t%s\t%s\n' "$WORKSPACE" "$STATUS" "$(date +%s)" "$WEZTERM_PANE" > "$DIR/$SESSION_ID"

# Native notification for statuses that need attention, but only when
# wezterm is in the background. Text goes through argv, not string
# interpolation, so arbitrary hook messages can't break the osascript.
if [ "$STATUS" = "completed" ] || [ "$STATUS" = "blocked" ]; then
  FRONT=$(lsappinfo info -only name "$(lsappinfo front)" 2>/dev/null)
  case "$FRONT" in
    *WezTerm*) exit 0 ;;
  esac

  if [ "$STATUS" = "completed" ]; then
    TITLE="✓ $WORKSPACE"
    BODY="task completed"
  else
    TITLE="◆ $WORKSPACE"
    BODY=$(printf '%s' "$INPUT" | "$JQ" -r '.message // "waiting for you"' 2>/dev/null)
  fi

  # terminal-notifier allows a custom image; osascript is the fallback
  # (with its stock Script Editor icon).
  ICON="$(dirname "$0")/assets/claude.png"
  if [ -x "$NOTIFIER" ]; then
    "$NOTIFIER" -title "$TITLE" -message "$BODY" \
      -contentImage "$ICON" -group "claude-$SESSION_ID" >/dev/null 2>&1
  else
    osascript - "$TITLE" "$BODY" >/dev/null 2>&1 <<'EOF'
on run argv
  display notification (item 2 of argv) with title (item 1 of argv)
end run
EOF
  fi
fi

exit 0
