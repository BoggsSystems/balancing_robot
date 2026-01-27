# End-to-End Test (E2E)

Runs the full pipeline on the host and in the iOS Simulator:

**Prerequisites:** Go (e.g. `brew install go`). The Makefile will use `go` from PATH or `/opt/homebrew/bin/go` on macOS.

1. **Go IMU streamer** → simulated gyro/accel CSV (runs until Ctrl+C when `--duration_s 0`)
2. **Firmware sim** (`firmware/tools/sim`) → attitude filter + PID → `t,roll,pitch,balance,left,right`
3. **e2e-bridge** → merges IMU with live RC from the app, feeds sim; parses sim output, streams `R: P: Y:0` over TCP :9001
4. **iOS app** (Simulator) → connects to the bridge, taps **Start** to begin IMU telemetry, **Stop** to pause; can send `M:throttle,turn` to control the sim

No hardware or BLE; everything runs on the host + iOS Simulator. **Connection is separate from streaming:** after Connect, tap **Start** to receive `R: P: Y:`; tap **Stop** to pause. The app can **control** the simulated robot with `M:throttle,turn`, which the bridge injects as `RC,throttle,turn,1` into the sim.

## 1. Start the bridge

From the repo root:

```bash
make e2e-bridge
```

This builds `bin/imu-streamer` and `firmware/tools/sim`, then runs:

```
imu-streamer --config configs/default.yaml --duration_s 0 | firmware/tools/sim
```

and starts a TCP server on **:9001**. The bridge runs until you press **Ctrl+C**.

Options (via `go run ./cmd/e2e-bridge`):

- `--config` – imu-streamer config (default `configs/default.yaml`)
- `--port` – TCP port (default `9001`)
- `--duration_s` – imu-streamer duration, `0` = until Ctrl+C
- `--telemetry-hz` – max rate to send R: P: to clients (default `20`)
- `--imu-streamer` – path to binary (default `./bin/imu-streamer`)
- `--sim` – path to sim (default `./firmware/tools/sim`)

## 2. Run the iOS app

1. Open `ios_app/Robot_Controller/Robot_Controller.xcodeproj` in Xcode.
2. Choose an **iPhone Simulator** and run (⌘R).
3. Tap **Connect to E2E Bridge**.
4. Tap **Start** to begin IMU streaming; tap **Stop** to pause.

Connection and streaming are separate: after Connect, no `R: P: Y:` is sent until the app sends **START**. Tap **Start** to send `START` and receive roll/pitch from the sim (e.g. sine motion from `configs/default.yaml`). Tap **Stop** to send `STOP` and pause. When you add motor controls and send `M:throttle,turn`, the bridge forwards them to the sim.

## 3. START / STOP (gate IMU streaming)

The app sends:

- **START** – begin sending `R: P: Y:` to this client. No telemetry until START.
- **STOP** – pause; connection stays open.

The bridge keeps imu-streamer and sim running; it only sends telemetry to a client when that client has sent START.

## 4. Controlling the simulated robot

The app can send motor commands; when you wire `sendMotorCommand(throttle:turn:)` to a control (e.g. joystick or sliders), it sends `M:throttle,turn` to the bridge. The bridge injects `RC,throttle,turn,1` into the sim before the next IMU line, so the sim uses that for `motor_mix` (throttle and turn) until the next `M:` arrives. The sim’s balance PID always runs; RC adds forward/back and left/right.

## 5. Optional: run the bridge with custom config

```bash
make build
make -C firmware/tools sim
go run ./cmd/e2e-bridge --config configs/default.yaml --duration_s 0 --port 9001
```

Or use a config with different motion (e.g. `scripted`, `impulse_push`).
