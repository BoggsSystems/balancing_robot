# Back Rest Arm

Physical arm that supports the robot from behind when balance is shut off. **Critical for safe shutdown**: if the arm is not down in time or the robot doesn’t tip backward onto it, the robot can fall forward on its nose.

## Purpose

- **Down (support)**: Catches the robot when balance is turned off so it falls **backward** onto the arm instead of forward.
- **Up (stowed)**: Retracted when the robot is balancing so it doesn’t interfere.

## Timing

- There is **critical timing** between:
  1. Lowering the arm, and  
  2. Shutting balance off so the robot falls backward onto the arm.
- If the arm is not down in time, or the robot is not made to fall backward intentionally, it can **fall forward on its nose**.

## Behavior

| Event | Arm |
|-------|-----|
| **START BALANCE** | Arm goes **UP** (stowed) |
| **Before shutting balance OFF** | Arm goes **DOWN** (support); then robot is allowed to fall back onto it |

## Hardware

| Item | Value |
|------|-------|
| **Servo** | Hitec HS-422 |
| **PWM** | TCC5 |
| **Pin** | PB10 |

*(Hitec HS-422: standard 1–2 ms pulse, ~50 Hz. Map TCC5/PB10 to the timer/channel on the target MCU.)*

## Firmware notes

- Drive the servo from TCC5 on PB10.
- **START BALANCE** (or equivalent “begin balance” from app/firmware) → set servo to **up** position.
- **Shutdown sequence**:  
  1. Set servo to **down** (support).  
  2. Wait for arm to reach position (or a fixed delay).  
  3. Disable balance / motors so the robot falls back onto the arm.

## App / protocol

- “START BALANCE” likely corresponds to today’s **Start** (streaming) or a future explicit “arm balance” command.
- The app sends **`DISARM`** for safe shutdown: firmware runs arm down → wait → disable balance. Use the **Disarm** (or "Stop balance") button for normal shutdown.
- **E‑Stop** is for emergencies only: it sends `M:0,0` immediately and does **not** run the arm sequence. Use E‑Stop when you need to kill motors right away; use Disarm when you want the robot to tip back onto the arm.

---

*Spec from hardware design; TCC5/PB10 to be mapped per target MCU (e.g. AVR-Dx vs SAME51).*
