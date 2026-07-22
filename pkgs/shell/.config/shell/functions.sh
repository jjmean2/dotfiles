# shellcheck shell=bash disable=SC1091,SC1090
# Count line changes for each author
jw_count_line_changes() {
	# shellcheck disable=SC2016
	git shortlog -sn --since="${2:-1.year.ago}" | cut -f2 | cut -d\( -f1 | xargs -L 1 bash -c 'echo -ne "$1":"\t" ; git count-line-changes --since=$0 --author="$1"' "$1" | sort -nrk 8
}

if [ -d "$HOME/.vim" ]; then
	# Vim package related alias
	jw_vim_list_plugins() {
		find -E ~/.vim/pack -type d -regex ".*/start/[^/]+$" |
			sed -E "s:.*/([^/]+/start/[^/]+)$:\1:"
	}

	jw_vim_install_helpdocs() {
		find ~/.vim/pack -type d -name doc -print0 |
			xargs -0 -o -I% vim -u NONE -c "helptags %" -c q
	}
fi

if [ -f /usr/libexec/java_home ]; then
	jw_set_java_home() {
		JAVA_HOME=$(/usr/libexec/java_home -v "$1")
		export JAVA_HOME
	}
fi

jw_decode_proto_hangul() {
	python3 - "$@" <<-EOF
		import sys
		if len(sys.argv) >= 2:
		  source = sys.argv[1]
		else:
		  source = ""
		  for line in sys.stdin:
		    source += line

		result = source.encode("latin1").decode("unicode-escape").encode("latin1").decode("utf8")
		print(result)
	EOF
}

jw_chrome() {
	/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome "$@"
}

jw_chrome_debug() {
	/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 --user-data-dir=remote-profile "$@"
}

sq_prepare_k2_web() {
	REPO_ROOT="$(basename "$(git rev-parse --show-toplevel)")"
	if [[ "$REPO_ROOT" != *squarelab ]]; then
		echo You\'re not in squarelab repo
		return 1
	fi
	# gd k2_web:cpenv && yarn workspace web start
	gd k2_web:cpenv && yarn --cwd client/k2_web start
}

sq_with_https() {
	local CRT_ROOT=/Users/ljw/squarelab/.keystore/local-dev-server-cert

	HTTPS=true \
		SSL_KEY_FILE="$CRT_ROOT/key.pem" \
		SSL_CRT_FILE="$CRT_ROOT/cert.pem" \
		"$@"
}

if [ -n "$ZSH_VERSION" ]; then
	[ -f "$HOME/.config/shell/functions.zsh" ] && . "$HOME/.config/shell/functions.zsh"
elif [ -n "$BASH_VERSION" ]; then
	[ -f "$HOME/.config/shell/functions.bash" ] && . "$HOME/.config/shell/functions.bash"
fi
