#!/bin/bash

# Add the following line to keyboard shortcuts:
# gnome-terminal -- sudo bash -c '/home/nick/.local/bin/update_and_shutdown.sh' 

dnf -y upgrade && sleep 2
shutdown -h now
while [ $? -ne 0 ]; do
	echo "Could not shutdown. Will try again."
	sleep 5
	shutdown -h now
done

