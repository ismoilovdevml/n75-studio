#!/usr/bin/env bash
# Build N75 Studio. `./build.sh` builds to build/Release; `./build.sh install`
# also copies the app to /Applications and launches it.
set -euo pipefail

cd "$(dirname "$0")"

CONFIG=Release
APP="build/$CONFIG/N75Studio.app"
# A stable signing identity makes the Input Monitoring grant stick across relaunches
# (ad-hoc signatures change every build, and macOS then asks again). See README.
IDENTITY="${N75_SIGN_IDENTITY:-N75Studio Local Signing}"

echo "==> Building $CONFIG"
xcodebuild -project N75Studio.xcodeproj -target N75Studio -configuration "$CONFIG" \
    CODE_SIGNING_ALLOWED=NO build | tail -1

if security find-identity -v -p codesigning | grep -qF "$IDENTITY"; then
    echo "==> Signing with \"$IDENTITY\""
    codesign --force --deep --options runtime \
        --entitlements N75Studio/N75Studio.entitlements \
        --sign "$IDENTITY" "$APP"
else
    echo "==> \"$IDENTITY\" not found, signing ad hoc"
    echo "    (macOS will re-ask for Input Monitoring after every build — see README)"
    codesign --force --deep --options runtime \
        --entitlements N75Studio/N75Studio.entitlements --sign - "$APP"
fi

codesign --verify --strict "$APP" && echo "==> Signature valid"

if [ "${1:-}" = "install" ]; then
    echo "==> Installing to /Applications"
    osascript -e 'quit app "N75Studio"' 2>/dev/null || true
    sleep 1
    rm -rf /Applications/N75Studio.app
    cp -R "$APP" /Applications/
    open -a /Applications/N75Studio.app
fi

echo "==> Done: $APP"
