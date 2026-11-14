# shellcheck shell=sh disable=SC1091
# cargo (Rust). env 가 ~/.cargo/bin 을 PATH 에 넣는다.
if [ -f "$HOME/.cargo/env" ]; then
	. "$HOME/.cargo/env"
fi
