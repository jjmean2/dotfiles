source_zsh_variants ~/.zprofile

# setup for non-interactive sessions of mise
# https://mise.en.dev/dev-tools/shims.html#how-to-add-mise-shims-to-path
if ! [[ -o interactive ]]; then
	eval "$(mise activate zsh --shims)"
fi
