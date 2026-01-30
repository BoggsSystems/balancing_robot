BIN_DIR := bin
# Prefer go from PATH; fallback to Homebrew on macOS if not in PATH
GO := $(or $(shell command -v go 2>/dev/null),$(shell ([ -x /opt/homebrew/bin/go ] && echo /opt/homebrew/bin/go)),go)

.PHONY: build run test lint e2e-bridge e2e run-e2e e2e-test voice-input

build:
	mkdir -p $(BIN_DIR)
	$(GO) build -o $(BIN_DIR)/imu-streamer ./cmd/imu-streamer

run:
	$(GO) run ./cmd/imu-streamer --config configs/default.yaml

test:
	$(GO) test ./...

lint:
	@echo "lint placeholder"

# End-to-end: imu-streamer | firmware/tools/sim, TCP :9001 for iOS app
e2e-bridge: build
	$(MAKE) -C firmware/tools sim
	$(GO) run ./cmd/e2e-bridge --duration_s 0

e2e: e2e-bridge

# Run full E2E on Mac: bridge + startup test + launch iOS app (see tools/run_e2e_mac.sh)
run-e2e:
	@bash tools/run_e2e_mac.sh

# Run E2E Python tests (bridge must be running: make e2e-bridge in another terminal)
e2e-test:
	@python3 tools/e2e_startup_test.py && python3 tools/e2e_movement_test.py

# Open Dictation settings and show how to use voice input in Cursor
voice-input:
	@bash tools/run_voice_input_mac.sh
