# shellcheck shell=bash disable=SC1091

if [[ -r $HOME/.config/shell/profile.sh ]]; then
	source "$HOME/.config/shell/profile.sh"
fi

if [[ $- = *i* ]]; then
	source "$HOME/.bashrc"
fi
