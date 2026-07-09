# Claude Code statusLine command — styled after Starship / Catppuccin Mocha
# Managed by nix (home/programs/claude-code). Runtime deps are provided by the wrapper.

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
branch=$(echo "$input" | jq -r '.worktree.branch // empty' 2>/dev/null)
git_worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty' 2>/dev/null)
repo=$(echo "$input" | jq -r '.workspace.repo | if . then .owner + "/" + .name else empty end' 2>/dev/null)
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
pr_number=$(echo "$input" | jq -r '.pr.number // empty')
pr_state=$(echo "$input" | jq -r '.pr.review_state // empty')
five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Catppuccin Mocha palette (ANSI 24-bit)
mauve='\033[38;2;203;166;247m'    # #cba6f7
blue='\033[38;2;137;180;250m'     # #89b4fa
green='\033[38;2;166;227;161m'    # #a6e3a1
yellow='\033[38;2;249;226;175m'   # #f9e2af
peach='\033[38;2;250;179;135m'    # #fab387
red='\033[38;2;243;139;168m'      # #f38ba8
sky='\033[38;2;137;220;235m'      # #89dceb
subtext='\033[38;2;166;173;200m'  # #a6adc8
teal='\033[38;2;148;226;213m'     # #94e2d5
maroon='\033[38;2;235;160;172m'   # #eba0ac
sapphire='\033[38;2;116;199;236m' # #74c7ec
reset='\033[0m'

# Shorten home directory
home=$(eval echo "~")
short_cwd="${cwd/#$home/\~}"

parts=()

# Directory
parts+=("${blue}${short_cwd}${reset}")

# Git branch (from worktree data if available, otherwise try git)
if [ -z "$branch" ] && [ -n "$cwd" ]; then
    branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
fi
if [ -n "$branch" ]; then
    git_part="${green} ${branch}${reset}"
    # Append git worktree name if present
    if [ -n "$git_worktree" ]; then
        git_part="${git_part}${subtext}(${git_worktree})${reset}"
    fi
    parts+=("$git_part")
fi

# PR badge
if [ -n "$pr_number" ]; then
    case "$pr_state" in
        approved)          pr_color="$green" ;;
        changes_requested) pr_color="$red" ;;
        draft)             pr_color="$subtext" ;;
        *)                 pr_color="$yellow" ;;
    esac
    parts+=("${pr_color}PR #${pr_number}${reset}")
fi

# Repo (owner/name)
if [ -n "$repo" ]; then
    parts+=("${sky}${repo}${reset}")
fi

# Model
if [ -n "$model" ]; then
    parts+=("${mauve}${model}${reset}")
fi

# Token usage — parsed from transcript JSONL (cumulative across all assistant turns)
# Input: sum of input + cache_read + cache_creation across all turns
# Output: sum of output_tokens across all assistant turns
abbrev_tokens() {
    local n=$1
    if [ "$n" -ge 1000000 ]; then
        printf '%.1fM' "$(echo "$n 1000000" | awk '{printf "%.1f", $1/$2}')"
    elif [ "$n" -ge 1000 ]; then
        printf '%.1fk' "$(echo "$n 1000" | awk '{printf "%.1f", $1/$2}')"
    else
        printf '%d' "$n"
    fi
}

if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    # Sum all output_tokens across assistant turns
    total_output=$(jq -r '
        select(.type == "assistant" and .message.usage.output_tokens != null)
        | .message.usage.output_tokens
    ' "$transcript_path" 2>/dev/null | awk '{s+=$1} END {print (s+0)}')

    # Cumulative input across all turns: input + cache_read + cache_creation
    total_input=$(jq -r '
        select(.type == "assistant" and .message.usage != null)
        | (.message.usage.input_tokens // 0)
          + (.message.usage.cache_read_input_tokens // 0)
          + (.message.usage.cache_creation_input_tokens // 0)
    ' "$transcript_path" 2>/dev/null | awk '{s+=$1} END {print (s+0)}')

    if [ -n "$total_output" ] && [ -n "$total_input" ] && { [ "$total_output" -gt 0 ] || [ "$total_input" -gt 0 ]; }; then
        in_fmt=$(abbrev_tokens "$total_input")
        out_fmt=$(abbrev_tokens "$total_output")
        parts+=("${teal}in:${in_fmt} out:${out_fmt}${reset}")
    fi
fi

# Context remaining
if [ -n "$remaining" ]; then
    remaining_int=$(printf '%.0f' "$remaining")
    if [ "$remaining_int" -le 10 ]; then
        ctx_color="$red"
    elif [ "$remaining_int" -le 25 ]; then
        ctx_color="$peach"
    else
        ctx_color="$subtext"
    fi
    parts+=("${ctx_color}ctx:${remaining_int}%${reset}")
fi

# Subscription rate limits (only present for claude.ai subscribers after first API response)
# Color progression: teal (normal) → yellow (elevated) → maroon (high) → red (critical)
# Deliberately distinct from ctx which uses subtext→peach→red
usage_color() {
    local pct=$1
    local pct_int
    pct_int=$(printf '%.0f' "$pct")
    if [ "$pct_int" -ge 90 ]; then
        printf '%s' "$red"
    elif [ "$pct_int" -ge 75 ]; then
        printf '%s' "$maroon"
    elif [ "$pct_int" -ge 55 ]; then
        printf '%s' "$yellow"
    else
        printf '%s' "$teal"
    fi
}

if [ -n "$five_hour" ]; then
    five_int=$(printf '%.0f' "$five_hour")
    five_color=$(usage_color "$five_hour")
    parts+=("${five_color}5h:${five_int}%${reset}")
fi

if [ -n "$seven_day" ]; then
    week_int=$(printf '%.0f' "$seven_day")
    week_color=$(usage_color "$seven_day")
    parts+=("${week_color}7d:${week_int}%${reset}")
fi

# Session cost — sapphire (#74c7ec), distinct from ctx (subtext/peach/red) and usage (teal/yellow/maroon/red)
# Omitted when absent, null, or zero
if [ -n "$cost" ]; then
    cost_nonzero=$(echo "$cost" | awk '$1+0 > 0 {print $1}')
    if [ -n "$cost_nonzero" ]; then
        cost_fmt=$(printf '$%.2f' "$cost_nonzero")
        parts+=("${sapphire}${cost_fmt}${reset}")
    fi
fi

# Join parts with separator
sep="${subtext} | ${reset}"
result=""
for part in "${parts[@]}"; do
    if [ -z "$result" ]; then
        result="$part"
    else
        result="${result}${sep}${part}"
    fi
done

printf "%b\n" "$result"
