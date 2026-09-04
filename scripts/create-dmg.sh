#!/bin/zsh
set -e

# 把编译好的“闪念.app”装进标准 DMG 安装镜像。
# 用户打开 DMG 后，可以把软件拖进旁边的“应用程序”文件夹。
PROJECT_DIR="${0:A:h:h}"
APP_PATH="$PROJECT_DIR/outputs/闪念.app"
DMG_PATH="$PROJECT_DIR/outputs/ShanNian-macOS.dmg"
STAGING_DIR="$PROJECT_DIR/work/dmg"

if [[ ! -d "$APP_PATH" ]]; then
    echo "没有找到闪念.app，请先运行 ./build-app.sh"
    exit 1
fi

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/闪念.app"
ln -s /Applications "$STAGING_DIR/应用程序"

rm -f "$DMG_PATH"
hdiutil create \
    -volname "闪念" \
    -srcfolder "$STAGING_DIR" \
    -format UDZO \
    -ov \
    "$DMG_PATH"

echo "$DMG_PATH"
