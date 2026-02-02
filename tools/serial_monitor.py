#!/usr/bin/env python3
"""
Open the robot's serial port at 115200 and print received lines.
Use this to run Step 1 (Serial / UART sanity check) without Xcode.

  python3 tools/serial_monitor.py              # list ports and prompt
  python3 tools/serial_monitor.py /dev/cu.usbmodem*  # use first matching port

Robot UART is SERCOM0 (PA04 TX, PA05 RX). You need one of:
  - Curiosity Nano's EDBG virtual serial (if it bridges that UART to USB)
  - USB-serial adapter: connect adapter RX to robot TX (PA04), GND to GND
"""
import sys
import glob
import argparse

try:
    import serial
    import serial.tools.list_ports
except ImportError:
    print("pyserial is required: pip install pyserial")
    sys.exit(1)

BAUD = 115200


def list_ports():
    ports = list(serial.tools.list_ports.comports())
    if not ports:
        print("No serial ports found. Plug in the Curiosity Nano or a USB-serial adapter.")
        return []
    print("Available ports:")
    for i, p in enumerate(ports):
        print(f"  {i}: {p.device}  {p.description or ''}")
    return [p.device for p in ports]


def main():
    ap = argparse.ArgumentParser(description="Monitor robot UART at 115200")
    ap.add_argument("port", nargs="?", help="Port (e.g. /dev/cu.usbmodem*)")
    ap.add_argument("-l", "--list", action="store_true", help="List ports and exit")
    args = ap.parse_args()

    if args.list:
        list_ports()
        return

    port = args.port
    if not port:
        devices = list_ports()
        if not devices:
            sys.exit(1)
        # Prefer Microchip/Curiosity-like names on macOS
        for d in devices:
            if "usbmodem" in d or "usbserial" in d or "SLAB" in d or "Microchip" in d:
                port = d
                break
        if not port:
            port = devices[0]
        print(f"Using: {port}")
    else:
        # Allow glob for convenience (e.g. /dev/cu.usbmodem*)
        if "*" in port:
            matches = glob.glob(port)
            if not matches:
                print(f"No port matching {port}")
                sys.exit(1)
            port = sorted(matches)[0]
            print(f"Using: {port}")

    try:
        ser = serial.Serial(port, BAUD, timeout=0.1)
    except serial.SerialException as e:
        print(f"Could not open {port}: {e}")
        sys.exit(1)

    print(f"Connected at {BAUD} baud. Reset the robot to see boot messages. Ctrl+C to quit.\n")
    try:
        buf = b""
        while True:
            chunk = ser.read(256)
            if chunk:
                buf += chunk
                while b"\n" in buf:
                    line, _, buf = buf.partition(b"\n")
                    line = line.replace(b"\r", b"").strip()
                    if line:
                        try:
                            print(line.decode("utf-8", errors="replace"))
                        except Exception:
                            print(line)
            else:
                pass  # timeout: allow Ctrl+C
    except KeyboardInterrupt:
        pass
    except (serial.SerialException, OSError) as e:
        print(f"\nDevice disconnected or unavailable: {e}", file=sys.stderr)
    finally:
        try:
            ser.close()
        except Exception:
            pass
    print("\nClosed.")


if __name__ == "__main__":
    main()
