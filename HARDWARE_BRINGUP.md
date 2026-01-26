# Saturday Bring-Up Checklist (AVR64DD32 + BMI088)

Use this checklist to get from "power on" to "balanced test" quickly.

## 1) Software setup

- Install Cursor and open the repo folder.
- Verify Go + Python are installed:
  - `go version`
  - `python3 --version`
- Run the local end-to-end simulation:
  - `go test ./...`
  - `cd firmware/tools && make sim && cd ../..`
  - `go run ./cmd/imu-streamer --config configs/default.yaml | firmware/tools/sim > out_angles.csv`

## 2) Hardware inventory

- AVR64DD32 Curiosity Nano board
- BMI088 IMU module
- Motor driver board + motors + power supply
- USB cables for both MCU and (if needed) motor controller
- Wires and headers for SPI/UART

## 3) Wiring confirmation

- Decide **SPI** or **I2C** (SPI recommended for 500 Hz).
- Record the pin map:
  - SPI SCK, MOSI, MISO
  - Accel CS, Gyro CS
  - IMU power (3.3 V), ground
- Update these in firmware:
  - `firmware/src/spi.h`
  - `firmware/src/bmi088.c`

## 4) Build + flash firmware

- Install toolchain (macOS):
  - `brew install avr-gcc`
  - `pip3 install pymcuprog`
- Build + flash:
  - `cd firmware`
  - `make build EMU=0 BAUD=115200`
  - `make flash UPDI_PORT=/dev/tty.usbmodemXXXX`

## 5) Sensor bring-up

- Confirm BMI088 chip IDs (once registers are finalized).
- Log raw accel/gyro to UART and verify values change with movement.
- Set ODR/range in `bmi088_init()` when register map is ready.

## 6) Filter + control validation

- Verify calibration completes (message: "Calibration done").
- Observe roll/pitch output on UART.
- Inspect control output `U` for reasonable response.

## 7) Motor bring-up (safely)

- Lift wheels off ground first.
- Map `control` output to motor PWM (direction + magnitude).
- Verify response to manual tilt.

## 8) Final balancing test

- Place robot on ground.
- Adjust PID gains as needed.
- Increase output limits cautiously.

## Quick notes to fill in on Saturday

- BMI088 wiring:
  - SCK: _______
  - MOSI: ______
  - MISO: ______
  - CS accel: ___
  - CS gyro: ____
- UART port: _________
- UART baud: _________
- Motor driver + PWM range: __________________
