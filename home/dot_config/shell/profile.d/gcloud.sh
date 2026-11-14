# shellcheck shell=sh disable=SC1091
# Google Cloud SDK 의 PATH. 설치 스크립트가 rc 파일에 넣어 주는 줄과 같다 (완성은 rc.d/gcloud.sh).
# 설치 위치는 ~/dev/toolbox/google-cloud-sdk 로 고정돼 있다. 다른 곳에 깐 머신은
# 관리 밖 profile.d/gcloud.local.sh 에 그 경로로 같은 줄을 둔다.
if [ -n "$ZSH_VERSION" ]; then
	[ -f "$HOME/dev/toolbox/google-cloud-sdk/path.zsh.inc" ] &&
		. "$HOME/dev/toolbox/google-cloud-sdk/path.zsh.inc"
elif [ -n "$BASH_VERSION" ]; then
	[ -f "$HOME/dev/toolbox/google-cloud-sdk/path.bash.inc" ] &&
		. "$HOME/dev/toolbox/google-cloud-sdk/path.bash.inc"
fi
