#!/usr/bin/env bash
#
# toggle-focused-mute.sh
# Toggles mute on the PulseAudio/PipeWire sink-input(s) owned by the
# application that currently has focus — GNOME/Wayland version.
#
# Designed to be run from a GNOME custom keyboard shortcut, where the
# environment is minimal (no .bashrc, thin PATH, no terminal for stderr).
#
# Requires:
#   - GNOME Shell extension "Window Calls" (by ubaidraza)
#     gnome-extensions enable window-calls@domandoman.xyz
#   - gdbus, jq, pactl, notify-send (libnotify-bin)


# When launched by gnome-shell for a keybinding, XDG_RUNTIME_DIR and
# DBUS_SESSION_BUS_ADDRESS are normally still inherited from the user's
# systemd session — but if they're ever missing, gdbus/pactl calls fail
# silently. Set sane fallbacks explicitly:
: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
export XDG_RUNTIME_DIR
: "${DBUS_SESSION_BUS_ADDRESS:=unix:path=${XDG_RUNTIME_DIR}/bus}"
export DBUS_SESSION_BUS_ADDRESS

set -uo pipefail   # NOTE: no -e — we want to control flow and always notify

LOG="/tmp/toggle-focused-mute.log"
debug=0
[[ "${1:-}" == "-d" || "${1:-}" == "--debug" ]] && debug=1

log() { echo "$(date '+%H:%M:%S') $*" >>"$LOG"; }
notify() { command -v notify-send >/dev/null 2>&1 && notify-send -t 2500 "Mute Toggle" "$1"; }
fail() {
    log "ERROR: $1"
    notify "❌ $1"
    exit 1
}

log "---- run start (pid $$) ----"

command -v gdbus >/dev/null 2>&1 || fail "gdbus not found in PATH"
command -v jq    >/dev/null 2>&1 || fail "jq not found in PATH"
command -v pactl >/dev/null 2>&1 || fail "pactl not found in PATH"

# ---------------------------------------------------------------------------
# 1. Get info about the focused window via the "Window Calls" extension
# ---------------------------------------------------------------------------

raw=$(gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/Windows \
    --method org.gnome.Shell.Extensions.Windows.List 2>>"$LOG")
rc=$?
[[ $rc -ne 0 || -z "$raw" ]] && fail "gdbus call failed (rc=$rc). Is Window Calls enabled?"

json=$(echo "$raw" | sed -e "s/^(//" -e "s/,)$//" -e "s/^'//" -e "s/'$//")

win_pid=$(echo "$json" | jq -r '.[] | select(.focus==true) | .pid' | head -n1)
win_wmclass=$(echo "$json" | jq -r '.[] | select(.focus==true) | .wm_class' | head -n1)
win_title=$(echo "$json" | jq -r '.[] | select(.focus==true) | .title' | head -n1)

log "focused window: title=\"$win_title\" wm_class=\"$win_wmclass\" pid=$win_pid"

[[ -z "$win_pid" || "$win_pid" == "null" ]] && fail "couldn't determine focused window's PID"

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

log "candidate pids: ${!candidate_pids[*]}"

# ---------------------------------------------------------------------------
# 3. Pull all active sink-inputs as JSON
# ---------------------------------------------------------------------------

sinkfile="/tmp/.sinkinputs.$$"
pactl --format=json list sink-inputs >"$sinkfile" 2>>"$LOG"
[[ $? -ne 0 ]] && fail "pactl --format=json list sink-inputs failed"

if [[ $debug -eq 1 ]]; then
    jq -r '.[] | "  idx=\(.index) pid=\(.properties["application.process.id"] // "?") name=\(.properties["application.name"] // "?") binary=\(.properties["application.process.binary"] // "?") muted=\(.mute)"' \
        "$sinkfile" >>"$LOG"
fi

matched_indices=()

# --- Pass 1: match by PID ---
while IFS= read -r idx; do
    pid=$(jq -r --argjson i "$idx" '.[] | select(.index==$i) | .properties["application.process.id"] // empty' "$sinkfile")
    [[ -n "${candidate_pids[$pid]:-}" ]] && matched_indices+=("$idx")
done < <(jq -r '.[].index' "$sinkfile")

# --- Pass 2: fallback — match by app name / wm_class ---
if [[ ${#matched_indices[@]} -eq 0 && -n "$win_wmclass" && "$win_wmclass" != "null" ]]; then
    log "no PID match, falling back to name match against wm_class=\"$win_wmclass\""
    wmclass_lc=$(echo "$win_wmclass" | tr '[:upper:]' '[:lower:]')
    while IFS= read -r idx; do
        appname=$(jq -r --argjson i "$idx" '.[] | select(.index==$i) | (.properties["application.name"] // "")' "$sinkfile")
        binary=$(jq -r --argjson i "$idx" '.[] | select(.index==$i) | (.properties["application.process.binary"] // "")' "$sinkfile")
        appname_lc=$(echo "$appname" | tr '[:upper:]' '[:lower:]')
        binary_lc=$(echo "$binary" | tr '[:upper:]' '[:lower:]')
        if [[ "$appname_lc" == *"$wmclass_lc"* || "$wmclass_lc" == *"$appname_lc"* \
           || "$binary_lc"  == *"$wmclass_lc"* || "$wmclass_lc" == *"$binary_lc"* ]]; then
            matched_indices+=("$idx")
        fi
    done < <(jq -r '.[].index' "$sinkfile")

    distinct_binaries=$(for idx in "${matched_indices[@]}"; do
        jq -r --argjson i "$idx" '.[] | select(.index==$i) | (.properties["application.process.binary"] // .properties["application.name"] // "unknown")' "$sinkfile"
    done | sort -u)
    n_distinct=$(echo "$distinct_binaries" | grep -c . || true)
    if [[ "$n_distinct" -gt 1 ]]; then
        log "fallback matched multiple distinct apps: $distinct_binaries"
        rm -f "$sinkfile"
        fail "name fallback matched >1 app — refusing to guess (see $LOG)"
    fi
fi

if [[ ${#matched_indices[@]} -eq 0 ]]; then
    rm -f "$sinkfile"
    fail "no active audio stream matched \"$win_title\" (wm_class=$win_wmclass, pid=$win_pid)"
fi

log "matched sink-input indices: ${matched_indices[*]}"

# ---------------------------------------------------------------------------
# 4. Determine a single target mute state for ALL matched streams, apply it
# ---------------------------------------------------------------------------

any_unmuted=0
for idx in "${matched_indices[@]}"; do
    muted=$(jq -r --argjson i "$idx" '.[] | select(.index==$i) | .mute' "$sinkfile")
    log "  idx=$idx currently muted=$muted"
    [[ "$muted" == "false" ]] && any_unmuted=1
done
rm -f "$sinkfile"

target="1"
[[ $any_unmuted -eq 0 ]] && target="0"

log "target mute state: $target"

for idx in "${matched_indices[@]}"; do
    pactl set-sink-input-mute "$idx" "$target"
    log "set idx=$idx mute=$target"
done

if [[ "$target" == "1" ]]; then
    notify "🔇 Muted: $win_title"
else
    notify "🔊 Unmuted: $win_title"
fi

log "---- run end ----"
