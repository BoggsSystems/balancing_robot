package runtime

import (
	"math"
	"time"

	"balancing_robot/internal/imu"
)

type Stats struct {
	Count int
	Mean  float64
	M2    float64
	Min   float64
	Max   float64
}

func (s *Stats) Add(x float64) {
	s.Count++
	if s.Count == 1 {
		s.Min = x
		s.Max = x
		s.Mean = x
		return
	}
	if x < s.Min {
		s.Min = x
	}
	if x > s.Max {
		s.Max = x
	}
	delta := x - s.Mean
	s.Mean += delta / float64(s.Count)
	s.M2 += delta * (x - s.Mean)
}

func (s Stats) StdDev() float64 {
	if s.Count < 2 {
		return 0
	}
	return math.Sqrt(s.M2 / float64(s.Count-1))
}

type Runner struct {
	RateHz float64
	IMU    imu.IMU
}

type DeltaSetter interface {
	SetDelta(dt float64)
}

type SampleWriter interface {
	WriteSample(sample imu.Sample) error
}

func (r Runner) Run(durationS float64, writer SampleWriter) (Stats, error) {
	var stats Stats
	if r.RateHz <= 0 {
		r.RateHz = 500
	}
	period := time.Duration(float64(time.Second) / r.RateHz)
	ticker := time.NewTicker(period)
	defer ticker.Stop()

	start := time.Now()
	prev := start

	for {
		<-ticker.C
		now := time.Now()
		dt := now.Sub(prev).Seconds()
		prev = now
		stats.Add(dt)

		if ds, ok := r.IMU.(DeltaSetter); ok {
			ds.SetDelta(dt)
		}
		if err := writer.WriteSample(r.IMU.NextSample()); err != nil {
			return stats, err
		}

		if durationS > 0 && now.Sub(start).Seconds() >= durationS {
			break
		}
	}
	return stats, nil
}
