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
