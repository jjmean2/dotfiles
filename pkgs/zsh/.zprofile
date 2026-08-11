# shellcheck disable=SC2034
typeset -U path fpath PATH FPATH
export PATH FPATH

# shellcheck disable=SC1091
if [[ -r $HOME/.config/shell/profile.sh ]]; then
	source "$HOME/.config/shell/profile.sh"
fi
