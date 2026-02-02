# SAME51J20A Balancing Robot Firmware

Firmware port for the SAME51J20A Curiosity Nano with BMI088 IMU and TMC2209 stepper drivers.

## Hardware Configuration

Pin layout follows **ARTU 3** wiring diagram; see repo root **`ARTU3_WIRING.md`** for the canonical map.

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
| **Motors (TMC2209)** | GPIO, PORTB (ARTU 3) |
| Left STEP | PB13 |
| Left DIR | PB0 |
| Left EN | PB1 |
| Right STEP | PB12 |
| Right DIR | PB7 |
| Right EN | PB6 |
| **G LED** | PA11 |
| **R LED** | PA10 |
| **LED (onboard)** | PA14 |
| **Back rest arm (Hitec HS-422)** | TCC5 PWM, PB10 |

> **Back rest arm**: Retracts (up) on START BALANCE; extends (down) before balance shutdown so the robot falls backward onto it. Critical timing — see `docs/back-rest-arm.md`.

## Prerequisites

Install the ARM GCC toolchain (macOS with Homebrew):

```bash
brew install arm-none-eabi-gcc
```

This provides `arm-none-eabi-gcc`, `arm-none-eabi-objcopy`, `arm-none-eabi-size`. The project is known to build with this toolchain.

## Build

Run `make` in this directory. That produces `build/balancing_robot.elf`, `build/balancing_robot.bin`, and `dist/default/production/firmware_sam.production.hex`. The `.hex` is created so **MPLAB X Run/Program** finds the image at the path it expects. **Do this first**; then program the MCU with MPLAB X, IPE, or the `.bin`/`.hex` file.

```bash
make
```

## Flash (download to the MCU)

After **building** (above), the file `build/balancing_robot.bin` exists. We **do not use an IDE to compile**; we use `make`. To program the SAME51, load that `.bin` with one of these:

### Recommended: Microchip MPLAB IPE

**MPLAB IPE** (Integrated Programming Environment) is a standalone flasher — no full IDE.

