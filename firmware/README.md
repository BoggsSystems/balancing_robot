# AVR64DD32 firmware scaffold

This folder contains a minimal AVR64DD32 firmware scaffold for the Curiosity Nano.

## Prerequisites (macOS)

- avr-gcc toolchain (via `brew install avr-gcc`)
- pymcuprog (via `pip3 install pymcuprog`)
- screen (built-in)

## Build

```bash
make build
```

## Flash (UPDI via Curiosity Nano)

Set the serial port used by the onboard debugger (UPDI):

```bash
make flash UPDI_PORT=/dev/tty.usbmodemXXXX
```

## Monitor UART

Set the UART serial device exposed by the target (if bridged):

```bash
make monitor UART_PORT=/dev/tty.usbmodemYYYY BAUD=115200
```

## Notes

- Default `F_CPU` is 4 MHz (internal oscillator). Adjust if you change clocks.
- Pin mappings for SPI/UART are defined in `src/uart.h` and `src/spi.h`.
- BMI088 register details are stubbed; update as needed for your wiring.
- Emulator input mode is enabled by default (`EMU=1`) and expects CSV lines:
  `t,gx,gy,gz,ax,ay,az` (SI units). Disable with `make build EMU=0`.
- For 500 Hz CSV streaming, use a higher UART baud (e.g. `BAUD=460800`).
- Optional RC input (assumed format) can be streamed over UART:
  `throttle,turn,enable` where throttle/turn are in [-1,1].

## No hardware? Use the host simulator

You can run the same Kalman filter on your Mac and feed it the Go emulator output.

```bash
cd firmware/tools
make sim
cd ../..
go run ./cmd/imu-streamer --config configs/default.yaml | firmware/tools/sim > out_angles.csv
```

Output CSV: `t,roll,pitch,balance,left,right`

### Simulated RC input (optional)

You can drive throttle/turn with a simple time-stamped CSV:

```
t,throttle,turn,enable
0.0,0.0,0.0,1
1.0,0.2,0.0,1
2.0,0.2,0.3,1
4.0,0.0,0.0,0
```

Run the sim with:

```bash
go run ./cmd/imu-streamer --config configs/default.yaml | firmware/tools/sim --rc rc_profile.csv > out_angles.csv
```

If you include a 5th column, `mode`, the simulator will run the scripted
motions (1=circle, 2-4=figure-8 variants, 5=spin, 6=stop-go,
7=square, 8=slalom, 9-11=balance challenge). Example:

```
t,throttle,turn,enable,mode
0.0,0.0,0.0,1,1
2.0,0.0,0.0,1,2
6.0,0.0,0.0,1,3
12.0,0.0,0.0,1,4
18.0,0.0,0.0,0,0
```

### Fixed-rate control loop (heartbeat)

To mirror the firmware's fixed-rate control loop, run the simulator with a
fixed control cadence:

```bash
go run ./cmd/imu-streamer --config configs/default.yaml | firmware/tools/sim --control-hz 400 > out_angles.csv
```

### Step pulse emulator

To emulate step pulse generation at a fixed tick rate, add `--step-hz`.
This produces `pos_left` and `pos_right` columns with the cumulative
step count per motor:

```bash
go run ./cmd/imu-streamer --config configs/default.yaml | firmware/tools/sim --control-hz 400 --step-hz 10000 > out_angles.csv
```

### Trace scripted commands

Add `--trace` to include the selected mode and the effective command
throttle/turn in the output columns:

```bash
go run ./cmd/imu-streamer --config configs/default.yaml | firmware/tools/sim --rc rc_profile_scripted.csv --control-hz 400 --step-hz 10000 --trace > out_angles.csv
```
