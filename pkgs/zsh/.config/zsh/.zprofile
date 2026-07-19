# setup for homebrew
if [[ -f /opt/homebrew/bin/brew ]]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
	eval "$(/usr/local/bin/brew shellenv)"
fi

# setup for non-interactive sessions of mise
# https://mise.en.dev/dev-tools/shims.html#how-to-add-mise-shims-to-path
if command -v mise &>/dev/null && ! [[ -o interactive ]]; then
	eval "$(mise activate zsh --shims)"
fi
