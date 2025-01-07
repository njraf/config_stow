#!/bin/bash

# need:
# custom program name -n
# exec path -e
# icon path -i

name=""
exec_path=""
icon=""

while getopts 'n:p:i:' opt; do
	case "$opt" in
		n)
			name="$OPTARG"
			;;
		p)
			exec_path="$OPTARG"
			;;
		i)
			icon="$OPTARG"
			;;
		*)
			echo "Usage: $(basename $0) -n program-name -p program-path [-i icon-path]"
			exit
			;;
	esac
done

if [ -z "$name"  ] || [ -z "$exec_path"  ]; then
	echo "empty name or exec path"
	exit
fi

desktop_file="$HOME/.local/share/applications/$name.desktop"
touch "$desktop_file"
echo "[Desktop Entry]" > "$desktop_file"
echo "Type=Application" >> "$desktop_file"
echo "Name=$name" >> "$desktop_file"
echo "Exec=$exec_path">> "$desktop_file"
if [ -n "$icon"  ]; then
	echo "Icon=$icon" >> "$desktop_file"
fi
echo "Terminal=false" >> "$desktop_file"

chmod +x "$desktop_file"
