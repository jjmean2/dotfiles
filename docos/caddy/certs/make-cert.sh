#!/bin/sh

# 1. 스크립트가 위치한 디렉토리 경로 추출
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# 2. 해당 디렉토리로 이동
cd "$SCRIPT_DIR" || exit 1

mkcert -cert-file cert.pem -key-file key.pem '*.jwlee.dev' 'localhost' 'localhost.test' 'kroki.internal' 'gerrit.internal'
