#!/bin/bash

# Add the following line to keyboard shortcuts:
# gnome-terminal -- /home/nick/.local/bin/update_and_shutdown.sh

if which dnf &> /dev/null; then
	sudo dnf -y upgrade
elif which zypper &> /dev/null; then
	sudo zypper update -y
fi

sleep 2

sudo shutdown -h now
while [ $? -ne 0 ]; do
	echo "Could not shutdown. Will try again."
	sleep 5
	sudo shutdown -h now
done