1. Download and install from [Microchip MPLAB IPE](https://www.microchip.com/en-us/tools-resources/develop/mplab-integrated-programming-environment).
2. Connect the **SAME51 Curiosity Nano** via USB (onboard **EDBG** debugger).
3. In IPE: choose device **ATSAME51J20A**, then select the **file** `build/balancing_robot.bin` (the firmware `make` produced) and click **Program**.

### Run through Xplab / MPLAB X IDE

**Goal:** Build, flash, and run the robot from the IDE.

1. **Open the project in Xplab (or MPLAB X IDE)**  
   - **File → Open Project** and select the `firmware_sam` folder.  
   - The project includes an `nbproject` so the IDE treats it as a **User Makefile** project (device **ATSAME51J20A**).  
   - If the IDE does not open it correctly, create a new **User Makefile Project**: **File → New Project → Microchip Embedded → User Makefile Project**, choose device **ATSAME51J20A**, set the project folder to `firmware_sam`, and use the existing **Makefile**.

2. **Build**  
   - **Run → Build Project** (or F11). The IDE runs `make` and produces `build/balancing_robot.elf` and `build/balancing_robot.bin`.

3. **Connect hardware**  
   - Connect the **SAME51 Curiosity Nano** via USB (onboard **EDBG**).  
   - In **Project Properties → Conf: [default] → Curiosity**, ensure the **EDBG** tool is selected (e.g. **Curiosity Nano EDBG (ATSAME51J20A)**).

4. **Run / debug**  
   - **Run → Run Project** (F6) or **Run → Debug Project** (Ctrl+F5) to program the device and start the firmware. The IDE uses the built-in programmer to load the built image.

**Summary:** Open `firmware_sam` in Xplab, build, connect the Curiosity Nano, then Run or Debug to program and run the robot.

### Optional: OpenOCD (command line)

With an OpenOCD config for the SAME51 and the board’s CMSIS-DAP/EDBG interface, you can flash from the command line. Requires extra setup.

**Summary:** You can use **MPLAB IPE** to download only, or use **Xplab / MPLAB X IDE** to build, program, and run from the IDE (see **Run through Xplab / MPLAB X IDE** above).

### Cursor / VS Code with MPLAB extensions

You can build, program, and debug from **Cursor** (or VS Code) using the **MPLAB Extension Pack**.

**Prerequisites**

- **MPLAB Extension Pack** installed: **Extensions** (Cmd+Shift+X) → search **MPLAB** → install **MPLAB Extension Pack**, or run: `cursor --install-extension Microchip.mplab-extension-pack`.
- **ARM GCC** toolchain: `brew install arm-none-eabi-gcc` (used by the Makefile). The MPLAB project is set to use **ARM GCC** (not XC32). If the extension says a compiler is not installed, either: (1) use **Run Build Task** (Cmd+Shift+B) and choose **Build firmware (make)** — that uses your existing `arm-none-eabi-gcc` and does not need XC32; or (2) click **Download and install** for **arm-gcc 14.2.1** in the MPLAB pop-up so the extension’s own build can run.
- **Curiosity Nano** connected via USB (data-capable cable).

**Workflow**

1. **Open the repo** in Cursor: **File → Open Folder** and select the **balancing_robot** repo root (not only `firmware_sam`). The repo has `.vscode/tasks.json`, `launch.json`, and `balancing_robot.mplab.json` at the root.

2. **Build**: **Terminal → Run Build Task** (Cmd+Shift+B). This runs `make` in `firmware_sam` and produces `firmware_sam/build/balancing_robot.elf` and `firmware_sam/build/balancing_robot.bin`. The MPLAB project config (`.vscode/balancing_robot.mplab.json`) points the debugger at this `.elf`.

3. **Set device and tool** (first time or when changing board):
   - **Command Palette** (Cmd+Shift+P) → **MPLAB: Edit Project Properties (UI)** (or **Edit Project Properties (JSON)**).
   - Ensure **device** is **ATSAME51J20A** and **Connected Hardware Tool** is **Curiosity Nano EDBG** (or EDBG with serial number). With the Nano plugged in, the tool should appear in the dropdown; if not, try another USB cable/port and **System Information → USB** to confirm the board is seen.

4. **Program / run**: **Run and Debug** view (Ctrl+Shift+D or Cmd+Shift+D), select **MPLAB Debug (balancing_robot)**, then click **Start Debugging** (F5) or the green play button. The launch config runs **Build firmware (make)** first, then programs the Nano and starts the firmware. To run without debugging, use the same configuration; the adapter will program and run.

5. **Debug**: Set breakpoints in `firmware_sam/src/*.c`, then F5. Use the debug toolbar (pause, step, continue) and variable/watch views as usual.

**What’s in the repo**

- **`.vscode/tasks.json`** (repo root): **Build firmware (make)** runs `make` in `firmware_sam`; **Clean firmware** runs `make clean`.
- **`.vscode/launch.json`**: **MPLAB Debug (balancing_robot)** uses the MPLAB debug adapter and the default configuration; **preLaunchTask** runs **Build firmware (make)** before programming so F5 builds then flashes and debugs.
- **`.vscode/balancing_robot.mplab.json`**: MPLAB project file; device ATSAME51J20A, image path `firmware_sam/build/balancing_robot.elf`. Edit here or via **MPLAB: Edit Project Properties** if you need to change device/tool or paths.
- **`firmware_sam/.vscode/tasks.json`**: Same build/clean tasks when you open only the `firmware_sam` folder.

**If the Curiosity Nano doesn’t appear as a tool**: Unplug/replug USB, try another cable/port, and check **System Information → USB**. Install **EDBG_TP** (Tool Packs) in MPLAB X if you use the full IDE; the VS Code extension uses the same tool support.

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
