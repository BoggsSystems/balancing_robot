package tests

import (
	"math"
	"testing"

	"balancing_robot/internal/config"
	"balancing_robot/internal/motion"
)

func TestSinePitchBounds(t *testing.T) {
	cfg := config.MotionConfig{Type: "sine", AmplitudeDeg: 5, FreqHz: 1}
	m, err := motion.New(cfg)
	if err != nil {
		t.Fatalf("motion: %v", err)
	}
	amp := 5 * math.Pi / 180
	for _, tt := range []float64{0, 0.25, 0.5, 0.75, 1.0} {
		state := m.StateAt(tt)
		if math.Abs(state.Orientation.Pitch) > amp+1e-6 {
			t.Fatalf("pitch out of bounds: %.6f", state.Orientation.Pitch)
		}
	}
}

func TestSlowTiltBounds(t *testing.T) {
	cfg := config.MotionConfig{Type: "slow_tilt", AmplitudeDeg: 10, DurationS: 4}
	m, err := motion.New(cfg)
	if err != nil {
		t.Fatalf("motion: %v", err)
	}
	amp := 10 * math.Pi / 180
	for _, tt := range []float64{0, 1, 2, 3, 4} {
		state := m.StateAt(tt)
		if math.Abs(state.Orientation.Pitch) > amp+1e-6 {
			t.Fatalf("pitch out of bounds: %.6f", state.Orientation.Pitch)
		}
	}
}

func TestImpulseAngle(t *testing.T) {
	cfg := config.MotionConfig{
		Type: "impulse_push",
		Impulse: config.ImpulseConfig{
			Axis:      "pitch",
			RateDegS:  90,
			DurationS: 0.1,
		},
	}
	m, err := motion.New(cfg)
	if err != nil {
		t.Fatalf("motion: %v", err)
	}
	state := m.StateAt(0.2)
	want := 90 * math.Pi / 180 * 0.1
	if math.Abs(state.Orientation.Pitch-want) > 1e-6 {
		t.Fatalf("expected pitch %.6f got %.6f", want, state.Orientation.Pitch)
	}
}
