# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# aliases
alias grep="grep --color=always"
alias less="less -R"

## Colored man pages and less
export MANPAGER='less' # redundant since man uses less as a pager by default
export GROFF_NO_SGR=1  # required to display color on some terminals
export LESS_TERMCAP_mb=$'\e[1;91m' # red blinking text
export LESS_TERMCAP_md=$'\e[1;91m' # red bold text
export LESS_TERMCAP_me=$'\e[0m' # reset/end all special formatting
export LESS_TERMCAP_ue=$'\e[0m' # reset/end underline mode
export LESS_TERMCAP_us=$'\e[4;1;92m' # green underline
export LESS_TERMCAP_mr=$'\e[7m' # "reverse" video
export LESS_TERMCAP_mh=$'\e[2m' # dims text
# super and subscripts below, rarely used
export LESS_TERMCAP_ZN=$'\e[74m'
export LESS_TERMCAP_ZV=$'\e[75m'
export LESS_TERMCAP_ZO=$'\e[73m'
export LESS_TERMCAP_ZW=$'\e[75m'

# tput version in case the terminal does not support ANSI escape codes
#export LESS_TERMCAP_mb=$(tput bold; tput setaf 1)
#export LESS_TERMCAP_md=$(tput bold; tput setaf 1)
#export LESS_TERMCAP_me=$(tput sgr0)
#export LESS_TERMCAP_ue=$(tput sgr0)
#export LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 2)
#export LESS_TERMCAP_mr=$(tput rev)
#export LESS_TERMCAP_mh=$(tput dim)
#export LESS_TERMCAP_ZN=$(tput ssubm)
#export LESS_TERMCAP_ZV=$(tput rsubm)
#export LESS_TERMCAP_ZO=$(tput ssupm)
#export LESS_TERMCAP_ZW=$(tput rsupm)

stty -ixon # disable ctrl-s from pausing execution

# Shell options #
shopt -s cdspell
shopt -s autocd
shopt -s globstar

# openDDS support
if [[ -f /usr/local/share/dds/dds-devel.sh ]]; then
	source /usr/local/share/dds/dds-devel.sh
fi
