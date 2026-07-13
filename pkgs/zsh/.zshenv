# if [[ -z $ZDOTDIR ]]; then
# 	export ZDOTDIR="$HOME/.config/zsh"
# 	[[ -f $ZDOTDIR/.zshenv ]] && source $ZDOTDIR/.zshenv
# fi

# ZDOTDIR이 세팅되지 않은 경우에 기본 경로 지정
# 빈 값이라도 세팅되어 있다면 스킵
if ((!$+ZDOTDIR)); then
	export ZDOTDIR="$HOME/.config/zsh"
fi

# 파라미터 확장시 Prompt Expansion을 사용하도록 설정 (% 플래그)
# %x는 현재 스크립트 파일의 경로를 의미한다.
# :- 는 파라미터 기본값을 지정하는 파라미터 확장의 문법으로
# 앞에 파라미터 명이 없으면, 항상 기본값이 사용된다.
current_file="${(%):-%x}"

# 현재 파일이 ZDOTDIR/.zshenv 가 아니면, ZDOTDIR/.zshenv 를 로드한다.
if [[ -f $ZDOTDIR/.zshenv ]]; then
	if [[ ! $current_file -ef $ZDOTDIR/.zshenv ]]; then
		source "$ZDOTDIR/.zshenv"
	fi
fi
unset current_file
