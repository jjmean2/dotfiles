# shellcheck shell=bash disable=SC1091
# Google Cloud SDK 의 명령 완성. 설치 스크립트가 rc 파일에 넣어 주는 줄과 같다 (PATH 는 profile.d/gcloud.sh).
if [ -n "$ZSH_VERSION" ]; then
	[ -f "$HOME/dev/toolbox/google-cloud-sdk/completion.zsh.inc" ] &&
		. "$HOME/dev/toolbox/google-cloud-sdk/completion.zsh.inc"
elif [ -n "$BASH_VERSION" ]; then
	[ -f "$HOME/dev/toolbox/google-cloud-sdk/completion.bash.inc" ] &&
		. "$HOME/dev/toolbox/google-cloud-sdk/completion.bash.inc"
fi
