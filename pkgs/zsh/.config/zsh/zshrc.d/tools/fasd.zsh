() {
	# fasd는 brew로 설치되거나 ~/.jongwan/bin/fasd로 설치할 수 있다.
	# 후자의 경우, 아직 PATH 설정 전이라서 commands[fasd]에서 안 나올 수 있다.
	local fasd_path="${commands[fasd]:-$HOME/.jongwan/bin/fasd}"

	# fasd 커맨드가 사용 불가능하면, early return 한다.
	[[ -f $fasd_path ]] || return 0

	# fasd initialization (Select one between two ways of configuration)
	# "Default" configuration
	# https://github.com/clvv/fasd
	# eval "$(fasd --init auto)"

	# "Fast init with cache" configration
	local fasd_cache="$HOME/.fasd-init-zsh"
	if [[ $fasd_path -nt $fasd_cache || ! -s $fasd_cache ]]; then
		# `>` means it will overwrite even if "$fasd_cache" file exists
		# https://unix.stackexchange.com/questions/45201/bash-what-does-do
		# fasd --init auto >|"$fasd_cache"
		$fasd_path --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install >|"$fasd_cache"

	fi
	source "$fasd_cache"
}
