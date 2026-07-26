# shellcheck disable=SC2034
define_colors() {
	# 1. 연관 배열 전역 선언 (-g: global, -A: associative array)
	declare -g -A color fg fg_bold bg bg_bold
	declare -g reset_color bold_color

	# 2. 기본 ANSI 매핑 테이블 구축
	color=(
		[00]="none"
		[01]="bold"
		[02]="faint"
		[22]="normal"
		[03]="italic"
		[23]="no-italic"
		[04]="underline"
		[24]="no-underline"
		[05]="blink"
		[25]="no-blink"
		[07]="reverse"
		[27]="no-reverse"
		[08]="conceal"
		[28]="no-conceal"

		[30]="black"
		[40]="bg-black"
		[31]="red"
		[41]="bg-red"
		[32]="green"
		[42]="bg-green"
		[33]="yellow"
		[43]="bg-yellow"
		[34]="blue"
		[44]="bg-blue"
		[35]="magenta"
		[45]="bg-magenta"
		[36]="cyan"
		[46]="bg-cyan"
		[37]="white"
		[47]="bg-white"
		[39]="default"
		[49]="bg-default"
	)
	local k
	for k in "${!color[@]}"; do
		color[${color[$k]}]=$k
	done

	for k in "${!color[@]}"; do
		# 키가 '3'으로 시작하고 2자리인 경우 (30~39 번 대 글자색 코드)
		if [[ $k == 3? ]]; then
			color["fg-${color[$k]}"]="$k"
		fi
	done

	for k in grey gray; do
		color[$k]=${color[black]}
		color["fg-$k"]=${color[$k]}
		color["bg-$k"]=${color["bg-black"]}
	done

	local lc=$'\e[' rc=m
	declare -g reset_color bold_color
	reset_color="$lc${color[none]}$rc"
	bold_color="$lc${color[bold]}$rc"

	declare -Ag fg fg_bold fg_no_bold
	local color_name
	for k in "${!color[@]}"; do
		if [[ $k == fg-* ]]; then
			color_name="${k#fg-}"
			fg["$color_name"]="$lc${color[$k]}$rc"
			fg_bold["$color_name"]="$lc${color[bold]};${color[$k]}$rc"
			fg_no_bold["$color_name"]="$lc${color[normal]};${color[$k]}$rc"
		fi
	done

	declare -Ag bg bg_bold bg_no_bold
	for k in "${!color[@]}"; do
		if [[ $k == bg-* ]]; then
			color_name="${k#bg-}"
			bg["$color_name"]="$lc${color[$k]}$rc"
			bg_bold["$color_name"]="$lc${color[bold]};${color[$k]}$rc"
			bg_no_bold["$color_name"]="$lc${color[normal]};${color[$k]}$rc"
		fi
	done
}

colors() {

	local code="" arg key
	declare -A map=(
		# 스타일
		[reset]="0"

		[bold]="1"
		[faint]="2"
		[italic]="3"
		[underline]="4"
		[blink]="5"
		[reverse]="7"
		[conceal]="8"

		["nobold"]="22"
		["nofaint"]="22"
		["noitalic"]="23"
		["nounderline"]="24"
		["noblink"]="25"
		["noeverse"]="27"
		["noconceal"]="28"

		# 글자색 (Foreground)
		[black]="30" [red]="31" [green]="32" [yellow]="33"
		[blue]="34" [magenta]="35" [cyan]="36" [white]="37"
		[default]="39"

		# 배경색 (Background)
		["bg-black"]="40" ["bg-red"]="41" ["bg-green"]="42" ["bg-yellow"]="43"
		["bg-blue"]="44" ["bg-magenta"]="45" ["bg-cyan"]="46" ["bg-white"]="47"
		["bg-default"]="49"
	)

	# 쉼표(,)나 공백( ) 구분자를 모두 인자로 받아 처리
	for arg in "$@"; do
		# IFS를 쉼표로 설정해 "bold,green" 형태도 분리
		IFS=',' read -ra keys <<<"$arg"
		for key in "${keys[@]}"; do
			if [[ -n "${map[$key]}" ]]; then
				if [[ -z "$code" ]]; then
					code="${map[$key]}"
				else
					code="${code};${map[$key]}"
				fi
			fi
		done
	done

	local is_in_prompt=0
	if [[ ${FUNCNAME[1]} == pcolors ]]; then
		is_in_prompt=1
	fi

	# 일치하는 키가 있으면 ANSI Escape Sequence 출력
	if [[ -n "$code" ]]; then
		if [[ $is_in_prompt -eq 1 ]]; then
			# 프롬프트에서 사용될 때는 \[와 \]로 감싸서 출력
			printf "\[\e[%sm\]" "$code"
		else
			# 일반적인 경우에는 그냥 출력
			printf "\e[%sm" "$code"
		fi
	fi
}
pcolors() {
	colors "$@"
}

hey() {
	printf "\[\e[%sm\]" "36;4"
}
