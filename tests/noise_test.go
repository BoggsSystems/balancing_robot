package tests

import (
	"testing"

	"math/rand"

	"balancing_robot/internal/config"
	"balancing_robot/internal/imu"
	"balancing_robot/internal/motion"
)

func TestDeterministicSeed(t *testing.T) {
	cfg := config.Config{
		RateHz:        500,
		DurationS:     1,
		Units:         "si",
		Seed:          42,
		GyroNoiseStd:  0.01,
		AccelNoiseStd: 0.05,
		GyroBias:      [3]float64{0.02, -0.01, 0.005},
		GyroDriftStd:  0.0001,
	}
	m, err := motion.New(config.MotionConfig{Type: "static"})
	if err != nil {
		t.Fatalf("motion: %v", err)
	}
	rng1 := rand.New(rand.NewSource(cfg.Seed))
	rng2 := rand.New(rand.NewSource(cfg.Seed))
	imu1 := imu.NewEmulator(cfg, m, rng1)
	imu2 := imu.NewEmulator(cfg, m, rng2)
	imu1.SetDelta(1.0 / cfg.RateHz)
	imu2.SetDelta(1.0 / cfg.RateHz)

	for i := 0; i < 10; i++ {
		s1 := imu1.NextSample()
		s2 := imu2.NextSample()
		if s1.Gyro != s2.Gyro || s1.Accel != s2.Accel {
			t.Fatalf("samples differ at %d", i)
		}
	}
}
