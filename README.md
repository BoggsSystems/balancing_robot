# IMU Streamer (BMI088-like emulator)

Go-based IMU data streaming emulator that produces 6-axis gyro+accel samples with configurable motion profiles.

## Build and run

```bash
make build
./bin/imu-streamer --config configs/default.yaml
```

Or run directly:

```bash
go run ./cmd/imu-streamer --config configs/default.yaml
```

## Output formats

### Stdout CSV (default)

```bash
go run ./cmd/imu-streamer --config configs/default.yaml > out.csv
```

CSV header: `t,gx,gy,gz,ax,ay,az`

### UDP CSV

```bash
go run ./cmd/imu-streamer --config configs/default.yaml --udp --udp_addr 127.0.0.1:9000
```

### UDP binary

Set in config:

```yaml
udp:
  enabled: true
  addr: "127.0.0.1:9000"
  format: "binary"
```

Binary packet: 7 little-endian float64 values in order `t,gx,gy,gz,ax,ay,az`.

## Motion profiles

- `static`: no motion
- `slow_tilt`: 0 -> +amplitude -> 0 over `duration_s`
- `sine`: pitch = amplitude * sin(2π f t)
- `impulse_push`: brief angular velocity spike on axis
- `scripted`: sequence of segments (each segment can be any profile)

## Example config fields

```yaml
rate_hz: 500
duration_s: 10
units: "si" # "si" (rad/s) or "deg" (deg/s)
seed: 1
motion:
  type: "sine"
  amplitude_deg: 5
  freq_hz: 1.0
gyro_noise_std: 0.01
accel_noise_std: 0.05
gyro_bias: [0.02, -0.01, 0.005]
gyro_bias_drift_std: 0.0001
vibration_burst:
  enabled: false
  amplitude: 0.2
  freq_hz: 20
  duty_cycle: 0.1
udp:
  enabled: false
  addr: "127.0.0.1:9000"
  format: "csv" # "csv" or "binary"
```

## Plot CSV output

```bash
go run ./cmd/imu-streamer --config configs/default.yaml > out.csv
python3 tools/plot_csv.py out.csv
```

## Axis conventions

Defined in `internal/model/frames.go`:

- World frame: X forward, Y right, Z up. Gravity points toward -Z.
- Body frame: X forward, Y right, Z up (aligned with world at zero angles).
- Euler angles: roll about +X, pitch about +Y, yaw about +Z (right-hand rule).
- When level and stationary, accel reads `(0, 0, +g)`.

## Makefile targets

- `make build`
- `make run`
- `make test`
- `make lint` (placeholder)

## AVR64DD32 firmware (Cursor CLI workflow)

Firmware scaffold lives in `firmware/` and builds/flashes from the terminal.

```bash
cd firmware
make build
make flash UPDI_PORT=/dev/tty.usbmodemXXXX
make monitor UART_PORT=/dev/tty.usbmodemYYYY BAUD=115200
```

See `firmware/README.md` for details.
