# iOS App: Drive Controls — UX Narrative

## 1. Who and what

**User:** Someone operating the balancing robot from their phone. They’ve already connected (E2E bridge, BLE, or mock) and started IMU streaming. They see roll, pitch, yaw and the horizon.  

**Goal:** Drive the robot (forward/back, left/right) and use a few supporting controls, with behavior that we can simulate as much as possible in the Simulator (E2E and Mock) before moving to real hardware.

---

## 2. Current flow (baseline)

1. **Connect** → link to robot or E2E bridge.  
2. **Start** → begin R: P: Y: streaming; gauges and horizon update.  
3. **Attitude** → horizon, roll/pitch/yaw.  
4. **Controls** → LED toggle; Motors is a placeholder.  
5. **Disconnect** → stop streaming and disconnect.

Drive controls will slot into step 4 and stay usable whenever the user is connected and (at least) often when streaming is on.

---

## 3. Primary control: Drive (throttle + turn)

We need two continuous axes:

- **Throttle** (−1 … +1): forward / back.  
- **Turn** (−1 … +1): left / right.

They map to `M:throttle,turn`, which the sim and (later) firmware use in `motor_mix` with the balance output.

### 3.1 Control options

| Control       | Throttle        | Turn            | Simulator        | Notes                                      |
|---------------|-----------------|-----------------|------------------|--------------------------------------------|
| Virtual stick | Y (up/down)     | X (left/right)  | ✅ Works          | One finger, familiar, good for “drive feel”|
| Two sliders   | Slider 1        | Slider 2        | ✅ Works          | Precise, easy to simulate                  |
| D-pad / btns  | Fwd / Back      | Left / Right    | ✅ Works          | Simple; combo or hold for analog-ish       |
| Tilt device   | Pitch phone     | Roll phone      | ⚠️ Device only   | Simulator: off or mock with random/script  |

### 3.2 Recommended for v1: virtual joystick + optional sliders

- **Main:** One **virtual joystick**.  
  - Drag from center: up = positive throttle, down = negative; left/right = turn.  
  - Magnitude = command strength; release = return to center = 0,0.  
- **Optional (same screen or a “simple” mode):** Two **sliders** (Throttle, Turn) for users who prefer explicit values.  
- **Tilt:** Omit in v1 or hide in Simulator; on device we can add later and gate by `!simulator`.

So: we **simulate** drive by sending `M:throttle,turn` from the joystick (and sliders if present). In E2E, the bridge injects RC into the sim and R: P: Y: reflects the resulting motion. In Mock, we already bias `basePitch`/`baseRoll` from `M:` so the fake attitude responds. Both feel like “my input moves the robot” even without hardware.

---

## 4. Arm / Enable (gate for drive)

We need a rule for *when* drive commands are allowed:

- **Option A — Implicit:** Drive is allowed whenever **streaming is on**. No separate Arm. Simple; matches “I’ve started the robot, now I can drive.”  
- **Option B — Explicit Arm:** An **Arm** toggle (or button) must be ON before any drive. Safer on real hardware; extra step.  
- **Option C — Drive implies arm:** First drive command “arms” until Stop or E‑stop. Less discoverable.

**Recommendation for v1:** **Option A.** Treat “streaming on” as “drive enabled.” Arm can be added later as an explicit switch (and map to RC `enabled` or a new command) when we care more about real‑robot safety.

So in the narrative: **Drive controls are active when `isStreaming == true`.** If we add sliders or a joystick, we can gray them out or show a “Start streaming to drive” state when `!isStreaming`.

---

## 5. E‑Stop (emergency stop)

- **Role:** One obvious action: “stop drive **right now**.”  
- **Action:** Set throttle and turn to 0 and send `M:0,0` (and, if we add it, clear an Armed state or send a dedicated E‑STOP for firmware).  
- **Placement:** Always visible when drive exists: e.g. **red E‑Stop** at the top or bottom of the drive area, or a persistent strip. Tapping it:  
  - Zeroes the joystick / sliders in the UI.  
  - Sends `M:0,0` (and future E‑STOP if we have it).  
  - Does **not** disconnect or stop streaming by default (user can Disconnect separately).

