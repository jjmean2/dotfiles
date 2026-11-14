# shellcheck shell=sh
# Android SDK tools (emulator, adb, sdkmanager 등)
if [ -d "$HOME/Library/Android/sdk" ]; then
	export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
	PATH="$ANDROID_SDK_ROOT/emulator:$PATH"
	PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"
	PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
fi
