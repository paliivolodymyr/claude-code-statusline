# Claude Status Line

A multi-line custom status line for [Claude Code](https://claude.com/claude-code). All data comes from the JSON Claude Code pipes to the script on stdin — **no API calls, no OAuth tokens, no network access, zero extra token usage**.

```
[Sonnet 4.6] high | ██░░░░░░░░ 24% (50k/200k) | EarnIt git:(kan-154-auth-form-ux-polish*) +12 -4
5h ██░░░░░░░░ 25% ↻ 14:30 | Weekly ░░░░░░░░░░ 3% ↻ Thu 10:00
$1.23 · ⏱ 1h 54m · ✦ thinking · style: explanatory
```

## What it shows

| Line | Segment | Description |
|------|---------|-------------|
| 1 | **Model** | Current model display name |
| 1 | **Effort** | Reasoning effort level, color-coded (low / med / high / xhigh / max) |
| 1 | **Context** | Progress bar, % used, used/total tokens |
| 1 | **Project & git** | Folder name, branch, dirty marker `*`, lines `+added -removed` |
| 2 | **5h limit** | 5-hour rate limit bar, % used, reset time (`↻ HH:MM`) |
| 2 | **Weekly limit** | 7-day rate limit bar, % used, reset day+time (`↻ Thu 10:00`) |
| 3 | **Cost** | Estimated session cost in USD (hidden when $0) |
| 3 | **Duration** | Session wall-clock time |
| 3 | **Thinking** | `✦ thinking` when extended thinking is enabled |
| 3 | **Style** | Output style name (hidden when `default`) |

Usage bars are color-coded: green (<50%) → yellow (≥50%) → orange (≥70%) → red (≥90%). Line 3 is omitted entirely when it has nothing to show.

## Installation

The easiest way — ask Claude Code:

> Clone https://github.com/paliivolodymyr/claude-code-statusline to `~/.claude/statusline/` and configure it as my status line by following its INSTALL.md.

Or do it yourself:

```bash
git clone https://github.com/paliivolodymyr/claude-code-statusline ~/.claude/statusline
~/.claude/statusline/install.sh
```

Then restart Claude Code. See [INSTALL.md](INSTALL.md) for manual setup, updating, and troubleshooting.

## Requirements

- Claude Code v2.x (rate limit data requires a Claude Pro/Max subscription)
- `jq` and `git` in `PATH`
- A terminal with 24-bit ANSI color support
- macOS or Linux (Bash)

## Testing

Run the script against the bundled fixtures:

```bash
./test/test.sh
```

Or pipe any mock JSON manually:

```bash
./statusline.sh < test/full.json
```

## Customizing

Everything lives in one file, `statusline.sh`:

- **Colors**: edit the ANSI variables at the top.
- **Bar width**: change the default `width` in the `bar()` function (default 10).
- **Thresholds**: edit `usage_color()` (50 / 70 / 90).
- **Segments**: each segment is a clearly-marked block — delete or reorder freely.

All available stdin fields are documented in the [Claude Code status line docs](https://code.claude.com/docs/en/statusline#available-data).

## License

MIT
