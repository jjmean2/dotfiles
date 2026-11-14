# shellcheck shell=sh
# mozjpeg (cjpeg, jpegtran 등). brew 의 keg-only formula 라 PATH 에 직접 넣는다.
if [ -d "$HOMEBREW_PREFIX/opt/mozjpeg/bin" ]; then
	PATH="$HOMEBREW_PREFIX/opt/mozjpeg/bin:$PATH"
fi
