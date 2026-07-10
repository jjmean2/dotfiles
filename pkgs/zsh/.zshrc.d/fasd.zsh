# commands 변수에는 zsh에서 사용 가능한 외부 실행파일의 경로가 담겨 있다.
# $+commands[fasd]는 fasd 키가 연관배열 변수에 있으면 1, 없으면 0을 반환한다.
# ((expr))는 expr이 0이면, exit code 1, 0이 아니면 exit code 0으로 종료된다.
# 이를 조합하여 특정 커맨드가 사용 가능한지 검사하는 조건을 만들 수 있다.
# fasd 커맨드가 사용 불가능하면, early return 한다.
(($+commands[fasd])) || return 0

# fasd initialization (Select one between two ways of configuration)
# "Default" configuration
# https://github.com/clvv/fasd
# eval "$(fasd --init auto)"

# "Fast init with cache" configration
fasd_cache="$HOME/.fasd-init-zsh"
if [ "$(command -v fasd)" -nt "$fasd_cache" -o ! -s "$fasd_cache" ]; then
	# `>` means it will overwrite even if "$fasd_cache" file exists
	# https://unix.stackexchange.com/questions/45201/bash-what-does-do
	fasd --init auto >|"$fasd_cache"
fi
source "$fasd_cache"
unset fasd_cache
