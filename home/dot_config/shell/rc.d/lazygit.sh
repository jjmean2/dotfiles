# shellcheck shell=sh
# lazygit 설정 파일. macOS 에서 XDG_CONFIG_HOME 이 없으면 lazygit 은
# ~/Library/Application Support/lazygit/config.yml 을 읽으므로, dotfiles 가 관리하는 위치를
# 직접 가리킨다. nvim 안의 snacks lazygit 모듈은 이 값 뒤에 자기 테마 파일을 덧붙인다.
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"
