# ZDOTDIR을 XDG_CONFIG_HOME 인 ~/.config 내에 설정
export ZDOTDIR="$HOME/.config/zsh"

# 파라미터 확장시 Prompt Expansion을 사용하도록 설정 (% 플래그)
# %x는 현재 스크립트 파일의 경로를 의미한다.
# :- 는 파라미터 기본값을 지정하는 파라미터 확장의 문법으로
# 앞에 파라미터 명이 없으면, 항상 기본값이 사용된다.
current_file="${(%):-%x}"

# 현재 파일이 $ZDOTDIR/.zshenv 가 아니면, $ZDOTDIR/.zshenv 를 로드한다.
# 최초 로그인시 ZDOTDIR이 없는 상태로 시작하고,
# 이후 그 환경에서 다시 로그인시 ZDOTDIR이 있는 상태에서 시작해서
# ~/.config/zsh/.zshenv의 로드 여부가 달라지는 것을 방지하기 위함
if [[ -f $ZDOTDIR/.zshenv ]]; then
	if [[ ! $current_file -ef $ZDOTDIR/.zshenv ]]; then
		source "$ZDOTDIR/.zshenv"
	fi
fi
unset current_file
