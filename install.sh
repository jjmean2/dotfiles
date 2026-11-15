#!/bin/sh
# dev container 에 이 dotfiles 를 까는 진입점. 설계는 docs/machines.md 의 "dev container".
#
# VS Code Dev Containers 와 GitHub Codespaces 의 dotfiles 기능은 저장소를 컨테이너 안에 clone 한 뒤
# 루트의 install.sh 를 인자 없이 실행한다. VS Code 사용자 설정에 한 줄을 넣어 두면 컨테이너를 만들 때마다 된다:
#   "dotfiles.repository": "jjmean2/dotfiles"
# 손으로 돌려도 된다:
#   git clone https://github.com/jjmean2/dotfiles.git ~/dotfiles && ~/dotfiles/install.sh [ide|minimal|full]
#
# 하는 일: chezmoi 가 없으면 ~/.local/bin 에 받고, 이 파일이 있는 저장소를 소스로 chezmoi init --apply 를
# 질문 없이 실행한다. 무엇을 깔지는 인자로 고른다.
#   ide      (기본) 필수 도구와 설정 + nvim IDE(LazyVim). minimal 등급에 ide 기능만 켠 것이다
#   minimal  필수 도구와 설정만
#   full     Mac 의 full 머신과 같은 기능 (ide, dev, credentials). 언어 런타임을 받느라 몇 분 걸린다
#
# 처음 한 번만 쓴다. 이미 chezmoi 로 init 한 머신에서는 아무것도 하지 않는다 (그 뒤로는 chezmoi apply / update).
# Linux 전용이다. Mac 은 README 의 "설치" 대로 chezmoi 를 직접 실행한다 (이메일·이름·Karabiner 를 물어야 해서).
set -eu

log() { printf '[install.sh] %s\n' "$*" >&2; }
die() {
	log "$*"
	exit 1
}

mode="${1:-ide}"
case "$mode" in
ide | minimal | full) ;;
*)
	echo "사용법: install.sh [ide|minimal|full]   (기본 ide. 이 파일 머리말 참고)" >&2
	exit 2
	;;
esac

src="$(cd "$(dirname "$0")" && pwd)"
[ -f "$src/.chezmoiroot" ] || die "저장소를 clone 한 뒤 그 안의 install.sh 를 실행해야 한다 ($src 에 .chezmoiroot 가 없다)"
[ "$(uname -s)" = Linux ] || die "Linux(dev container) 전용이다. Mac 은 README 의 '설치' 를 따른다"

cfg="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi/chezmoi.toml"
if [ -e "$cfg" ]; then
	log "이미 chezmoi 로 init 한 머신이다 ($cfg). 아무것도 하지 않는다. 다시 적용하려면 chezmoi apply"
	exit 0
fi

PATH="$HOME/.local/bin:$PATH"
export PATH
if ! command -v chezmoi >/dev/null 2>&1; then
	log "chezmoi 를 $HOME/.local/bin 에 받는다"
	mkdir -p "$HOME/.local/bin"
	if command -v curl >/dev/null 2>&1; then
		sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" >/dev/null
	elif command -v wget >/dev/null 2>&1; then
		sh -c "$(wget -qO- get.chezmoi.io)" -- -b "$HOME/.local/bin" >/dev/null
	else
		die "curl 이나 wget 이 필요하다"
	fi
	command -v chezmoi >/dev/null 2>&1 || die "chezmoi 를 받지 못했다"
fi

# 등급과 기능. ide 는 "minimal 인데 ide 기능만 켠다" 이다. 기능 스위치는 질문이 아니라 설정 파일의
# [data.features] 에 적는 값이라서, init 전에 그 한 줄만 든 설정 파일을 먼저 써 둔다. init 은 설정 파일을
# 템플릿으로 다시 쓰면서 이미 적혀 있는 스위치를 옮겨 적는다 (home/.chezmoi.toml.tmpl).
minimal=true
[ "$mode" != full ] || minimal=false
if [ "$mode" = ide ]; then
	mkdir -p "$(dirname "$cfg")"
	printf '[data.features]\n  ide = true\n' >"$cfg"
fi

# git 신원은 컨테이너에 이미 있는 값을 쓴다 (이 스크립트가 돌기 전에 누가 git 설정을 넣어 두었다면 그 값).
# 없으면 비워 둔다. 그러면 dotfiles 의 git 설정에 신원 줄이 들어가지 않고, 첫 커밋 때 git 이 정하라고 알려 준다.
# --promptBool / --promptString 의 키는 home/.chezmoi.toml.tmpl 의 질문 문구 그대로여야 한다 (jw-ephemeral 도 같은 문구를 쓴다).
email="$(git config --global user.email 2>/dev/null || true)"
name="$(git config --global user.name 2>/dev/null || true)"

log "$src 를 소스로 깐다 (모드: $mode)"
rc=0
chezmoi init --apply --source "$src" --promptBool "minimal=$minimal" \
	--promptString "Email address=$email" --promptString "Full name (git user.name)=$name" || rc=$?

# init 이 설정 파일을 만들기 전에 실패했다면 위에서 써 둔 한 줄짜리 파일만 남는다. 그대로 두면 다음 실행이
# "이미 init 한 머신" 으로 보고 멈추므로 지운다.
if [ "$rc" -ne 0 ] && [ -e "$cfg" ] && ! grep -q '^sourceDir' "$cfg"; then
	rm -f "$cfg"
fi
if [ "$rc" -ne 0 ]; then
	log "chezmoi 가 실패로 끝났다 (종료 코드 $rc). 설정 파일까지 만들어졌다면 chezmoi apply 로 이어서 한다"
	exit "$rc"
fi
log "끝. 새 셸을 열면 적용된다"
