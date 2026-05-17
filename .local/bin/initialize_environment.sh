#!/bin/bash
# Used to set up the environment on a new install

# prints warnings in yellow text
function printWarning() {
	echo $'\e[93m'"$@"$'\e[0m'
}

# prints errors in red text
function printError() {
	echo $'\e[91m'"$@"$'\e[0m'
}

# determine which package manager the system uses and create an install string
echo "Checking package manager"
INSTALL_PREFIX=""
if which dnf &> /dev/null; then
	INSTALL_PREFIX="dnf -y install"
elif which zypper &> /dev/null; then
	INSTALL_PREFIX="zypper install -y"
elif which apt &> /dev/null; then
	INSTALL_PREFIX="apt -y install"
fi

if [[ -z "$INSTALL_PREFIX" ]]; then
	printError "Could not determine which package manager to use"
	exit 1
fi

# check for software and install it if necessary
echo "Downloading software"
SW_TO_DOWNLOAD=("stow" "gh")
for software in "${SW_TO_DOWNLOAD[@]}"; do
	if ! which "$software" &> /dev/null; then
		eval sudo $INSTALL_PREFIX "$software"
	fi
done

# install flatpaks
echo "Downloading flatpaks"
FP_TO_DOWNLOAD=("com.spotify.Client")
for software in "${FP_TO_DOWNLOAD[@]}"; do
	flatpak install "$software"
done

echo "Stowing"
stow --adopt .
git reset --hard


# determine the default terminal
echo "Checking default terminal"
DEFAULT_TERMINAL=""
if which gnome-terminal &> /dev/null; then
	DEFAULT_TERMINAL="gnome-terminal"
elif which ptyxis &> /dev/null; then
	DEFAULT_TERMINAL="ptyxis"
else
	printWarning "Could not determine the default terminal. Not setting custom keybind to open terminal."
fi

# gnome custom keyboard shortcuts
#TODO: check that gnome is the current DE
echo "Setting custom keyboard shortcuts"
SCHEMA="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"
GPATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom"
SCHEMA_LIST_STR="['"$GPATH"0/', '"$GPATH"1/'"
if [[ -n "$DEFAULT_TERMINAL" ]]; then
	SCHEMA_LIST_STR+=", '"$GPATH"2/'"
fi
SCHEMA_LIST_STR+="]"

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$SCHEMA_LIST_STR"
KEYBIND_PREFIX="$SCHEMA:$GPATH"
if [[ "GNOME" == "$XDG_SESSION_DESKTOP" ]] || [[ "gnome" == "$XDG_SESSION_DESKTOP" ]]; then
	gsettings set "$KEYBIND_PREFIX"'0/' name "'Toggle Mute'"
	gsettings set "$KEYBIND_PREFIX"'0/' binding "'<Primary><Alt>m'"
	gsettings set "$KEYBIND_PREFIX"'0/' command "'bash $HOME/.local/bin/toggle_mute_focused_window.sh'"

	gsettings set "$KEYBIND_PREFIX"'1/' name "'Update and Shutdown'"
	gsettings set "$KEYBIND_PREFIX"'1/' binding "'<Primary><Alt><Super>x'"
	gsettings set "$KEYBIND_PREFIX"'1/' command "'$DEFAULT_TERMINAL -- $HOME/.local/bin/update_and_shutdown.sh'"
	if [[ -n "$DEFAULT_TERMINAL" ]]; then
		gsettings set "$KEYBIND_PREFIX"'2/' name "'New Terminal'"
		gsettings set "$KEYBIND_PREFIX"'2/' binding "'<Super>t'"
		gsettings set "$KEYBIND_PREFIX"'2/' command "'$DEFAULT_TERMINAL'"
	fi
else
	printWarning "Could not determine the Desktop Environment. Not setting keyboard shortcuts."
fi
