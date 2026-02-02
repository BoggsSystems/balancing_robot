#!/usr/bin/env python3
"""E2E telemetry trace: connect to bridge, run a movement, print every line with R,P,Y,DIST,VEL,ACC.

Use this to verify the full pipeline (bridge → telemetry format → app parsing) for path plotting.
Run with bridge up: make e2e-bridge (in another terminal), then:
  python3 tools/trace_telemetry_e2e.py [MODE] [SECONDS]
  MODE: 1=circle, 5=spin, default 1. SECONDS: how long to collect, default 4.
"""
import socket
import sys
import time
import re

HOST = "127.0.0.1"
PORT = 9001


def parse_telemetry(line):
    """Parse R: P: Y: DIST: VEL: ACC: from a line. Returns dict or None."""
    if not line.strip().startswith("R:"):
        return None
    out = {}
    for part in line.split():
        if part.startswith("R:"):
            out["R"] = float(part[2:])
        elif part.startswith("P:"):
            out["P"] = float(part[2:])
        elif part.startswith("Y:"):
            out["Y"] = float(part[2:])
        elif part.startswith("DIST:"):
            out["DIST"] = float(part[5:])
        elif part.startswith("VEL:"):
            out["VEL"] = float(part[4:])
        elif part.startswith("ACC:"):
            out["ACC"] = float(part[4:])
    return out if "R" in out and "P" in out else None


def main():
    mode = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    seconds = float(sys.argv[2]) if len(sys.argv) > 2 else 4.0

    print(f"Connecting to {HOST}:{PORT}...")
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(5.0)
    try:
        s.connect((HOST, PORT))
    except OSError as e:
        print(f"ERROR: Could not connect. Is e2e-bridge running? (make e2e-bridge)\n{e}")
        return 1

    print("Sending START, ARM, MODE:{}...".format(mode))
    for cmd in [b"START\n", b"ARM\n", ("MODE:%d\n" % mode).encode()]:
        s.sendall(cmd)
        time.sleep(0.2)

    print("Collecting telemetry (expect R P Y DIST VEL ACC for path plotting)...\n")
    lines = []
    start = time.time()
    while time.time() - start < seconds:
        try:
            data = s.recv(4096)
            if not data:
                break
            lines.extend(data.decode("utf-8", errors="ignore").splitlines())
        except socket.timeout:
            break

    s.sendall(b"MODE:0\n")
    s.sendall(b"STOP\n")
    s.close()

    # Report raw lines and parsed fields
    telemetry = [ln for ln in lines if ln.strip().startswith("R:")]
    print("Total telemetry lines:", len(telemetry))
    if not telemetry:
        print("No R: lines received. Check bridge is sending DIST/VEL/ACC.")
        return 1

    # Sample first, mid, last
    for i in [0, len(telemetry) // 2, len(telemetry) - 1]:
        if i < 0 or i >= len(telemetry):
            continue
        ln = telemetry[i]
        parsed = parse_telemetry(ln)
        print("\n--- Line", i + 1, "---")
        print("Raw:", ln)
        if parsed:
            print("Parsed: R={} P={} Y={} DIST={} VEL={} ACC={}".format(
                parsed.get("R"), parsed.get("P"), parsed.get("Y"),
                parsed.get("DIST"), parsed.get("VEL"), parsed.get("ACC")))
            if "DIST" not in parsed or "VEL" not in parsed or "ACC" not in parsed:
                print("WARNING: Missing DIST/VEL/ACC - path plot needs these.")
        else:
            print("WARNING: Could not parse (need R: P: and ideally DIST: VEL: ACC:)")

    # Path plot needs: velocity (for displacement) and ideally yaw (for direction).
    # Bridge sends Y:0; Spin (mode 5) has near-zero translational VEL → path is a dot.
    # Circle (mode 1) has non-zero VEL → path should show a line (straight if Y=0).
    dist_vals = [parse_telemetry(ln).get("DIST") for ln in telemetry if parse_telemetry(ln)]
    vel_vals = [parse_telemetry(ln).get("VEL") for ln in telemetry if parse_telemetry(ln)]
    yaw_vals = [parse_telemetry(ln).get("Y") for ln in telemetry if parse_telemetry(ln)]
    if dist_vals:
        print("\nDIST range: {:.4f} .. {:.4f} m".format(min(dist_vals), max(dist_vals)))
    if vel_vals:
        print("VEL range: {:.4f} .. {:.4f} m/s".format(min(vel_vals), max(vel_vals)))
    if yaw_vals:
        print("Y (yaw) range: {:.2f} .. {:.2f} deg".format(min(yaw_vals), max(yaw_vals)))
    print("\nPath plot: needs VEL (and Y for curves). Spin has ~0 VEL → dot; Circle has VEL → line.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
