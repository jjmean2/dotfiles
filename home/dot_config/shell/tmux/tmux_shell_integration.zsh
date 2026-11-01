# vim:ft=zsh
# ==============================================================================
# tmux 용 셸 통합 (zsh)
# 위치: ~/.config/shell/tmux/tmux_shell_integration.zsh  (rc.zsh 가 $TMUX 안에서만 소싱)
# ==============================================================================
#
# 셸은 자기 바로 위의 터미널과 대화한다. tmux 안에서는 그 터미널이 tmux 다.
# Ghostty/iTerm2 의 셸 통합은 그 터미널이 직접 띄운 셸에만 주입되고, 주입돼도 tmux 는
# 받은 OSC 133 을 자기 그리드에 기록만 하고 바깥 터미널로 넘기지 않는다. 그래서 tmux 가
# 프롬프트/명령/출력의 경계를 알 수 있도록 셸이 tmux 에게 직접 마크를 보낸다.
#
# 마크(OSC 133, FinalTerm "시맨틱 프롬프트" 규약. iTerm2/Ghostty/kitty/WezTerm/tmux 공통):
#   ESC ] 133 ; A BEL             프롬프트 시작  (이 줄이 "프롬프트 줄")
#   ESC ] 133 ; B BEL             입력 영역 시작
#   ESC ] 133 ; P ; k=s BEL       이어지는(2차) 프롬프트 줄 - 멀티라인 명령의 PS2
#   ESC ] 133 ; C BEL             출력 시작      (preexec, 명령 실행 직전)
#   ESC ] 133 ; D ; <status> BEL  출력 끝 + 종료 코드 (precmd, 다음 프롬프트 직전)
#
# tmux 가 이 마크로 하는 일 (tmux 3.8 기준, man tmux 참고):
#   - copy-mode 의 previous-prompt / next-prompt (-o 는 출력 시작 줄로)  → tmux.conf 3절
#   - pane-shell-prompt / pane-command-started / pane-command-finished 훅
#   - pane_command_running / pane_command_status / pane_command_duration 포맷 변수
#     (tmux.conf 의 root M-S-Up 바인딩은 pane_command_running 으로 "프롬프트인가, 프로그램 실행 중인가"
#      를 판단해 실행 중이면 키를 프로그램에 넘긴다)
#
# 구현 메모:
#   - A/B 는 PS1 안에 %{...%} 로 넣어야 한다. precmd 에서 print 로 찍으면 ZLE 가 프롬프트
#     줄을 다시 그리면서 줄을 통째로 지우는데, tmux 는 줄을 비울 때 플래그도 초기화한다.
#     (Ghostty/iTerm2 스크립트가 PS1 을 건드리는 이유와 같다)
#   - $? 는 zsh 가 precmd 훅마다 원래 값으로 복원해 주므로 다른 precmd 훅과 순서가 섞여도 된다.
#   - tmux 안에서는 Ghostty/iTerm2 통합 스크립트를 함께 소싱하지 않는다. A 마크가 두 번 찍힌다.
#   - ssh 로 들어간 원격 셸에는 $TMUX 가 없어 원격 프롬프트는 마크되지 않는다 (알려진 한계).
#
# 확인 방법 (tmux 안에서):
#   false; tmux display -p '#{pane_command_status}'   → 1
#   print -r -- ${(V)PS1}                              → %{^[]133;A^G%} ... %{^[]133;B^G%}
#   Option+Shift+↑ = M-S-Up (tmux.conf 바인딩)         → 이전 프롬프트 줄로 이동

_tmux_shell_integration() {
    builtin emulate -L zsh -o no_warn_create_global -o no_aliases
    [[ -o interactive ]]        || builtin return 0
    [[ -n $TMUX ]]              || builtin return 0
    (( ! ${+_tmux_si_fd} ))     || builtin return 0   # 이미 로드됨 (source ~/.zshrc 재실행 대비)

    # stdout 이 리다이렉트돼도 마크가 tmux 에 닿도록 TTY 에 직접 쓰는 fd 를 연다.
    # cloexec 로 열어 자식 프로세스에 새지 않게 한다. 실패하면 stdout(1) 으로 보낸다.
    builtin typeset -gi _tmux_si_fd
    { builtin zmodload zsh/system && [[ -w $TTY ]] &&
      builtin sysopen -o cloexec -wu _tmux_si_fd -- $TTY } 2>/dev/null || (( _tmux_si_fd = 1 ))

    builtin typeset -g  _tmux_si_mark_a=$'%{\e]133;A\a%}'
    builtin typeset -g  _tmux_si_mark_b=$'%{\e]133;B\a%}'
    builtin typeset -g  _tmux_si_mark_p=$'%{\e]133;P;k=s\a%}'
    builtin typeset -gi _tmux_si_running=0

    _tmux_si_precmd() {
        builtin local cmd_status=$?
        # C 를 보낸 명령이 끝났을 때만 D 를 보낸다 (빈 프롬프트에서 Ctrl-C 를 눌러도 D 가 나가지 않음)
        if (( _tmux_si_running )); then
            builtin print -nu $_tmux_si_fd "\e]133;D;$cmd_status\a"
            _tmux_si_running=0
        fi
        # 매 프롬프트마다 확인해서, 다른 코드가 PS1 을 갈아엎어도 마크를 되살린다
        if [[ $PS1 != *$_tmux_si_mark_a* ]]; then
            # PS1 이 홀수 개의 % 로 끝나면 뒤에 붙는 %{ 와 합쳐지므로 % 를 하나 더 붙여 끊는다
            [[ $PS1 == *[^%]% || $PS1 == % ]] && PS1=$PS1%
            PS1=$_tmux_si_mark_a$PS1$_tmux_si_mark_b
        fi
        [[ $PS2 == *$_tmux_si_mark_p* ]] || PS2=$_tmux_si_mark_p$PS2
    }
    _tmux_si_preexec() {
        builtin print -nu $_tmux_si_fd '\e]133;C\a'
        _tmux_si_running=1
    }
    builtin autoload -Uz add-zsh-hook
    add-zsh-hook precmd  _tmux_si_precmd
    add-zsh-hook preexec _tmux_si_preexec
}
_tmux_shell_integration
builtin unfunction _tmux_shell_integration