**Simulation:** Sending `M:0,0` is enough for E2E and Mock; both sim and mock will effectively stop the added drive component. E‑Stop is therefore fully simulatable.

---

## 6. LED

- **Keep as today:** Toggle in the control panel.  
- **Placement:** With or near the other “utility” controls (e.g. Arm, if we add it), not mixed into the drive area, so the main block is “drive + E‑Stop.”

---

## 7. Layout and hierarchy

Rough order, top → bottom:

1. **Header** — BalanceBot, status badge (unchanged).  
2. **Start / Stop** — streaming (unchanged).  
3. **Horizon** — attitude (unchanged).  
4. **Roll / Pitch / Yaw** — gauges (unchanged).  
5. **Drive + E‑Stop** (new)  
   - **E‑Stop** — red, prominent (e.g. full‑width or a dedicated row).  
   - **Joystick** — centered, reasonable size (e.g. 140–180 pt).  
   - **Optional:** Throttle and Turn sliders below or in an “Advanced” section.  
6. **Control panel** — LED (and future Arm, settings, etc.).  
7. **Disconnect** — bottom (unchanged).

Drive is **above** the existing Control panel so it’s the primary action; E‑Stop is the first thing in that drive block so it’s hard to miss.

---

## 8. States and feedback

- **Connected, streaming off**  
  - Horizon/gauges: last values or zero.  
  - Drive: disabled (grayed or “Start streaming to drive”).  
  - E‑Stop: enabled (still send `M:0,0` if we want a “safe” state on connect).  

- **Connected, streaming on**  
  - Horizon/gauges: live.  
  - Drive: enabled. Joystick and sliders active.  
  - E‑Stop: enabled.  
  - Optional: tiny “M: x.xx, x.xx” or a “sending” indicator so the user knows commands are going out (useful in Simulator when we simulate).  

- **E‑Stop just tapped**  
  - Joystick springs to center; sliders to 0.  
  - `M:0,0` sent.  
  - Optional: short haptic and/or “Stopped” toast.  

- **Disconnected**  
  - Drive and E‑Stop disabled; no `M:` sent.

---

## 9. Simulation: what we can do

| Environment | Drive (M:)     | Attitude (R:P:Y:)     | E‑Stop     | Joystick / Sliders |
|-------------|----------------|------------------------|------------|---------------------|
| **E2E**     | Bridge → sim   | Sim → bridge → app    | M:0,0      | ✅ Touch/drag       |
| **Mock**    | basePitch/Roll | Mock timer + bias     | M:0,0      | ✅ Touch/drag       |
| **Device**  | BLE → robot    | BLE → app             | M:0,0      | ✅ Touch/drag       |

- **Joystick and sliders:** Pure UI; they work in Simulator.  
- **Tilt:** Needs device motion; in Simulator we hide or mock (e.g. random nudge) so the narrative stays “we simulate as much as we can.”  
- **E2E:** We already send `M:` and get back R: P: Y:; no change to protocol.  
- **Mock:** We already adjust `basePitch`/`baseRoll` from `motor`; we can tune the scaling so the simulated motion feels plausible.

---

## 10. Summary: UX in one paragraph

The user connects and starts streaming, then uses a **virtual joystick** (and optionally **sliders**) to send throttle and turn as `M:throttle,turn`. Drive is enabled only while streaming. A **red E‑Stop** zeroes and sends `M:0,0` immediately. The **LED** toggle stays in the control panel. In E2E, the sim’s response appears in the horizon and gauges; in Mock, our fake attitude is biased by `M:` so both modes simulate the effect of the controls. We avoid tilt in v1 so everything is simulatable in the Simulator; Arm remains optional for a later, hardware‑focused iteration.
