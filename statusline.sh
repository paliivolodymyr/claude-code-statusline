#!/bin/bash
# ============================================================================
# Claude Code Status Line
# https://github.com/paliivolodymyr/claude-code-statusline
#
# Multi-line status line for Claude Code:
#   Line 1: [Model] effort | context bar (used/total) | project git:(branch) +/-
#   Line 2: 5h limit bar @ reset | Weekly limit bar @ reset
#   Line 3: session cost · duration · thinking · output style
#
# All data comes from the JSON Claude Code pipes to stdin — no API calls,
# no OAuth tokens, no network. Requires: jq, git.
# ============================================================================

set -f # disable globbing

input=$(cat)
[ -z "$input" ] && { printf "Claude"; exit 0; }

command -v jq >/dev/null 2>&1 || { printf "statusline: jq not found (brew install jq)"; exit 0; }

# ----------------------------------------------------------------------------
# Colors (24-bit ANSI)
# ----------------------------------------------------------------------------
blue='\033[38;2;102;178;255m'
cyan='\033[38;2;86;182;194m'
green='\033[38;2;152;195;121m'
yellow='\033[38;2;229;192;123m'
orange='\033[38;2;255;165;89m'
red='\033[38;2;224;108;117m'
purple='\033[38;2;198;160;246m'
white='\033[38;2;220;220;220m'
dim='\033[2m'
reset='\033[0m'

sep=" ${dim}|${reset} "

# Color by usage percentage: green <50, yellow <70, orange <90, red >=90
usage_color() {
    local pct=$1
    if   [ "$pct" -ge 90 ]; then echo "$red"
    elif [ "$pct" -ge 70 ]; then echo "$orange"
    elif [ "$pct" -ge 50 ]; then echo "$yellow"
    else echo "$green"
    fi
}

# Render a colored progress bar: bar <pct> <width>
bar() {
    local pct=$1 width=${2:-10}
    [ "$pct" -gt 100 ] && pct=100
    [ "$pct" -lt 0 ] && pct=0
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    local color; color=$(usage_color "$pct")
    local b=""
    local i
    for (( i=0; i<filled; i++ )); do b+="█"; done
    for (( i=0; i<empty;  i++ )); do b+="░"; done
    printf '%b%s%b' "$color" "$b" "$reset"
}

# Format token counts: 1234 -> 1k, 1500000 -> 1.5m
fmt_tokens() {
    local n=$1
    if [ "$n" -ge 1000000 ]; then
        awk "BEGIN {v=$n/1000000; printf (v==int(v)?\"%dm\":\"%.1fm\"), v}"
    elif [ "$n" -ge 1000 ]; then
        awk "BEGIN {printf \"%.0fk\", $n/1000}"
    else
        printf '%d' "$n"
    fi
}

# Cross-platform epoch -> formatted local time: fmt_epoch <epoch> <format>
fmt_epoch() {
    date -r "$1" +"$2" 2>/dev/null || date -d "@$1" +"$2" 2>/dev/null
}

# Duration ms -> "1h 54m" / "12m" / "45s"
fmt_duration() {
    local ms=$1
    local s=$(( ms / 1000 ))
    local h=$(( s / 3600 ))
    local m=$(( (s % 3600) / 60 ))
    if   [ "$h" -gt 0 ]; then printf '%dh %dm' "$h" "$m"
    elif [ "$m" -gt 0 ]; then printf '%dm' "$m"
    else printf '%ds' "$s"
    fi
}

