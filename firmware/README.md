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
