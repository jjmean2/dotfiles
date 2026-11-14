# shellcheck shell=sh
# Go: go install 로 받은 실행 파일($GOPATH/bin)을 PATH 에 넣는다.
# go 가 PATH 에 없으면(대화형 셸은 rc.sh 에서야 mise 가 켜진다) mise 로 설치한 go 에게 묻는다.
if command -v go >/dev/null 2>&1; then
	_target_gopath=$(go env GOPATH 2>/dev/null)
elif command -v mise >/dev/null 2>&1 && mise which go >/dev/null 2>&1; then
	_target_gopath=$(mise exec go -- go env GOPATH 2>/dev/null)
fi

if [ -n "$_target_gopath" ]; then
	PATH="$_target_gopath/bin:$PATH"
fi
unset _target_gopath