# ----------------------------------------------------------------------------
# Extract everything in a single jq call (keeps the script fast).
# One value per line; mapfile preserves empty lines, unlike tab-separated read.
# ----------------------------------------------------------------------------
mapfile -t F < <(echo "$input" | jq -r '
    (.model.display_name // "Claude"),
    (.effort.level // ""),
    (.workspace.current_dir // .cwd // ""),
    (.context_window.context_window_size // 200000),
    (.context_window.current_usage.input_tokens // 0),
    (.context_window.current_usage.cache_creation_input_tokens // 0),
    (.context_window.current_usage.cache_read_input_tokens // 0),
    (.context_window.used_percentage // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.seven_day.resets_at // ""),
    (.cost.total_cost_usd // 0),
    (.cost.total_duration_ms // 0),
    (.thinking.enabled // false),
    (.output_style.name // "default")
' 2>/dev/null)

model=${F[0]:-Claude}; effort=${F[1]}; cwd=${F[2]}
ctx_size=${F[3]}; in_tok=${F[4]}; cache_create=${F[5]}; cache_read=${F[6]}
used_pct=${F[7]}; fh_pct=${F[8]}; fh_reset=${F[9]}; sd_pct=${F[10]}; sd_reset=${F[11]}
cost=${F[12]}; dur_ms=${F[13]}; thinking=${F[14]}; out_style=${F[15]}

# Sanitize values that are used in arithmetic (guards against null/garbage)
int_or() { case "$1" in (''|*[!0-9]*) echo "$2" ;; (*) echo "$1" ;; esac; }
ctx_size=$(int_or "$ctx_size" 200000)
in_tok=$(int_or "$in_tok" 0)
cache_create=$(int_or "$cache_create" 0)
cache_read=$(int_or "$cache_read" 0)
dur_ms=$(int_or "$dur_ms" 0)
case "$cost" in (''|*[!0-9.]*) cost=0 ;; esac

# ============================================================================
# LINE 1: [Model] effort | context | project git:(branch) +/-
# ============================================================================
line1=""

# --- Model + effort ---
line1+="${blue}[${model}]${reset}"
if [ -n "$effort" ]; then
    case "$effort" in
        low)    line1+=" ${dim}low${reset}" ;;
        medium) line1+=" ${yellow}med${reset}" ;;
        high)   line1+=" ${green}high${reset}" ;;
        xhigh)  line1+=" ${purple}xhigh${reset}" ;;
        max)    line1+=" ${red}max${reset}" ;;
        *)      line1+=" ${white}${effort}${reset}" ;;
    esac
fi

# --- Context window ---
current=$(( in_tok + cache_create + cache_read ))
[ "$ctx_size" -le 0 ] 2>/dev/null && ctx_size=200000
if [ -n "$used_pct" ]; then
    ctx_pct=$(int_or "${used_pct%%.*}" 0)
else
    ctx_pct=$(( current * 100 / ctx_size ))
fi
line1+="${sep}$(bar "$ctx_pct") $(usage_color "$ctx_pct")${ctx_pct}%${reset} ${dim}($(fmt_tokens $current)/$(fmt_tokens "$ctx_size"))${reset}"

# --- Project + git branch + changes ---
if [ -n "$cwd" ]; then
    project="${cwd##*/}"
    line1+="${sep}${cyan}${project}${reset}"
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        # Dirty marker
        dirty=""
        [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null | head -1)" ] && dirty="${yellow}*${reset}"
        line1+=" ${dim}git:(${reset}${purple}${branch}${reset}${dirty}${dim})${reset}"
        # Lines added/removed (staged + unstaged vs HEAD)
        changes=$(git -C "$cwd" diff HEAD --numstat 2>/dev/null \
            | awk '{a+=$1; d+=$2} END {if (a+d>0) printf "%d %d", a, d}')
        if [ -n "$changes" ]; then
            added=${changes%% *}
            removed=${changes##* }
            line1+=" ${green}+${added}${reset} ${red}-${removed}${reset}"
        fi
    fi
fi

# ============================================================================
# LINE 2: 5h limit | Weekly limit (with reset times)
# ============================================================================
line2=""

if [ -n "$fh_pct" ] || [ -n "$sd_pct" ]; then
    if [ -n "$fh_pct" ]; then
        p=$(int_or "${fh_pct%%.*}" 0)
        line2+="${white}5h${reset} $(bar "$p") $(usage_color "$p")${p}%${reset}"
        if [ -n "$fh_reset" ] && [ "$fh_reset" != "null" ]; then
            t=$(fmt_epoch "$fh_reset" "%H:%M")
            [ -n "$t" ] && line2+=" ${dim}↻ ${t}${reset}"
        fi
    fi
    if [ -n "$sd_pct" ]; then
        [ -n "$line2" ] && line2+="$sep"
        p=$(int_or "${sd_pct%%.*}" 0)
        line2+="${white}Weekly${reset} $(bar "$p") $(usage_color "$p")${p}%${reset}"
        if [ -n "$sd_reset" ] && [ "$sd_reset" != "null" ]; then
            t=$(fmt_epoch "$sd_reset" "%a %H:%M")
            [ -n "$t" ] && line2+=" ${dim}↻ ${t}${reset}"
        fi
    fi
else
    # rate_limits absent until the first API response (and for non-subscribers)
    line2+="${white}5h${reset} ${dim}–${reset}${sep}${white}Weekly${reset} ${dim}–${reset}"
fi

# ============================================================================
# LINE 3: cost · duration · thinking · output style (omitted when empty)
# ============================================================================
line3=""
parts=()

is_nonzero_cost=$(awk "BEGIN {print ($cost > 0) ? 1 : 0}")
[ "$is_nonzero_cost" = "1" ] && parts+=("${green}\$$(LC_NUMERIC=C printf '%.2f' "$cost")${reset}")

[ "$dur_ms" -gt 0 ] 2>/dev/null && parts+=("${white}⏱ $(fmt_duration "$dur_ms")${reset}")

[ "$thinking" = "true" ] && parts+=("${purple}✦ thinking${reset}")

[ -n "$out_style" ] && [ "$out_style" != "default" ] && parts+=("${cyan}style: ${out_style}${reset}")

if [ ${#parts[@]} -gt 0 ]; then
    for part in "${parts[@]}"; do
        [ -n "$line3" ] && line3+=" ${dim}·${reset} "
        line3+="$part"
    done
fi

# ----------------------------------------------------------------------------
# Output
# ----------------------------------------------------------------------------
printf '%b\n' "$line1"
printf '%b\n' "$line2"
[ -n "$line3" ] && printf '%b\n' "$line3"

exit 0
