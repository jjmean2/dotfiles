#!/bin/sh

# 시스템 부팅 시간(epoch) 및 현재 시간 구하기
btime=$(awk '/^btime/ {print $2}' /proc/stat 2>/dev/null)
now=$(date +%s 2>/dev/null)
[ -z "$now" ] && now=0

# CLK_TCK (리눅스 기본 클럭 틱: 100)
clk_tck=100

# 헤더 출력 (ps -ef 표준 스타일)
printf "%-8s %-7s %-7s %-3s %-8s %-10s %-8s %s\n" "UID" "PID" "PPID" "C" "STIME" "TTY" "TIME" "CMD"

for pid_dir in /proc/[0-9]*; do
	[ -d "$pid_dir" ] || continue
	pid=${pid_dir#/proc/}

	[ -f "$pid_dir/status" ] && [ -f "$pid_dir/stat" ] || continue

	# 1. status 파일에서 UID, PPID, 프로세스명 추출
	uid=$(awk '/^Uid:/ {print $2}' "$pid_dir/status" 2>/dev/null)
	ppid=$(awk '/^PPid:/ {print $2}' "$pid_dir/status" 2>/dev/null)
	name=$(awk '/^Name:/ {print $2}' "$pid_dir/status" 2>/dev/null)

	# 2. TTY 확인 (/proc/[PID]/fd/0 심볼릭 링크)
	tty_path=$(readlink "$pid_dir/fd/0" 2>/dev/null)
	case "$tty_path" in
	/dev/pts/*) tty="${tty_path#/dev/}" ;;
	/dev/tty*) tty="${tty_path#/dev/}" ;;
	*) tty="?" ;;
	esac

	# 3. stat 파일에서 CPU 사용량, 시작 시간 파싱
	stat_line=$(cat "$pid_dir/stat" 2>/dev/null)
	# stat 파일 내 프로세스 이름(괄호) 내부의 공백/특수문자 예외 처리
	stat_after=${stat_line##*\) }

	set -- $stat_after
	utime=${12}     # 사용자 CPU 시간 (틱)
	stime=${13}     # 시스템 CPU 시간 (틱)
	starttime=${20} # 부팅 후 프로세스 시작 시간 (틱)

	# TIME 계산 (HH:MM:SS)
	tot_ticks=$((utime + stime))
	tot_sec=$((tot_ticks / clk_tck))
	t_hrs=$((tot_sec / 3600))
	t_min=$(((tot_sec % 3600) / 60))
	t_sec=$((tot_sec % 60))
	time_str=$(printf "%02d:%02d:%02d" $t_hrs $t_min $t_sec)

	# STIME 계산 (시작 시각 HH:MM:SS)
	start_epoch=$((btime + (starttime / clk_tck)))
	stime_str=$(date -d "@$start_epoch" "+%H:%M:%S" 2>/dev/null)
	[ -z "$stime_str" ] && stime_str="?"

	# C (CPU 사용률 대략치 %)
	proc_age=$((now - start_epoch))
	if [ "$proc_age" -gt 0 ]; then
		c_val=$(((tot_sec * 100) / proc_age))
	else
		c_val=0
	fi

	# 4. CMD 추출 (null 문자를 공백으로 변환, 명령어 인자 전체 포함)
	cmd=$(tr '\0' ' ' <"$pid_dir/cmdline" 2>/dev/null)
	if [ -z "$cmd" ]; then
		cmd="[$name]"
	fi

	# 정렬하여 출력
	printf "%-8s %-7s %-7s %-3s %-8s %-10s %-8s %s\n" \
		"$uid" "$pid" "$ppid" "$c_val" "$stime_str" "$tty" "$time_str" "$cmd"
done
