package tests

import (
	"testing"
	"time"

	"balancing_robot/internal/imu"
	"balancing_robot/internal/runtime"
)

type dummyIMU struct{}

func (d dummyIMU) NextSample() imu.Sample { return imu.Sample{} }

type countWriter struct {
	count int
}

func (c *countWriter) WriteSample(sample imu.Sample) error {
	c.count++
	return nil
}

func TestSampleRateAccuracy(t *testing.T) {
	rate := 200.0
	duration := 5.0
	writer := &countWriter{}
	runner := runtime.Runner{RateHz: rate, IMU: dummyIMU{}}

	start := time.Now()
	stats, err := runner.Run(duration, writer)
	if err != nil {
		t.Fatalf("run: %v", err)
	}
	elapsed := time.Since(start).Seconds()
	expected := int(rate * duration)
	if writer.count == 0 {
		t.Fatalf("no samples")
	}
	errPct := mathAbs(float64(writer.count-expected)) / float64(expected) * 100
	if errPct > 2.0 {
		t.Fatalf("rate error %.2f%% (expected %d got %d)", errPct, expected, writer.count)
	}
	if mathAbs(stats.Mean-(1/rate)) > 0.01 {
		t.Fatalf("mean dt out of range: %.6f", stats.Mean)
	}
	if mathAbs(elapsed-duration) > 0.2 {
		t.Fatalf("elapsed out of range: %.3f", elapsed)
	}
}

func mathAbs(v float64) float64 {
	if v < 0 {
		return -v
	}
	return v
}
