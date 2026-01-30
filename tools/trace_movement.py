#!/usr/bin/env python3
"""Manually trigger a movement and trace the results.

Usage:
  python3 tools/trace_movement.py [mode] [duration_s]

  mode: 0=manual, 1=circle, 2-4=figure8, 5=spin, 6=stop-go, 7=square, 8=slalom, 9-11=balance
  duration_s: how long to collect telemetry (default 5)

Example:
  python3 tools/trace_movement.py 1 6    # Circle for 6 seconds, trace R/P/Y

Requires e2e-bridge running: make e2e-bridge (in another terminal)
"""
import socket
import sys
import time

HOST = "127.0.0.1"
PORT = 9001


def main():
    mode = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    duration_s = float(sys.argv[2]) if len(sys.argv) > 2 else 5.0

    print("Connecting to", HOST, ":", PORT)
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(1.0)
    try:
        s.connect((HOST, PORT))
    except OSError as e:
        print("ERROR: Could not connect. Is e2e-bridge running? (make e2e-bridge)")
        return 1

    print("Sending START, ARM, MODE:%d" % mode)
    for cmd in [b"START\n", b"ARM\n", ("MODE:%d\n" % mode).encode()]:
        s.sendall(cmd)
        time.sleep(0.1)

    print("Tracing telemetry for %.1f seconds (R P Y)...\n" % duration_s)
    start = time.time()
    count = 0
    while time.time() - start < duration_s:
        try:
            data = s.recv(4096)
            if not data:
                break
            for line in data.decode("utf-8", errors="ignore").splitlines():
                if line.startswith("R:"):
                    count += 1
                    print("[%6.2fs] %s" % (time.time() - start, line))
        except socket.timeout:
            continue

    print("\n--- Sending MODE:0 (manual), STOP ---")
    s.sendall(b"MODE:0\n")
    time.sleep(0.1)
    s.sendall(b"STOP\n")
    s.close()

    print("Trace complete. %d telemetry lines received." % count)
    return 0


if __name__ == "__main__":
    exit(main())
