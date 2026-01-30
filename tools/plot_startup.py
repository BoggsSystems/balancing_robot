#!/usr/bin/env python3
import csv
import sys

try:
    import matplotlib.pyplot as plt
except ImportError:
    print("matplotlib is required: pip install matplotlib")
    sys.exit(1)


def main():
    if len(sys.argv) != 2:
        print("usage: plot_startup.py <csv_path>")
        sys.exit(1)
    path = sys.argv[1]

    t = []
    pitch = []
    target = []
    mode = []

    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if "target_pitch_deg" not in row:
                print("missing target_pitch_deg; run sim with --trace")
                return
            t.append(float(row["t"]))
            pitch.append(float(row["pitch"]))
            target.append(float(row["target_pitch_deg"]))
            mode.append(int(float(row["mode"])))

    fig, ax = plt.subplots(figsize=(10, 4))
    ax.plot(t, pitch, label="pitch (deg)")
    ax.plot(t, target, label="target_pitch (deg)")
    ax.set_xlabel("t (s)")
    ax.set_ylabel("deg")
    ax.set_title("Startup / Stand-up Ramp")
    ax.legend()
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    main()
