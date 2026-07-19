# Count line changes for each author
function jw:count-line-changes() {
	git shortlog -sn --since="${2:-1.year.ago}" | cut -f2 | cut -d\( -f1 | xargs -L 1 bash -c 'echo -ne "$1":"\t" ; git count-line-changes --since=$0 --author="$1"' "$1" | sort -nrk 8
}

if [[ -d ~/.vim ]]; then
	# Vim package related alias
	function jw:vim:list-plugins() {
		find -E ~/.vim/pack -type d -regex ".*/start/[^/]+$" |
			sed -E "s:.*/([^/]+/start/[^/]+)$:\1:"
	}

	function jw:vim:install-helpdocs() {
		find ~/.vim/pack -type d -name doc |
			xargs -o -I% vim -u NONE -c "helptags %" -c q
	}
fi

if [[ -f /usr/libexec/java_home ]]; then
	function jw:set-java-home() {
		JAVA_HOME=$(/usr/libexec/java_home -v "$1")
		export JAVA_HOME
	}
fi

function jw:decode-proto-hangul() {
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

function jw:chrome() {
	/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome "$@"
}

function jw:chrome-debug() {
	/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 --user-data-dir=remote-profile "$@"
}

function sq:prepare-k2-web {
	REPO_ROOT="$(basename "$(git rev-parse --show-toplevel)")"
	if [[ "$REPO_ROOT" != *squarelab ]]; then
		echo You\'re not in squarelab repo
		return 1
	fi
	# gd k2_web:cpenv && yarn workspace web start
	gd k2_web:cpenv && yarn --cwd client/k2_web start
}

function sq:with-https() {
	local CRT_ROOT=/Users/ljw/squarelab/.keystore/local-dev-server-cert

	HTTPS=true \
		SSL_KEY_FILE="$CRT_ROOT/key.pem" \
		SSL_CRT_FILE="$CRT_ROOT/cert.pem" \
		"$@"
}
