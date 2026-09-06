#!/bin/sh
# Capture 6.7" App Store screenshots, then compose connected marketing frames.
# App Store Connect accepts 1284×2778 (portrait) for this display size.
#
# Usage:
#   ./Scripts/capture_app_store_screenshots.sh           # raw + marketing
#   ./Scripts/capture_app_store_screenshots.sh --raw-only
#   ./Scripts/capture_app_store_screenshots.sh --compose-only
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/AppStoreScreenshots/6.7-inch"
TARGET_WIDTH=1284
TARGET_HEIGHT=2778
UDID="${SIMULATOR_UDID:-DCCD7980-2B1A-4829-B6A9-13A81C65D6BE}"
BUNDLE_ID="com.hamptonsburgers.app"
DERIVED_DATA="$ROOT/.screenshot-derived-data"
APP="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/Hamptons Burgers.app"

RAW_ONLY=0
COMPOSE_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --raw-only) RAW_ONLY=1 ;;
    --compose-only) COMPOSE_ONLY=1 ;;
  esac
done

compose_marketing() {
  echo "→ Composing connected marketing frames"
  VENV="$ROOT/Scripts/.venv-screenshots"
  PYTHON="$VENV/bin/python"
  if [ ! -x "$PYTHON" ]; then
    echo "  Creating screenshot venv…"
    /opt/homebrew/bin/python3.11 -m venv "$VENV"
    "$VENV/bin/pip" install -q Pillow
  elif ! "$PYTHON" -c "import PIL" >/dev/null 2>&1; then
    "$VENV/bin/pip" install -q Pillow
  fi
  "$PYTHON" "$ROOT/Scripts/compose_marketing_screenshots.py"
}

if [ "$COMPOSE_ONLY" -eq 1 ]; then
  compose_marketing
  exit 0
fi

mkdir -p "$OUT"

echo "→ Building for simulator"
xcodebuild \
  -project "$ROOT/HamptonsBurgers.xcodeproj" \
  -scheme "Hamptons Burgers" \
  -destination "id=$UDID" \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  build >/dev/null

echo "→ Booting iPhone 15 Pro Max simulator"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null

echo "→ Cleaning status bar for marketing screenshots"
xcrun simctl status_bar "$UDID" override \
  --time "9:41" \
  --batteryState charged \
  --batteryLevel 100 \
  --wifiBars 3 \
  --cellularMode active \
  --cellularBars 4 >/dev/null

xcrun simctl install "$UDID" "$APP" >/dev/null

# Wipe prior simulator data so demo seeding starts clean.
xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$APP" >/dev/null

capture() {
  tab="$1"
  file="$2"
  echo "  • $file"
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl launch "$UDID" "$BUNDLE_ID" \
    -ScreenshotTab "$tab" \
    -ScreenshotDemo >/dev/null
  sleep 2.5
  xcrun simctl io "$UDID" screenshot "$OUT/$file"
  sips -z "$TARGET_HEIGHT" "$TARGET_WIDTH" "$OUT/$file" --out "$OUT/$file" >/dev/null
}

capture order "01-order.png"
capture rewards "02-rewards.png"
capture findus "03-find-us.png"
capture faq "04-faq.png"
capture account "05-account.png"

xcrun simctl status_bar "$UDID" clear >/dev/null

echo "→ Saved raw captures to $OUT (${TARGET_WIDTH}×${TARGET_HEIGHT})"
ls -lh "$OUT"

if [ "$RAW_ONLY" -eq 0 ]; then
  compose_marketing
fi
