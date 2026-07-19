.PHONY: all install link unlink

all: install link

# 기본 도구 설치 (scripts/install_base.sh)
install:
	scripts/install_base.sh

# pkgs 를 stow 로 링크 (scripts/install_pkgs.sh)
link:
	scripts/install_pkgs.sh

# pkgs 를 stow 로 unlink (scripts/uninstall_pkgs.sh)
unlink:
	scripts/uninstall_pkgs.sh
