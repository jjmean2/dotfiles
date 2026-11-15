# shellcheck shell=sh disable=SC1090,SC2154
# 디렉터리 하나에 든 셸 조각을 읽는다. profile.d/ · rc.d/ · functions.d/ · terminal/ 이 모두 이 파일로 읽힌다.
#
#   _jw_dir="$HOME/.config/shell/rc.d"
#   . "$HOME/.config/shell/load-dir.sh"
#
# 규칙
#   - 두 번에 나눠 읽는다. 먼저 chezmoi 가 까는 조각을, 그다음 이 머신에만 있는 조각(이름에 .local. 이 든 것,
#     예: company.local.sh)을 읽는다. 그래서 머신 전용 조각은 도구 조각이 만든 변수를 쓸 수 있고,
#     PATH·키 바인딩·alias 처럼 나중에 정한 것이 이기는 자리에서 항상 이긴다.
#   - 각 번 안에서는 이름순으로 읽는다 (숫자가 글자보다 앞). 조각끼리는 순서에 기대지 않는 것이 원칙이고,
#     꼭 먼저 읽혀야 하는 조각만 숫자를 앞에 붙인다 (예: profile.d/10-swiftly.sh).
#   - 확장자가 셸을 가린다: *.sh 는 어느 셸에서나, *.zsh 는 zsh 에서만, *.bash 는 bash 에서만.
#     그 밖의 파일과 하위 디렉터리는 읽지 않는다.
#   - 조각 안에서 이 파일을 다시 부르지 않는다 (_jw_dir, _jw_file 을 같이 쓴다).
#
# 함수가 아니라 소싱하는 파일인 이유: 함수 안에서 조각을 읽으면 조각이 typeset·declare 로 만든 변수가
# 그 함수의 지역 변수가 되어 사라진다.
# 외부 명령(ls, find)을 쓰지 않는 이유: 셸을 띄울 때마다 디렉터리 수만큼 프로세스를 만들게 된다
# (zsh 에서 한 번에 수 ms. 2026-11-15 측정).
if [ -n "$ZSH_VERSION" ]; then
	# zsh 는 맞는 파일이 없으면 "no matches found" 로 멈추므로 glob 한정자 (N) 을 붙인다. (-.) 은 일반 파일만
	# (심볼릭 링크는 따라간다). 다른 셸이 이 문법을 읽다가 멈추지 않도록 eval 안에 둔다.
	eval 'for _jw_file in "$_jw_dir"/*.(sh|zsh)(N-.); do
		case "$_jw_file" in *.local.*) ;; *) . "$_jw_file" ;; esac
	done
	for _jw_file in "$_jw_dir"/*.local.*(N-.); do
		case "$_jw_file" in *.sh | *.zsh) . "$_jw_file" ;; esac
	done'
elif [ -d "$_jw_dir" ]; then
	for _jw_file in "$_jw_dir"/*; do
		[ -f "$_jw_file" ] || continue
		case "$_jw_file" in
		*.local.*) ;;
		*.bash) [ -n "$BASH_VERSION" ] && . "$_jw_file" ;;
		*.sh) . "$_jw_file" ;;
		esac
	done
	for _jw_file in "$_jw_dir"/*.local.*; do
		[ -f "$_jw_file" ] || continue
		case "$_jw_file" in
		*.bash) [ -n "$BASH_VERSION" ] && . "$_jw_file" ;;
		*.sh) . "$_jw_file" ;;
		esac
	done
fi
unset _jw_dir _jw_file
