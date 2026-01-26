BIN_DIR := bin

.PHONY: build run test lint

build:
	mkdir -p $(BIN_DIR)
	go build -o $(BIN_DIR)/imu-streamer ./cmd/imu-streamer

run:
	go run ./cmd/imu-streamer --config configs/default.yaml

test:
	go test ./...

lint:
	@echo "lint placeholder"
