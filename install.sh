#!/bin/bash
# ============================================================================
# Installer for ClaudeStatusLine
# Configures statusline.sh as the Claude Code status line by updating
# ~/.claude/settings.json (a backup is created first).
#
# Usage:  ./install.sh
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
STATUSLINE="$SCRIPT_DIR/statusline.sh"

# --- Checks -----------------------------------------------------------------
command -v jq >/dev/null 2>&1 || {
    echo "Error: jq is required. Install it first:"
    echo "  macOS:  brew install jq"
    echo "  Linux:  sudo apt install jq  (or your distro's equivalent)"
    exit 1
}
[ -f "$STATUSLINE" ] || { echo "Error: statusline.sh not found next to install.sh"; exit 1; }

chmod +x "$STATUSLINE"
mkdir -p "$CLAUDE_DIR"

# --- Merge statusLine config into settings.json ------------------------------
if [ -f "$SETTINGS" ]; then
    cp "$SETTINGS" "$SETTINGS.bak"
    echo "Backed up existing settings to $SETTINGS.bak"
else
    echo '{}' > "$SETTINGS"
fi

tmp=$(mktemp)
jq --arg cmd "$STATUSLINE" \
   '.statusLine = {type: "command", command: $cmd, padding: 0}' \
   "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"

echo "Status line installed:"
echo "  script:   $STATUSLINE"
echo "  settings: $SETTINGS"
echo ""
echo "Preview with mock data:"
"$STATUSLINE" < "$SCRIPT_DIR/test/full.json" || true
echo ""
echo "Restart Claude Code (or send a message) to see it live."
