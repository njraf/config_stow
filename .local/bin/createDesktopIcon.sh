#!/bin/bash

name=""
exec_path=""
icon=""

usage() {
	echo "Usage: $(basename $0) -n program-name -p program-path [-i icon-path]"
}

while getopts ':hn:p:i:' opt; do
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
		h)
			usage
			exit 1
			;;
		*)
			usage
			exit 1
			;;
	esac
done

if [ -z "$name"  ] || [ -z "$exec_path"  ]; then
	usage
	exit 1
fi

desktop_file="$HOME/.local/share/applications/$name.desktop"
cat <<- EOF > $desktop_file
[Desktop Entry]
Type=Application
Name=$name
Exec=$exec_path
Terminal=false
EOF
if [ -n "$icon"  ]; then
	echo "Icon=$icon" >> "$desktop_file"
fi

