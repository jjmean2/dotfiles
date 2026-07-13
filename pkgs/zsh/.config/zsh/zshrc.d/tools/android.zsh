[[ -d $HOME/Library/Android/sdk ]] || return 0

# Android SDK tools
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
path=($ANDROID_SDK_ROOT/emulator $path)
path=($ANDROID_SDK_ROOT/platform-tools $path)
path=($ANDROID_SDK_ROOT/cmdline-tools/latest/bin $path)
