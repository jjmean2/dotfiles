typeset -U path fpath
export PATH FPATH

if [[ -r $HOME/.config/shell/profile.sh ]]; then
	source "$HOME/.config/shell/profile.sh"
fi
