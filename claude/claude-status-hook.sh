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

if [ "$STATUS" = "end" ]; then
  rm -f "$DIR/$SESSION_ID"
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
printf '%s\t%s\t%s\n' "$WORKSPACE" "$STATUS" "$(date +%s)" > "$DIR/$SESSION_ID"
exit 0
