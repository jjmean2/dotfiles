#!/bin/bash

set -euo pipefail

DOMAINS=(
	"*.jwlee.lan"
	"*.jwlee.priv"
	"*.home.arpa"
	"*.jwlee.internal"
	"localhost"
)

# 1. 스크립트가 위치한 디렉토리 경로 추출
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$SCRIPT_DIR/../caddy/certs"

mkdir -p "$TARGET_DIR"

# 2. 해당 디렉토리로 이동
cd "$TARGET_DIR" || exit 1

mkcert -cert-file cert.pem -key-file key.pem "${DOMAINS[@]}"
