#!/usr/bin/env bash
set -euo pipefail

ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

if [[ $ARCH = "x86_64" ]]; then
	URL="https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.appimage"
elif [[ $ARCH = aarch64 || $ARCH = arm64 ]]; then
	URL="https://github.com/neovim/neovim/releases/download/stable/nvim-linux-arm64.appimage"
else
	echo "Unsupported architecture: $ARCH"
	exit 1
fi

echo "Downloading Neovim from $ARCH..."
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

pushd "$TMP_DIR" &>/dev/null

curl -fLO "$URL"
mv nvim-linux-*.appimage nvim.appimage
chmod u+x nvim.appimage

./nvim.appimage --appimage-extract

TARGET_OPT_DIR="$HOME/.local/opt"
TARGET_BIN_DIR="$HOME/.local/bin"
mkdir -p "$TARGET_OPT_DIR" "$TARGET_BIN_DIR"

rm -rf "$TARGET_OPT_DIR/neovim"
mv squashfs-root/usr "$TARGET_OPT_DIR/neovim"

ln -sf "$TARGET_OPT_DIR/neovim/bin/nvim" "$TARGET_BIN_DIR/nvim"

popd &>/dev/null

echo "Neovim ($ARCH) installation completed!"
