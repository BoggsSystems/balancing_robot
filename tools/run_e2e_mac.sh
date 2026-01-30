#!/usr/bin/env bash
# Run full E2E on Mac: start e2e-bridge, run startup test, launch iOS app in Simulator.
# Usage: ./tools/run_e2e_mac.sh   (from repo root) or  bash tools/run_e2e_mac.sh

set -e
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

BRIDGE_PID_FILE="$REPO_ROOT/.e2e_bridge_pid"
APP_BUNDLE="$REPO_ROOT/ios_app/Robot_Controller/build/Build/Products/Debug-iphonesimulator/Robot_Controller.app"
BUNDLE_ID="BoggsSystems.Robot-Controller"

# Clean up any existing bridge PID from a previous run
cleanup_bridge() {
	if [[ -f "$BRIDGE_PID_FILE" ]]; then
		OLD_PID=$(cat "$BRIDGE_PID_FILE")
		if kill -0 "$OLD_PID" 2>/dev/null; then
			kill "$OLD_PID" 2>/dev/null || true
		fi
		rm -f "$BRIDGE_PID_FILE"
	fi
}

# Start e2e-bridge in background (make e2e-bridge blocks, so we build then run bridge)
echo "==> E2E: Building bridge and sim..."
make build
make -C firmware/tools sim

echo "==> E2E: Starting e2e-bridge on port 9001..."
cleanup_bridge
go run ./cmd/e2e-bridge --duration_s 0 &
BRIDGE_PID=$!
echo $BRIDGE_PID > "$BRIDGE_PID_FILE"

# Wait for bridge to listen on 9001
echo "==> E2E: Waiting for bridge..."
for i in {1..30}; do
	if nc -z 127.0.0.1 9001 2>/dev/null; then
		break
	fi
	[[ $i -eq 30 ]] && { echo "Timeout waiting for bridge on :9001"; cleanup_bridge; exit 1; }
	sleep 0.5
done

echo "==> E2E: Running startup test..."
python3 tools/e2e_startup_test.py
echo "==> E2E: Running movement test (MODE:1 circle)..."
python3 tools/e2e_movement_test.py

# Find booted simulator or boot iPhone 16 Plus
UDID=$(xcrun simctl list devices available | grep "Booted" | head -1 | sed -E 's/.*\(([A-F0-9-]{36})\).*/\1/')
if [[ -z "$UDID" ]]; then
	echo "==> E2E: Booting iPhone 16 Plus simulator..."
	xcrun simctl boot "iPhone 16 Plus" 2>/dev/null || true
	sleep 5
	UDID=$(xcrun simctl list devices available | grep "iPhone 16 Plus" | head -1 | sed -E 's/.*\(([A-F0-9-]{36})\).*/\1/')
fi
if [[ -z "$UDID" ]]; then
	echo "==> E2E: No iPhone 16 simulator found; skipping app launch."
else
	if [[ ! -d "$APP_BUNDLE" ]]; then
		echo "==> E2E: App not built. Build with: xcodebuild -project ios_app/Robot_Controller/Robot_Controller.xcodeproj -scheme Robot_Controller -destination 'platform=iOS Simulator,name=iPhone 16 Plus' -configuration Debug build"
	else
		echo "==> E2E: Installing and launching iOS app on simulator..."
		xcrun simctl install "$UDID" "$APP_BUNDLE"
		xcrun simctl launch "$UDID" "$BUNDLE_ID"
	fi
fi

echo ""
echo "=== E2E ready ==="
echo "  Bridge running (PID $BRIDGE_PID). In the app: Connect to E2E Bridge → Start."
echo "  To stop the bridge: kill \$(cat .e2e_bridge_pid)"
echo "  Or: pkill -f e2e-bridge"
