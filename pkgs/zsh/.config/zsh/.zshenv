# 대부분의 설치 도구를 찾기 위한 최소한의 PATH, FPATH 설정만 진행한다.
# 비로그인, 비대화형 세션에서도 해당 도구들은 찾을 수 있도록 한다.
# macOS에서 대부분의 도구는 Homebrew, mise로 설치할 예정이므로, 이 두가지 설정을 진행한다.

# ==================================================
# 🛠️ PATH, FPATH 및 도구별 환경 설정
# ==================================================
# path, fpath 변수에 중복 경로가 들어가지 않도록
typeset -U path
export PATH

typeset -U fpath
export FPATH

# Homebrew로 설치된 도구들을 찾을 수 있게 한다.
# setup for homebrew
if [[ -f /opt/homebrew/bin/brew ]]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
	eval "$(/usr/local/bin/brew shellenv)"
fi

# mise로 설치한 도구들을 찾을 수 있게 한다. interactive session이라면 여기 대신
# .zshrc에서 디렉토리 변경 hook 에서 동적으로 PATH를 처리하도록 한다.
# setup for non-interactive sessions of mise
# https://mise.en.dev/dev-tools/shims.html#how-to-add-mise-shims-to-path
if command -v mise &>/dev/null && ! [[ -o interactive ]]; then
	eval "$(mise activate zsh --shims)"
fi

# 내가 직접 작성한 autoload 함수를 찾을 수 있도록 fpath에 추가한다.
# 사실 개인 autoload 함수는 대부분 대화형 세션에서 쓸 용도라서
# 굳이 여기에 넣을 필요가 있을까 싶기도 한다.
fpath=(~/.jongwan/share/zsh/site-functions $fpath)

# ==================================================
# 🛠️ PATH, FPATH 및 도구별 환경 설정
# ==================================================
