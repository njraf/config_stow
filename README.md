# Instructions - manual setup
# ============
# 1. Clone the repo in the home directory
# 1a. optionally run 'dot-local/bin/initialize_environment.sh' instead of the remaining steps
# 2. install stow
# 3. cd config_stow
# 4. stow --dotfiles --adopt .
# 4a. CAUTION: This replaces all instances of stowed files on the system with symlinks. This is potentially harmful for .bashrc, so make a backup.
# 4b. Using --adopt may result in changes to the git repo and possible conflicts may arise.
# 
# NOTES
# =====
# This readme will not be symlinked to the system.


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

if [[ "$(whoami)" == "root" ]]; then
	printError "This script must not be run as root"
	exit 1
fi

# run this script from HOME
pushd ~

# determine which package manager the system uses and create an install string
echo "Checking package manager"
INSTALL_PREFIX=""
if which dnf &>/dev/null; then
    INSTALL_PREFIX="dnf -y install"
elif which zypper &>/dev/null; then
    INSTALL_PREFIX="zypper install -y"
elif which apt &>/dev/null; then
    INSTALL_PREFIX="apt -y install"
fi

if [[ -z "$INSTALL_PREFIX" ]]; then
    printError "Could not determine which package manager to use"
    exit 1
fi

# check for software and install it if necessary
echo "Downloading software"
SW_TO_DOWNLOAD=("stow" "gh" "nvim" "fastfetch" "steam" "thunderbird" "htop")
for software in "${SW_TO_DOWNLOAD[@]}"; do
    if ! which "$software" &>/dev/null; then
        eval sudo $INSTALL_PREFIX "$software"
    fi
done

# install flatpaks
echo "Downloading flatpaks"
FP_TO_DOWNLOAD=("com.spotify.Client")
for software in "${FP_TO_DOWNLOAD[@]}"; do
    flatpak install "$software"
done

# install lazyvim
#NOTE: should be done before cloning config_stow so that changes from the stow can be applied
echo "Installing LazyVim"
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# install dashlane from brew
if ! which brew &> /dev/null; then
	bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
	brew install -y dashlane/tap/dashlane-cli
fi

# check whether we are logged in to dashlane
function loggedInToDashlane() {
	if [[ "$(dcli status | cut -d ':' -f 2 | head -n 1)" =~ "no" ]]; then
		return 0
	else
		return 1
	fi
}

# log in to dashlane
if ! loggedInToDashlane; then
	dcli sync
fi

# log in to gh
if which dcli &> /dev/null && which gh &> /dev/null && loggedInToDashlane; then
	export GH_TOKEN="$(dcli note github-the-token)"
	gh auth login -cp https -h GitHub.com # should automatically get the token from GH_TOKEN; not sure about user name
fi

# clear sensitive fields
export GH_TOKEN=""
dcli lock

# clone repo and install dotfiles
if [[ "$(basename $PWD)" != "config_stow" ]]; then
	if ! gh repo clone config_stow; then
		printError "Could not clone config_stow. "
		popd
		exit 1
	fi
	cd config_stow
fi
echo "Stowing"
stow --dotfiles --adopt .
git stash --include-untracked
cd ~
mkdir -p .vim/undo

# determine the default terminal
echo "Checking default terminal"
DEFAULT_TERMINAL=""
NEW_WINDOW=""
if which gnome-terminal &>/dev/null; then
    DEFAULT_TERMINAL="gnome-terminal"
    NEW_WINDOW="--window"
elif which ptyxis &>/dev/null; then
    DEFAULT_TERMINAL="ptyxis"
#NEW_WINDOW="--new-window"
else
    printWarning "Could not determine the default terminal. Not setting custom keybind to open terminal or update_and_shutdown."
fi

# gnome custom keyboard shortcuts
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
    echo "Setting custom keyboard shortcuts"
    gsettings set "$KEYBIND_PREFIX"'0/' name "'Toggle Mute'"
    gsettings set "$KEYBIND_PREFIX"'0/' binding "'<Primary><Alt>m'"
    gsettings set "$KEYBIND_PREFIX"'0/' command "'bash $HOME/.local/bin/toggle_mute_focused_window.sh'"

    if [[ -n "$DEFAULT_TERMINAL" ]]; then
        gsettings set "$KEYBIND_PREFIX"'1/' name "'Update and Shutdown'"
	gsettings set "$KEYBIND_PREFIX"'1/' binding "'<Primary><Alt><Super>x'"
	gsettings set "$KEYBIND_PREFIX"'1/' command "'$DEFAULT_TERMINAL $NEW_WINDOW -- $HOME/.local/bin/update_and_shutdown.sh'"

        gsettings set "$KEYBIND_PREFIX"'2/' name "'New Terminal'"
        gsettings set "$KEYBIND_PREFIX"'2/' binding "'<Super>t'"
        gsettings set "$KEYBIND_PREFIX"'2/' command "'$DEFAULT_TERMINAL $NEW_WINDOW'"
    fi
else
    printWarning "Could not determine the Desktop Environment. Not setting keyboard shortcuts."
fi

source ~/.bashrc

popd
echo "DONE"
