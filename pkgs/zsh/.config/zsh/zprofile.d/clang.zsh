[[ -d /opt/homebrew/opt/llvm ]] || return 0

# clang, clang++ 등을 연결하기 위함. 최신 기능이 필요없다면, 다음 라인들은 주석처리할 것
path=(/opt/homebrew/opt/llvm/bin $path)
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
export CMAKE_PREFIX_PATH="/opt/homebrew/opt/llvm"
