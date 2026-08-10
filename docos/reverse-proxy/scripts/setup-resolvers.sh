#!/usr/bin/env bash
set -euo pipefail

DOMAINS=(
	"lan"
	"lab"
	"priv"
	"home.arpa"
	"internal"
)
RESOLVER_DIR="/etc/resolver"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_CONFIG="${SCRIPT_DIR}/dns/resolver.common"

# 스크립트가 관리하는 파일임을 표시할 식별용 마커
MANAGED_MARKER="# Managed by dotfiles"

# 소스 설정 파일 존재 여부 확인
if [ ! -f "$SRC_CONFIG" ]; then
	echo "Error: 소스 설정 파일을 찾을 수 없습니다: $SRC_CONFIG" >&2
	exit 1
fi

echo "==> /etc/resolver DNS 설정 동기화 시작..."

# 2. /etc/resolver 디렉토리가 없으면 root 권한으로 생성
if [ ! -d "$RESOLVER_DIR" ]; then
	echo "Creating directory: $RESOLVER_DIR"
	sudo mkdir -p "$RESOLVER_DIR"
	sudo chown root:wheel "$RESOLVER_DIR"
	sudo chmod 755 "$RESOLVER_DIR"
fi

# 3. 임시 바이너리 생성: 마커 주석 + 소스 설정 내용
# (dotfiles가 생성할 파일에는 항상 관리 마커 주석이 최상단에 붙음)
TEMP_SRC="$(mktemp)"
trap 'rm -f "$TEMP_SRC"' EXIT

echo "$MANAGED_MARKER" >"$TEMP_SRC"
cat "$SRC_CONFIG" >>"$TEMP_SRC"

NEED_FLUSH=false

# 4. 더 이상 사용하지 않는 (과거에 dotfiles가 설치했던) 레거시 파일 삭제 로직
# /etc/resolver 디렉토리 내부의 모든 파일 탐색
for file in "$RESOLVER_DIR"/*; do
	# 디렉터리가 비어있거나 파일이 존재하지 않는 경우 예외 처리
	[ -e "$file" ] || continue

	# 디렉터리는 스킵
	[ -f "$file" ] || continue

	filename="$(basename "$file")"

	# 현재 DOMAINS 목록에 들어있는 파일이면 삭제 검사 대상이 아니므로 패스
	IS_MANAGED_DOMAIN=false
	for d in "${DOMAINS[@]}"; do
		if [ "$d" = "$filename" ]; then
			IS_MANAGED_DOMAIN=true
			break
		fi
	done

	# 현재 DOMAINS 목록에는 없지만, 파일 첫 줄에 dotfiles 마커가 있는 경우 -> 삭제 처리
	if [ "$IS_MANAGED_DOMAIN" = false ]; then
		if head -n 1 "$file" | grep -Fq "$MANAGED_MARKER"; then
			echo "[DELETE] 더 이상 관리되지 않는 dotfiles resolver 파일 제거: $filename"
			sudo rm -f "$file"
			NEED_FLUSH=true
		fi
	fi
done

# 3. 정의된 도메인에 대해서만 멱등성 있게 동기화 수행
for domain in "${DOMAINS[@]}"; do
	TARGET="$RESOLVER_DIR/$domain"

	# 동기화(복사 및 권한 설정)가 필요한지 조건 검사
	# - 대상 파일이 존재하지 않거나
	# - dotfiles의 소스 파일과 파일 내용(diff)이 다르거나
	# - 파일 소유자/그룹이 root:wheel이 아니거나
	# - 파일 권한이 644가 아닌 경우

	NEEDS_UPDATE=false

	if [ ! -f "$TARGET" ]; then
		echo "[NEW] $domain 도메인 설정을 새로 추가합니다."
		NEEDS_UPDATE=true
	elif ! cmp -s "$TEMP_SRC" "$TARGET"; then
		echo "[UPDATE] $domain 도메인 설정 내용이 변경되어 업데이트합니다."
		NEEDS_UPDATE=true
	elif [ "$(stat -f "%Su:%Sg" "$TARGET")" != "root:wheel" ] || [ "$(stat -f "%Lp" "$TARGET")" != "644" ]; then
		echo "[FIX-PERM] $domain 도메인 설정의 권한/소유권을 올바르게 재설정합니다."
		NEEDS_UPDATE=true
	fi

	# 변경이 필요한 경우에만 sudo를 사용하여 처리
	if [ "$NEEDS_UPDATE" = true ]; then
		sudo cp "$TEMP_SRC" "$TARGET"
		sudo chown root:wheel "$TARGET"
		sudo chmod 644 "$TARGET"
		NEED_FLUSH=true
	else
		echo "[SKIP] $domain 도메인은 이미 최신 상태입니다."
	fi
done

# 4. 변경 사항이 발생한 경우에만 mDNSResponder 재시작 및 캐시 초기화
if [ "$NEED_FLUSH" = true ]; then
	echo "==> 변경 사항 적용을 위해 macOS DNS 캐시를 초기화합니다..."
	sudo killall -HUP mDNSResponder
	echo "==> 동기화 완료!"
else
	echo "==> 변경된 내용이 없습니다."
fi
