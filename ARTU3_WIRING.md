# ARTU 3 wiring diagram

This document captures the handwritten wiring diagram labeled "ARTU 3" for the balancing robot.

![ARTU 3 wiring diagram](/Users/jeffboggs/.cursor/projects/Users-jeffboggs-balancing-robot/assets/IMG_1627-ef277e16-23c0-468c-9e99-65ce898b01e9.png)

## Key notes from the diagram

- MCU: **SAME51J20A**.
- IMU + LCD SPI: `MOSI`, `MISO`, `SCK`, `CS`.
- XBee UART: `CTS`, `TX`, `RX`.
- IMU signals: `ACCEL CS`, `GYRO CS`, `ACCEL INT`.
- LEDs: `R LED`, `G LED`.
- Stepper driver control (right side of MCU):
  - `R = ENABLE`
  - `R = DIRECTION`
  - `R = STEP (TC2)`
  - `L = DIRECTION`
  - `L = ENABLE`
- `TC1` is noted for `L = STEP`.
- Servo output: `SERVO PWM (TC5)`.

## SAME51J20A pin map (from ARTU 3 diagram)

Use this as the single source of truth; firmware matches this layout.

| ARTU 3 signal   | SAME51 pin | Notes                    |
|-----------------|------------|--------------------------|
| **G LED**       | **PA11**   | Green status LED         |
| **R LED**       | **PA10**   | Red status LED           |
| Left STEP       | PB13       | TC2 (L = STEP)           |
| Left DIR        | PB0        |                          |
| Left EN         | PB1        |                          |
| Right STEP      | PB12       | TCCO                     |
| Right DIR       | PB7        |                          |
| Right EN        | PB6        |                          |
| Servo PWM (TC5) | PB10       | Back rest arm (Hitec MS)  |
| XBee UART       | PA04 TX, PA05 RX | SERCOM0 (firmware) |
| IMU SPI         | PA16–21    | SERCOM1, Accel/Gyro CS    |

R+L refer to step motor controller. Onboard LED (Curiosity Nano) is PA14.

## Legend

- `R` and `L` refer to the **right** and **left** stepper motor controllers.
- `XBee TX/RX` is the UART for XBee Bluetooth.
- Notes at bottom:
  - `*` = functional test OK
  - `.` = ohm meter check OK
  - Marked as `R2.1`.
