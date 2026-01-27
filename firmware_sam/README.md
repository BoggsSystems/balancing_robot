# SAME51J20A Balancing Robot Firmware

Firmware port for the SAME51J20A Curiosity Nano with BMI088 IMU and TMC2209 stepper drivers.

## Hardware Configuration

| Component | Connection |
|-----------|------------|
| **IMU (BMI088)** | SERCOM1 SPI |
| SPI MOSI | PA16 |
| SPI SCK | PA17 |
| SPI MISO | PA19 |
| Accel CS | PA20 |
| Gyro CS | PA21 |
| **XBee Bluetooth** | SERCOM0 UART |
| UART TX | PA04 |
| UART RX | PA05 |
| **Motors (TMC2209)** | GPIO |
| Left STEP | PA08 |
| Left DIR | PA09 |
| Left EN | PA10 |
| Right STEP | PA11 |
| Right DIR | PA12 |
| Right EN | PA13 |
| **LED** | PA14 |
| **Back rest arm (Hitec HS-422)** | TCC5 PWM, PB10 |

> **Back rest arm**: Retracts (up) on START BALANCE; extends (down) before balance shutdown so the robot falls backward onto it. Critical timing — see `docs/back-rest-arm.md`.

## Prerequisites

Install the ARM GCC toolchain (macOS with Homebrew):

```bash
brew install arm-none-eabi-gcc
```

This provides `arm-none-eabi-gcc`, `arm-none-eabi-objcopy`, `arm-none-eabi-size`. The project is known to build with this toolchain.

## Build

```bash
make
```

## Flash (download to the MCU)

We **build** from the command line (`make`); we **do not use an IDE to compile**. To program the SAME51, load `build/balancing_robot.bin` (or `.elf`) with one of these:

### Recommended: Microchip MPLAB IPE

**MPLAB IPE** (Integrated Programming Environment) is a standalone flasher — no full IDE.

1. Download and install from [Microchip MPLAB IPE](https://www.microchip.com/en-us/tools-resources/develop/mplab-integrated-programming-environment).
2. Connect the **SAME51 Curiosity Nano** via USB (onboard **EDBG** debugger).
3. In IPE: choose device **ATSAME51J20A**, select `build/balancing_robot.bin`, then **Program**.

### Alternative: MPLAB X IDE

**MPLAB X IDE** is a full IDE. You can use it only to flash: create a simple project or use “Make and Program,” or build with `make` and use MPLAB X’s programming tool to load `build/balancing_robot.bin`. The Curiosity Nano’s EDBG is supported directly.

### Optional: OpenOCD (command line)

With an OpenOCD config for the SAME51 and the board’s CMSIS-DAP/EDBG interface, you can flash from the command line. Requires extra setup.

**Summary:** Use **MPLAB IPE** to download to the SAME51; no IDE is required for editing or building.

## Pin Adjustments

Edit pin definitions in:
- `src/sercom_spi.c` for SPI pins
- `src/sercom_uart.c` for UART pins
- `src/main.c` for motor and LED pins

## XBee Command Format

The XBee is expected to send ASCII lines:

```
throttle,turn,enable
```

Example:
```
0.20,-0.10,1
```

- `throttle`: -1.0 to 1.0 (forward/back)
- `turn`: -1.0 to 1.0 (left/right)
- `enable`: 0 or 1 (motors on/off)

## iPhone App

The iPhone app should:
1. Display roll, pitch, yaw in degrees
2. Have On/Off button (sends enable=0 or enable=1)
3. Optionally show motor speeds

## Notes

- Motor pins need to be confirmed with actual wiring
- PID gains will need tuning on real hardware
- TMC2209 microstepping is set by hardware pins (not software here)
