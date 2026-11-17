# shellcheck shell=bash
# fzf-git.sh: git 의 이름(브랜치, 커밋 해시, 파일 …)을 fzf 로 골라 입력 줄의 커서 자리에 넣는다.
# https://github.com/junegunn/fzf-git.sh  (파일은 .chezmoiexternal.toml 이 ~/.local/share/fzf-git/ 에 받는다)
#
# Ctrl-G 를 누른 뒤 두 번째 키 (Ctrl 을 떼고 눌러도 된다. Ctrl-G ? 로 이 목록을 본다)
#   Ctrl-G Ctrl-B  브랜치            git switch <Ctrl-G Ctrl-B>
#   Ctrl-G Ctrl-H  커밋 해시         git show <…>, git rebase -i <…>
#   Ctrl-G Ctrl-F  바뀐 파일 + 추적 파일   git add <…> (Tab 으로 여러 개)
#   Ctrl-G Ctrl-T  태그 / Ctrl-R 리모트 / Ctrl-S stash / Ctrl-L reflog / Ctrl-W 워크트리 / Ctrl-E 모든 ref
# 목록 안: Tab 여러 개 고르기, Ctrl-O 브라우저(GitHub)로 열기, Ctrl-/ 미리보기 위치 바꾸기,
#   브랜치·해시에서 Alt-A 는 리모트·전체까지 보이기. 목록마다 쓸 수 있는 키가 머리글에 나온다.
# tmux 안에서는 fzf 가 tmux 팝업으로 뜬다 (스크립트의 fzf --tmux 기본값).
#
# 주의: 목록 안의 Ctrl-X 는 묻지 않고 바로 지운다. Ctrl-G Ctrl-S(stash) 는 git stash drop, Ctrl-G Ctrl-W(워크트리) 는
# git worktree remove (커밋 안 된 변경이 있으면 git 이 거절하지만 그 안에서 도는 프로세스는 보지 않는다).
# 워크트리 정리는 tmux-dev 의 W 를 쓴다 (W 는 변경과 실행 중인 프로세스를 확인하고 윈도우도 같이 정리한다).
#
# Ctrl-G 의 원래 동작(입력 줄 취소, zsh 의 send-break)은 Ctrl-G 만 누르고 잠깐(KEYTIMEOUT) 기다리면 그대로 된다.
# 셸 조각이 위젯을 만드므로 zsh 에서는 plugins.zsh 의 zsh-syntax-highlighting 보다 먼저 읽혀야 한다 (rc.d 는 그 앞).
_jw_fzf_git=$HOME/.local/share/fzf-git/fzf-git.sh
if [ -r "$_jw_fzf_git" ] && command -v fzf >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
	. "$_jw_fzf_git"
fi
unset _jw_fzf_git
