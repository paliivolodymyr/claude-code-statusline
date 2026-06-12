# Installation instructions

> These steps are written so Claude Code can follow them automatically.
> Just ask Claude Code:
>
> *"Clone https://github.com/paliivolodymyr/claude-code-statusline to `~/.claude/statusline/` and configure it as my status line by following its INSTALL.md."*

## Automatic (recommended)

```bash
git clone https://github.com/paliivolodymyr/claude-code-statusline ~/.claude/statusline
~/.claude/statusline/install.sh
```

`install.sh` makes the script executable, backs up `~/.claude/settings.json`, and merges in:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline/statusline.sh",
    "padding": 0
  }
}
```

Restart Claude Code afterwards.

## Manual

1. Verify requirements: `jq` and `git` must be in `PATH`.
   - macOS: `brew install jq`
   - Linux: `sudo apt install jq`
2. Copy `statusline.sh` anywhere (conventionally `~/.claude/statusline/statusline.sh`) and run `chmod +x` on it.
3. Add the `statusLine` block above to `~/.claude/settings.json`, pointing `command` at the script's absolute path.
4. Restart Claude Code.

## Steps for Claude Code to follow

1. Run `git clone https://github.com/paliivolodymyr/claude-code-statusline ~/.claude/statusline` (use `$CLAUDE_CONFIG_DIR/statusline` if `CLAUDE_CONFIG_DIR` is set).
2. Run `chmod +x ~/.claude/statusline/statusline.sh ~/.claude/statusline/install.sh`.
3. Read `~/.claude/settings.json`. If it exists, preserve all existing keys. Add or replace the `statusLine` key with the JSON block shown above (use the absolute path, not `~`).
4. Verify by running: `~/.claude/statusline/statusline.sh < ~/.claude/statusline/test/full.json` — it should print 3 colored lines.
5. Tell the user to restart Claude Code.

## Updating

```bash
git -C ~/.claude/statusline pull
```

No settings changes needed — the script path stays the same.

## Uninstalling

Remove the `statusLine` key from `~/.claude/settings.json` (or run `/statusline remove it` inside Claude Code), then delete `~/.claude/statusline/`.

## Troubleshooting

- **Nothing appears**: run the verify command from step 4 above; ensure the script is executable and `jq` is installed.
- **`5h – | Weekly –`**: rate limits only appear for Claude Pro/Max subscribers, and only after the first API response in a session.
- **Garbled characters**: your terminal must support 24-bit ANSI colors (iTerm2, Kitty, WezTerm, Windows Terminal, most modern terminals do).
