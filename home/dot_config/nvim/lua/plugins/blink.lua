-- 자동완성 메뉴를 수동으로 띄우는 키에 Shift+Option+Space 를 추가한다. 기본 <C-Space> 는 그대로 둔다.
-- 왜: macOS 에서 <C-Space> 는 입력 소스(한/영) 전환과 겹치고, Option+Space 는 Raycast 에서
--     Ghostty 호출용 글로벌 핫키로 쓰고 있어서 nvim 까지 오지 않는다.
-- 전제: Shift 가 살아서 와야 한다. 전통적인 터미널 인코딩에서는 ⇧⌥Space 가 ⌥Space 와 똑같이
--     ESC Space 로 오므로, Ghostty 의 Kitty Keyboard Protocol 과 tmux extended-keys(csi-u) 에 기댄다.
--     Option 은 왼쪽만 Alt 로 동작한다 (ghostty config 의 macos-option-as-alt = left).
-- 확인: insert 모드에서 <C-v> 를 누른 뒤 ⇧⌥Space → <S-M-Space> 가 찍혀야 한다 (<M-Space> 나 ^[ 면 미적용).
return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      ["<S-M-Space>"] = { "show", "show_documentation", "hide_documentation" },
    },
  },
}
