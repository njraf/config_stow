#!/usr/bin/env bash
#
# toggle-focused-mute.sh
# Toggles mute on the PulseAudio/PipeWire sink-input(s) owned by the
# application that currently has focus — GNOME/Wayland version.
#
# Requires:
#   - GNOME Shell extension "Window Calls" (by ubaidraza)
#     https://extensions.gnome.org/extension/4724/window-calls/
#     gnome-extensions enable window-calls@domandoman.xyz
#   - gdbus, jq, pactl
#
# Usage:
#   ./toggle-focused-mute.sh          normal run
#   ./toggle-focused-mute.sh -d       debug: print everything, don't toggle

set -euo pipefail

debug=0
[[ "${1:-}" == "-d" || "${1:-}" == "--debug" ]] && debug=1

die() { echo "Error: $*" &>> ~/mute-toggle-log; exit 1; }
dbg() { [[ $debug -eq 1 ]] && echo "[debug] $*" &>> ~/mute-toggle-log || true; }

command -v gdbus >/dev/null 2>&1 || die "gdbus not found (should ship with glib2)"
command -v jq    >/dev/null 2>&1 || die "jq not found (try: sudo apt install jq)"
command -v pactl >/dev/null 2>&1 || die "pactl not found (try: sudo apt install pulseaudio-utils)"

# ---------------------------------------------------------------------------
# 1. Get info about the focused window via the "Window Calls" extension
# ---------------------------------------------------------------------------

raw=$(gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/Windows \
    --method org.gnome.Shell.Extensions.Windows.List 2>/dev/null) \
    || die "couldn't call the Window Calls D-Bus method. Is the extension enabled? (gnome-extensions enable window-calls@domandoman.xyz)"

json=$(echo "$raw" | sed -e "s/^(//" -e "s/,)$//" -e "s/^'//" -e "s/'$//")

win_pid=$(echo "$json" | jq -r '.[] | select(.focus==true) | .pid' | head -n1)
win_wmclass=$(echo "$json" | jq -r '.[] | select(.focus==true) | .wm_class' | head -n1)
win_title=$(echo "$json" | jq -r '.[] | select(.focus==true) | .title' | head -n1)

dbg "focused window: title=\"$win_title\" wm_class=\"$win_wmclass\" pid=$win_pid"

[[ -z "$win_pid" || "$win_pid" == "null" ]] && die "couldn't determine focused window's PID from Window Calls output"

# ---------------------------------------------------------------------------
# 2. Build the set of PIDs related to that window (ancestors + descendants)
# ---------------------------------------------------------------------------

declare -A candidate_pids

collect_descendants() {
    local pid=$1
    candidate_pids[$pid]=1
    local child
    for child in $(pgrep -P "$pid" 2>/dev/null || true); do
        collect_descendants "$child"
    done
}

collect_ancestors() {
    local pid=$1
    while [[ -n "$pid" && "$pid" != "0" && "$pid" != "1" ]]; do
        candidate_pids[$pid]=1
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    done
}

collect_descendants "$win_pid"
collect_ancestors "$win_pid"

dbg "candidate pids (ancestors+descendants of $win_pid): ${!candidate_pids[*]}"

# ---------------------------------------------------------------------------
# 3. Pull all active sink-inputs as JSON
# ---------------------------------------------------------------------------

pactl --format=json list sink-inputs >/tmp/.sinkinputs.$$ 2>/dev/null \
    || die "pactl --format=json not supported by your pactl version"

if [[ $debug -eq 1 ]]; then
    echo "[debug] active sink-inputs:" >&2
    jq -r '.[] | "  idx=\(.index) pid=\(.properties["application.process.id"] // "?") name=\(.properties["application.name"] // "?") binary=\(.properties["application.process.binary"] // "?")"' \
        /tmp/.sinkinputs.$$ >&2
fi

matched_indices=()

# --- Pass 1: match by PID (ancestors/descendants) ---
while IFS= read -r idx; do
    pid=$(jq -r --argjson i "$idx" '.[] | select(.index==$i) | .properties["application.process.id"] // empty' /tmp/.sinkinputs.$$)
    [[ -n "${candidate_pids[$pid]:-}" ]] && matched_indices+=("$idx")
done < <(jq -r '.[].index' /tmp/.sinkinputs.$$)

# --- Pass 2: fallback — match by app name / wm_class (case-insensitive substring) ---
if [[ ${#matched_indices[@]} -eq 0 && -n "$win_wmclass" && "$win_wmclass" != "null" ]]; then
    dbg "no PID match, falling back to name match against wm_class=\"$win_wmclass\""
    wmclass_lc=$(echo "$win_wmclass" | tr '[:upper:]' '[:lower:]')
    while IFS= read -r idx; do
        appname=$(jq -r --argjson i "$idx" '.[] | select(.index==$i) | (.properties["application.name"] // "") ' /tmp/.sinkinputs.$$)
        binary=$(jq -r --argjson i "$idx" '.[] | select(.index==$i) | (.properties["application.process.binary"] // "")' /tmp/.sinkinputs.$$)
        appname_lc=$(echo "$appname" | tr '[:upper:]' '[:lower:]')
        binary_lc=$(echo "$binary" | tr '[:upper:]' '[:lower:]')
        if [[ "$appname_lc" == *"$wmclass_lc"* || "$wmclass_lc" == *"$appname_lc"* \
           || "$binary_lc"  == *"$wmclass_lc"* || "$wmclass_lc" == *"$binary_lc"* ]]; then
            matched_indices+=("$idx")
        fi
    done < <(jq -r '.[].index' /tmp/.sinkinputs.$$)
fi

rm -f /tmp/.sinkinputs.$$

if [[ ${#matched_indices[@]} -eq 0 ]]; then
    echo "No active audio stream matched window \"$win_title\" (wm_class=$win_wmclass, pid=$win_pid)." >&2
    echo "Re-run with -d to see candidate PIDs and available sink-inputs, then match manually with:" >&2
    echo "  pactl list sink-inputs" >&2
    exit 1
fi

dbg "matched sink-input indices: ${matched_indices[*]}"

# ---------------------------------------------------------------------------
# 4. Toggle mute on every matched sink-input
# ---------------------------------------------------------------------------

for idx in "${matched_indices[@]}"; do
    pactl set-sink-input-mute "$idx" toggle
    echo "Toggled mute on sink-input #$idx"
done
