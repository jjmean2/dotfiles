# shellcheck shell=sh
# pixi (conda 계열 패키지 매니저) 의 전역 실행 파일
if [ -d "$HOME/.pixi/bin" ]; then
	PATH="$HOME/.pixi/bin:$PATH"
fi
