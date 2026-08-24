#!/bin/sh

# 헤더 출력 (UID, PID, PPID, TTY, COMM)
printf "%-8s %-7s %-7s %-10s %s\n" "UID" "PID" "PPID" "TTY" "COMMAND"

# /proc 하위의 숫자(PID) 디렉토리 순회
for pid_dir in /proc/[0-9]*; do
	[ -d "$pid_dir" ] || continue

	# 디렉토리 경로에서 PID만 추출 (/proc/123 -> 123)
	pid=${pid_dir#/proc/}

	if [ -f "$pid_dir/status" ]; then
		# /proc/[PID]/status 파일에서 필요 정보 추출
		comm=$(awk '/^Name:/ {print $2}' "$pid_dir/status" 2>/dev/null)
		uid=$(awk '/^Uid:/ {print $2}' "$pid_dir/status" 2>/dev/null)
		ppid=$(awk '/^PPid:/ {print $2}' "$pid_dir/status" 2>/dev/null)

		# /proc/[PID]/fd/0 심볼릭 링크를 이용해 TTY 확인
		tty_path=$(readlink "$pid_dir/fd/0" 2>/dev/null)
		case "$tty_path" in
		/dev/pts/*) tty="${tty_path#/dev/}" ;;
		/dev/tty*) tty="${tty_path#/dev/}" ;;
		*) tty="?" ;;
		esac

		# 정렬된 테이블 형태로 출력
		printf "%-8s %-7s %-7s %-10s %s\n" "$uid" "$pid" "$ppid" "$tty" "$comm"
	fi
done
