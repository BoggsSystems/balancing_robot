# Testing Roadmap for the Balancing Robot

After the firmware is built and running (e.g. solid green LED after boot), use this order to test hardware and software.

## 1. Serial / UART sanity check

- **Goal:** Confirm the MCU is talking over the same UART the XBee (or USB-serial) uses.
- **Wiring:** XBee is on SERCOM0 UART (TX PA04, RX PA05), 115200 baud.

### Test from Mac without Xcode

You can run Step 1 from the repo using a serial monitor—no Xcode or iOS app needed.

1. **Install pyserial** (if needed): `pip install pyserial`
2. **Connect the robot** to the Mac:
   - **Option A – EDBG virtual serial:** Plug the Curiosity Nano in via USB. The EDBG may expose a virtual COM port; if it bridges the target UART (PA04/05) to USB, you’ll see the robot’s output on that port.
   - **Option B – USB-serial adapter:** Connect a USB–serial adapter: adapter **RX** → robot **TX (PA04)**, **GND** → **GND**. Leave the XBee disconnected from PA04/05 for this test, or use a second UART if your board has one.
3. **List ports:** `python3 tools/serial_monitor.py --list`  
   Note the port for the Nano or adapter (e.g. `/dev/cu.usbmodem*` or `/dev/cu.usbserial-*`).
4. **Run the monitor:**  
   `python3 tools/serial_monitor.py`  
   (It will pick a USB serial port if only one is present.)  
   Or specify the port:  
   `python3 tools/serial_monitor.py /dev/cu.usbmodem*`
5. **Reset or power-on the robot** (button or replug). You should see:
   - `SAME51 Balancing Robot Ready`
   - `Calibrating... hold still`
   - After ~200 samples (hold robot still): `Calibration done`  
   Then periodic telemetry lines (R: P: LM: RM: …).  
   **Ctrl+C** to quit the monitor.

**Firmware note:** The firmware sends all console output to **both** SERCOM0 (XBee, PA04/05) and **SERCOM5** (EDBG virtual serial on PB16/PB17). So after you **reprogram** the robot with the current build, boot messages and telemetry appear on the EDBG USB port when you open the serial monitor. If you still see no output, use Option B (USB-serial adapter on robot TX and GND).

### Other options

- **XBee connected:** Use the iOS app (or a Bluetooth serial terminal) that talks to the XBee; same messages should appear when the robot boots.
- **Pass:** Boot and calibration messages appear. **Fail:** If you see `BMI088 init failed`, the robot will blink and loop; check SPI wiring and IMU power.

## 2. IMU calibration

- **Goal:** Verify the BMI088 is read correctly and roll/pitch offsets are computed.
- **Steps:** Power on with the robot **held still** (e.g. resting on the bench or in hand). Wait for `Calibration done`.
- **Optional:** Use telemetry. The firmware prints lines like  
  `R:roll P:pitch ... LM:left_motor RM:right_motor ... ST:state BAL:balance ...`  
  every 50 samples. Tilt the robot slightly and confirm R/P values change in a sensible way (and return when you level it).
- **Pass:** Calibration completes and tilt angles look reasonable. **Fail:** No `Calibration done` or obviously wrong angles → recheck IMU wiring and BMI088 init.

## 3. XBee ↔ iOS app link

- **Goal:** Ensure the app and robot use the same protocol so enable/throttle/turn work.
- **Protocol:** The firmware expects ASCII lines: `throttle,turn,enable` or `throttle,turn,enable,mode`. Example: `0,0,1` = enable motors, no drive.
- **Steps:**
  - Pair/connect the iOS app to the XBee.
  - Send `0,0,1` (or use the app’s “On” / enable control if it sends that format).
  - Robot should enable motors and enter standup (see next step).
- **Pass:** Enabling from the app causes the robot to attempt standup (motors move). **Fail:** No response → check XBee wiring, baud (115200), and that the app sends lines in the expected format.

## 4. Motors and standup

- **Goal:** Confirm motor drivers (TMC2209) and wheel direction; see standup behavior.
- **Steps:**
  - With the robot **supported** (e.g. in hand or on a stand so it can’t fall), enable via app (`0,0,1`).
  - You should see/hear motors enable and a standup ramp: target pitch goes from about -25° to 0° over ~1.5 s.
  - Check that **left** and **right** wheels turn in the correct direction (no fighting each other). If one is reversed, fix in software (e.g. invert that motor’s command) or wiring.
- **Pass:** Motors enable, standup ramp runs, and directions look correct. **Fail:** One motor wrong direction → invert that side; no motion → check STEP/DIR/EN and TMC2209 power.

## 5. Balance and PID tuning

- **Goal:** Robot stands and holds balance; then add manual drive.
- **Steps:**
  - Place the robot on the ground (or use a back rest / safety if documented).
  - Enable from the app. Let it go through standup and try to balance.
  - If it oscillates or falls, tune PID in `main.c` (`pid_init(&pid, ...)`) and in `control.c` as needed. Typical order: P first, then D, then I.
  - Once stable, use the app to send small throttle/turn (e.g. `0.1,0,1` then `-0.1,0,1`) and confirm it drives forward/back and doesn’t spin unexpectedly.
- **Pass:** Robot balances and responds to throttle/turn. **Fail:** Unstable → retune PID; wrong response to throttle/turn → check motor mix and sign conventions.

## 6. Scripted motion (optional)

- **Goal:** Use firmware motion scripts (e.g. square, circle) from the app.
- **Protocol:** Send `throttle,turn,enable,mode` with `mode` set to the script index. See `motion_script.c` and the app for which mode number maps to which pattern.
- **Steps:** Enable robot, then switch to a scripted mode from the app; confirm the robot follows the intended pattern (e.g. square, figure-8) at a safe speed.
- **Pass:** Scripted paths match expectation. **Fail:** Wrong shape or no motion → check mode numbering and script implementation.

## Quick reference

| Test              | What to check                          | Pass condition                    |
|------------------|----------------------------------------|-----------------------------------|
| Serial            | Boot + calibration messages            | Messages at 115200                |
| IMU               | Calibration + tilt angles              | Calibration done; R/P sensible   |
| XBee + app        | Enable command                          | Robot enables / standup           |
| Motors            | Direction and standup                   | Both wheels correct; ramp runs   |
| Balance + PID     | Stand and manual drive                  | Balances; throttle/turn correct |
| Scripted motion   | Mode and path                          | Path matches script               |

## Pin reference (for debugging)

- **IMU (BMI088):** SERCOM1 SPI — MOSI PA16, SCK PA17, MISO PA19, Accel CS PA20, Gyro CS PA21  
- **XBee:** SERCOM0 UART — TX PA04, RX PA05, 115200  
- **Motors (TMC2209):** Left STEP/DIR/EN PA08/PA09/PA10, Right STEP/DIR/EN PA11/PA12/PA13  

See `firmware_sam/README.md` and `firmware_sam/src/main.c` for any pin or constant overrides (e.g. LED vs EN sharing).
