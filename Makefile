BIN_DIR := bin
# Prefer go from PATH; fallback to Homebrew on macOS if not in PATH
GO := $(or $(shell command -v go 2>/dev/null),$(shell ([ -x /opt/homebrew/bin/go ] && echo /opt/homebrew/bin/go)),go)

.PHONY: build run test lint e2e-bridge e2e

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
