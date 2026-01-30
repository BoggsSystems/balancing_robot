# Movement Execution Trace

End-to-end flow from iOS Execute button to firmware/sim execution.

## Chain

```
iOS MovementDetailScreen [Execute]
  → AttitudeViewModel.selectMovement(pattern)
  → startMovement(movement)
  → bluetoothService.send(.movementMode(movement.mode))
  → Command.movementMode(mode).data  →  "MODE:<n>\n"

E2EBluetoothService.send
  → NWConnection.send("MODE:1\n")  [TCP to 127.0.0.1:9001]

e2e-bridge (cmd/e2e-bridge/main.go)
  → Read "MODE:1" from client
  → pendingMode = 1, pendingRC = true
  → Merge goroutine: before next IMU line, write "RC,throttle,turn,enabled,mode\n" to sim stdin
  → e.g. "RC,0,0,1,1\n"

firmware/tools/sim
  → Parse RC line → rc.mode = 1, rc.enabled = 1
  → if (rc.enabled && rc.mode != 0) → run scripted motion
  → mode 1: cmd_throttle=0.3, cmd_turn=0.2 (circle)
  → motor_mix(balance, cmd_throttle, cmd_turn)
  → Output: t,roll,pitch,balance,left,right
```

## Requirement: ARM before MODE

The sim only runs scripted motion when `rc.enabled == 1`. The bridge sets `pendingEnabled = lastEnabled`, and `lastEnabled` is set to 1 only when the client sends **ARM**.

**Implementation:** The app auto-sends ARM when **Start** is tapped (`startStreaming()`), so scripted movements execute without requiring a separate Arm tap. The Arm button on C&C remains for explicit re-arm after Disarm.

## Mode mapping (iOS → sim)

| MovementPattern | mode | Sim behavior |
|-----------------|------|--------------|
| manual | 0 | Joystick / M:throttle,turn |
| circle | 1 | cmd_throttle=0.3, cmd_turn=0.2 |
| figure8Default | 2 | sine turn, period 4s |
| figure8Slow | 3 | sine turn, period 6s |
| figure8Fast | 4 | sine turn, period 3s |
| spin | 5 | cmd_turn=0.35 |
| stopAndGo | 6 | burst/pause 2s |
| square | 7 | square path |
| slalom | 8 | sine turn 3s |
| balanceHoldUp | 9 | target_pitch +5° |
| balanceHoldDown | 10 | target_pitch -5° |
| balanceOscillate | 11 | target_pitch sine 10s |

## Testing

Run with bridge: `make e2e-bridge` (or `make run-e2e`) in one terminal.

- `tools/e2e_startup_test.py` – sends START, ARM, MODE:9, DISARM, STOP; verifies telemetry.
- `tools/e2e_movement_test.py` – sends START, ARM, MODE:1 (circle); verifies varying R/P (motion).

```bash
python3 tools/e2e_startup_test.py
python3 tools/e2e_movement_test.py
```

### Manual trace

Trigger a movement and stream telemetry to stdout:

```bash
python3 tools/trace_movement.py [mode] [duration_s]
```

Example: `python3 tools/trace_movement.py 1 6` — run circle (mode 1) for 6 seconds, print each R: P: Y: line with timestamp.
