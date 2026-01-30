# TMC2209 wiring reference

This file summarizes the wiring diagram for a TMC2209 stepper driver connected to a microcontroller.

![TMC2209 wiring diagram](/Users/jeffboggs/.cursor/projects/Users-jeffboggs-balancing-robot/assets/IMG_1624-c4e862ff-2db8-4de6-be66-9ccaeaf12e8f.png)

## Purpose

Use this diagram to connect a microcontroller (MCU) to a TMC2209 stepper driver, provide logic and motor power, and wire the motor coils.

## Connections shown

### MCU control signals

- `STEP` and `DIR` from the MCU drive step pulses and direction.
- `ENABLE` can be driven from the MCU to enable or disable the driver.
- `TX`/`RX` are optional UART pins for driver configuration (if used).
- `MS1/AD0` and `MS2/AD1` are configuration pins.
- `SPREAD` is for spreadCycle/stealthChop mode selection.

### Power

- **Logic supply**: 3 to 5 V to `VIO` and `GND`.
- **Motor supply**: 4.75 to 28 V to `VMOT` and `GND`.

### Motor wiring

- Motor coils connect to `1A/1B` and `2A/2B`.

### Current adjustment

- The diagram notes a **current adjustment resistor** on the driver board.

## Notes

- Ensure logic ground and motor ground are tied correctly as shown.
- Verify the pin labels on your specific TMC2209 board, as silkscreen can vary by manufacturer.
