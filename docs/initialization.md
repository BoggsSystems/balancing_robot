# Robot Initialization Flow

This document describes the end-to-end startup sequence from power-on to balanced upright.

## High-level sequence

1. Power on (arm down, balance off)
2. MCU init (clocks, UART, SPI, SysTick)
3. IMU init + chip ID verify
4. Motor driver init (step/dir/en)
5. IMU calibration (offsets)
6. ARM command received (enable)
7. Stand-up ramp (target pitch -25° → 0°)
8. Balanced ready (manual/scripted movement)

## Diagram

```
Power ON
  |
  v
MCU init: clocks + UART/SPI + SysTick
  |
  v
IMU init + chip ID check
  |
  v
Motor init (TMC2209), motors disabled
  |
  v
IMU calibration (roll/pitch offsets)
  |
  v
WAIT: DISARMED (arm down, balance off)
  |
  |  ARM command
  v
Enable motors
  |
  v
Stand-up ramp (target pitch -25° → 0° over ~1.5s)
  |
  v
BALANCED READY
  |
  +--> Manual drive (joystick / M:throttle,turn)
  |
  +--> Scripted modes (MODE:n)
  |
  +--> DISARM (arm down, balance off)
```

## Notes

- The stand-up ramp is performed by gradually moving the target pitch.
- During stand-up, throttle/turn and scripted motions are suppressed.
- DISARM returns to the resting pose and disables balance.
