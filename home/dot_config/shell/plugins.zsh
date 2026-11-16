# vim:ft=zsh
# ==============================================================================
# zsh 플러그인: 무엇을, 어떤 순서로, 어떤 설정으로 읽는가
# 위치: ~/.config/shell/plugins.zsh  (rc.sh 가 rc.d/ 다음, terminal/ 앞에서 zsh 일 때만 읽는다)
# ==============================================================================
#
# zsh 에는 플러그인이라는 장치가 따로 없다. 플러그인은 source 로 읽는 zsh 스크립트이고, 줄 편집기(ZLE)의
# 위젯을 감싸거나(zle -N), 입력 줄에 색을 칠하거나(region_highlight), 커서 뒤에 글자를 보여 주는(POSTDISPLAY)
# 고유 장치를 쓴다. 그래서 플러그인 관리자 없이 파일을 받아(.chezmoiexternal.toml) 여기서 직접 읽는다.
# 더하고 올리고 빼는 법: 저장소의 docs/zsh-plugins.md
#
# 순서가 곧 설계다. 플러그인끼리 같은 키와 위젯을 차례로 감싸기 때문에 아래 순서를 바꾸지 않는다.
#   (앞) compinit (rc.zsh) → fzf 의 Tab·Ctrl-R 바인딩 (rc.d/fzf.sh)
#   1. fzf-tab                  compinit 뒤, Tab(^I) 을 마지막으로 잡아야 한다. 위젯을 감싸는 플러그인보다 앞
#   2. zsh-autosuggestions      위젯을 감싼다
#   3. zsh-syntax-highlighting  반드시 마지막. 이보다 뒤에 만든 위젯은 입력 줄 색칠이 갱신되지 않는다
#
# 받지 못한 플러그인(첫 apply 에서 네트워크 실패 등)은 조용히 건너뛴다.
# 이 머신에서만 끄려면 관리 밖 파일 ~/.config/shell/rc.d/plugins.local.zsh 에 이름을 공백으로 나눠 적는다.
# rc.d/ 가 이 파일보다 먼저 읽힌다.
#   JW_ZSH_PLUGINS_DISABLE='fzf-tab zsh-syntax-highlighting'

_jw_plugin_dir=$HOME/.local/share/zsh/plugins

# 플러그인의 진입 파일 경로를 REPLY 에 넣는다. 없거나 꺼 두었으면 1 을 돌려준다.
# source 는 이 함수 밖(최상위)에서 한다. 함수 안에서 읽으면 플러그인이 typeset 으로 만든 변수가 함수의
# 지역 변수가 되어 사라진다 (load-dir.sh 와 같은 이유).
_jw_plugin() {
	REPLY=$_jw_plugin_dir/$1/$1.plugin.zsh
	[[ " ${JW_ZSH_PLUGINS_DISABLE-} " != *" $1 "* && -r $REPLY ]]
}

# ------------------------------------------------------------------------------
# 1. fzf-tab: Tab 완성 목록을 fzf 로 고른다. https://github.com/Aloxaf/fzf-tab
# ------------------------------------------------------------------------------
# Tab 의 원래 동작(완성 목록 만들기)은 zsh 가 그대로 하고, 고르는 화면만 fzf 로 바꾼다. fzf 의 `**<Tab>`
# 은 fzf-tab 이 앞 바인딩(fzf-completion)을 불러 쓰므로 그대로 된다.
# 목록 안의 키: 글자 입력으로 걸러내기, Enter 고르기, Tab 여러 개 고르기, < > 종류(묶음) 바꾸기, Esc 닫기
if (( $+commands[fzf] )) && _jw_plugin fzf-tab; then
	source $REPLY
	# zsh 의 메뉴 선택(rc.zsh 의 menu select)을 끈다. 켜 두면 fzf-tab 보다 먼저 메뉴가 뜬다
	zstyle ':completion:*' menu no
	# 묶음 제목. fzf-tab 은 제목 안의 색 이스케이프(%F)를 읽지 못해 rc.zsh 의 색 있는 형식을 덮어쓴다
	zstyle ':completion:*:descriptions' format '[%d]'
	# 묶음 바꾸기 키 (기본 F1/F2)
	zstyle ':fzf-tab:*' switch-group '<' '>'
	# cd 로 디렉터리를 고를 때 오른쪽에 그 안의 파일을 보여 준다 ($realpath 는 fzf-tab 이 채운다)
	zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1A -- $realpath'
fi

# ------------------------------------------------------------------------------
# 2. zsh-autosuggestions: 입력하는 동안 히스토리에서 찾은 나머지를 흐린 글씨로 보여 준다.
#    https://github.com/zsh-users/zsh-autosuggestions
# ------------------------------------------------------------------------------
# 받아들이기: → 또는 End (Ctrl-F, Ctrl-E 도 같다). 한 단어씩: Option+→ (rc.zsh 의 forward-word)
# 무시: 그냥 계속 입력한다. 키를 새로 묶지 않았다 (기본 키에 이미 걸려 있다).
if _jw_plugin zsh-autosuggestions; then
	# 제안의 출처는 히스토리만. completion 전략(완성 시스템을 가상 터미널에서 돌림)은 fzf-tab 과 같이
	# 쓸 때 문제없는지 확인하지 않아 켜지 않았다
	ZSH_AUTOSUGGEST_STRATEGY=(history)
	# 붙여 넣은 긴 줄에는 제안을 찾지 않는다 (입력이 느려지지 않게)
	ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=100
	source $REPLY
fi

# ------------------------------------------------------------------------------
# 3. zsh-syntax-highlighting: 입력 중인 명령에 색을 칠한다. 반드시 마지막.
#    https://github.com/zsh-users/zsh-syntax-highlighting
# ------------------------------------------------------------------------------
# 없는 명령은 빨강, 있는 명령은 초록, 따옴표 문자열은 노랑. brackets 는 짝이 맞지 않는 괄호를 표시한다.
if _jw_plugin zsh-syntax-highlighting; then
	ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
	# 붙여 넣은 긴 줄은 칠하지 않는다 (입력이 느려지지 않게)
	ZSH_HIGHLIGHT_MAXLENGTH=512
	source $REPLY
fi

unfunction _jw_plugin
unset _jw_plugin_dir REPLY
