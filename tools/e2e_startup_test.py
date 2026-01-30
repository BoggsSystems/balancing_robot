#!/usr/bin/env python3
import socket
import time

HOST = "127.0.0.1"
PORT = 9001

def main():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(2.0)
    s.connect((HOST, PORT))

    # Start streaming, arm, then disarm.
    sequence = [
        b"START\n",
        b"ARM\n",
        b"MODE:9\n",  # balance hold +5°
        b"DISARM\n",
        b"STOP\n",
    ]
    for cmd in sequence:
        s.sendall(cmd)
        time.sleep(0.2)

    # Collect a short sample
    lines = []
    start = time.time()
    while time.time() - start < 1.0:
        try:
            data = s.recv(4096)
            if not data:
                break
            lines.extend(data.decode("utf-8", errors="ignore").splitlines())
        except socket.timeout:
            break

    s.close()

    telemetry = [ln for ln in lines if ln.startswith("R:")]
    print("telemetry_lines:", len(telemetry))
    for ln in telemetry[:5]:
        print(ln)
    if telemetry:
        print("...")
        for ln in telemetry[-5:]:
            print(ln)

if __name__ == "__main__":
    main()
