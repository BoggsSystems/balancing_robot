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

## Prerequisites

Install ARM toolchain:

```bash
brew install --cask gcc-arm-embedded
# or
brew install arm-none-eabi-gcc
```

## Build

```bash
make
```

## Flash

Use Microchip MPLAB IPE, Segger J-Link, or OpenOCD with the onboard debugger.

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
