[[ -d $HOME/Library/pnpm ]] || return 0

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
path=($PNPM_HOME/bin $path)
# pnpm end
