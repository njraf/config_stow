#!/bin/bash

winid=$(xdotool getwindowfocus)
winpid=$(xdotool getwindowpid $winid)

lastSinkInID=0

while IFS=$'\n' read -r line; do
	if echo "$line" | grep -q "Sink Input"; then
		lastSinkInID=$(echo $line | cut -d "#" -f 2)
	fi

	if echo "$line" | grep -q "application.process.id"; then
		linepid="$(echo $line | cut -d "\"" -f 2)"

		if  (( $linepid == $winpid )) ; then
			echo "Sink input ID: $lastSinkInID"
			pactl set-sink-input-mute $lastSinkInID toggle
		fi
	fi
done < <(pactl list sink-inputs)

