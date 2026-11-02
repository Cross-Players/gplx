#!/bin/bash
# Capture App Store screenshots on an iOS simulator.
# Usage: screenshots/capture.sh <simulator-udid> <output-dir>
set -euo pipefail
UDID=$1
OUT=$2
mkdir -p "$OUT"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl status_bar "$UDID" override --time "9:41" \
  --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 \
  --batteryState charged --batteryLevel 100

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/store_screenshots_test.dart \
  --dart-define-from-file=lib/env/production.json \
  -d "$UDID" 2>&1 | while IFS= read -r line; do
    echo "$line"
    if [[ $line =~ SHOT:([A-Za-z0-9_]+) ]]; then
      xcrun simctl io "$UDID" screenshot "$OUT/${BASH_REMATCH[1]}.png" >/dev/null 2>&1
    fi
  done
