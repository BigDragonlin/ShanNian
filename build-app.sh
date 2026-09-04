#!/bin/zsh
set -e

# 编译 Swift 程序，再整理成 Finder 中可以双击的标准 .app 软件包。
PROJECT_DIR="${0:A:h}"
APP_DIR="$PROJECT_DIR/outputs/闪念.app"

cd "$PROJECT_DIR"
mkdir -p "$PROJECT_DIR/work/swift-cache" "$PROJECT_DIR/work/clang-cache" \
    "$PROJECT_DIR/work/config" "$PROJECT_DIR/work/security"

# 把编译缓存放在项目内，避免受 macOS 的文件夹权限影响。
SWIFTPM_MODULECACHE_OVERRIDE="$PROJECT_DIR/work/clang-cache" \
CLANG_MODULE_CACHE_PATH="$PROJECT_DIR/work/clang-cache" \
swift build -c release --disable-sandbox \
    --cache-path "$PROJECT_DIR/work/swift-cache" \
    --config-path "$PROJECT_DIR/work/config" \
    --security-path "$PROJECT_DIR/work/security"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp ".build/release/ShanNian" "$APP_DIR/Contents/MacOS/ShanNian"
cp "AppResources/Info.plist" "$APP_DIR/Contents/Info.plist"
chmod +x "$APP_DIR/Contents/MacOS/ShanNian"

# 本地签名让 macOS 能稳定识别这是同一个应用，并正确保存位置权限。
codesign --force --deep --sign - "$APP_DIR"
echo "$APP_DIR"
