#!/usr/bin/env python3
import csv
import sys

try:
    import matplotlib.pyplot as plt
except ImportError:
    print("matplotlib is required: pip install matplotlib")
    sys.exit(1)


def read_csv(path):
    t, gx, gy, gz, ax, ay, az = [], [], [], [], [], [], []
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            t.append(float(row["t"]))
            gx.append(float(row["gx"]))
            gy.append(float(row["gy"]))
            gz.append(float(row["gz"]))
            ax.append(float(row["ax"]))
            ay.append(float(row["ay"]))
            az.append(float(row["az"]))
    return t, gx, gy, gz, ax, ay, az


def main():
    if len(sys.argv) != 2:
        print("usage: plot_csv.py <csv_path>")
        sys.exit(1)
    t, gx, gy, gz, ax, ay, az = read_csv(sys.argv[1])

    fig, (a1, a2) = plt.subplots(2, 1, sharex=True)
    a1.plot(t, gx, label="gx")
    a1.plot(t, gy, label="gy")
    a1.plot(t, gz, label="gz")
    a1.set_ylabel("gyro")
    a1.legend()

    a2.plot(t, ax, label="ax")
    a2.plot(t, ay, label="ay")
    a2.plot(t, az, label="az")
    a2.set_ylabel("accel")
    a2.set_xlabel("t (s)")
    a2.legend()

    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    main()
