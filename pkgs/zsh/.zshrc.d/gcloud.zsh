# Google Cloud SDK
# The next line updates PATH for the Google Cloud SDK.
if [[ -f $HOME/dev/toolbox/google-cloud-sdk/path.zsh.inc ]]; then
	source "$HOME/dev/toolbox/google-cloud-sdk/path.zsh.inc"
fi

# The next line enables shell command completion for gcloud.
if [[ -f $HOME/dev/toolbox/google-cloud-sdk/completion.zsh.inc ]]; then
	source "$HOME/dev/toolbox/google-cloud-sdk/completion.zsh.inc"
fi
