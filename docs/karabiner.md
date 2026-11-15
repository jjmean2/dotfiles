# 한글 상태에서 tmux prefix / Esc (macOS)

입력기가 Ghostty 앞단에서 평문자를 가로채 조합하므로, 한글 상태에서는
`prefix c` 의 `c` 가 tmux 에 닿지 않고 vim normal 모드도 자모를 받는다. tmux 는 입력기 상태를 알 수 없어 자체 해법이 없다.
그래서 Karabiner-Elements 규칙(`home/dot_config/private_karabiner/private_karabiner.json`)이 Ghostty 가 앞에 있고 입력기가 한글일 때
`ctrl+b` / `Esc` / `ctrl+[` 를 "영문 전환 + 그 키" 로 바꾼다. 제어 조합은 입력기를 통과하므로 전환이 늦어도 prefix 는 들어가고,
뒤따르는 키는 영문 상태에서 들어간다. 부작용은 zsh/nvim 에서 `ctrl+b` 를 눌러도 영문으로 바뀌는 것 하나다.
이 머신에서 아예 쓰지 않으려면 기능 스위치 `features.karabiner = false` (설치도, 설정 배포도 하지 않는다. [규칙의 "머신별 기능"](conventions.md#머신별-기능)).
잠깐 끄려면 Karabiner 설정 창 Complex Modifications 탭에서 규칙을 끄거나 메뉴바에서 Quit. 설정 창에서 뭔가 바꾸면 Karabiner 가
`karabiner.json` 을 다시 써서 `chezmoi status` 에 차이가 생기므로, 유지할 변경은 `chezmoi re-add` 로 가져온다.
