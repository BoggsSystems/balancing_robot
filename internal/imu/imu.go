package imu

import (
	"math"
	"math/rand"

	"balancing_robot/internal/config"
	"balancing_robot/internal/model"
	"balancing_robot/internal/motion"
)

type Sample struct {
	T     float64
	Gyro  [3]float64
	Accel [3]float64
}

type IMU interface {
	NextSample() Sample
}

type Emulator struct {
	model motion.Model
	cfg   config.Config
	rng   *rand.Rand

	timeS   float64
	lastDT  float64
	drift   [3]float64
	vibPhase float64
}

func NewEmulator(cfg config.Config, model motion.Model, rng *rand.Rand) *Emulator {
	return &Emulator{
		cfg:   cfg,
		model: model,
		rng:   rng,
	}
}

// SetDelta sets the elapsed time between samples (seconds).
func (e *Emulator) SetDelta(dt float64) {
	if dt > 0 {
		e.lastDT = dt
	}
}

func (e *Emulator) NextSample() Sample {
	dt := e.lastDT
	if dt <= 0 {
		dt = 1 / e.cfg.RateHz
	}
	e.timeS += dt
	state := e.model.StateAt(e.timeS)

	gyro := state.AngVelBody
	for i := 0; i < 3; i++ {
		gyro[i] += e.cfg.GyroBias[i]
	}
	gyro = e.applyGyroDrift(gyro, dt)
	gyro = e.applyNoise(gyro, e.cfg.GyroNoiseStd)

	accel := e.gravityBody(state.Orientation)
	accel = e.applyVibration(accel, dt)
	accel = e.applyNoise(accel, e.cfg.AccelNoiseStd)

	if e.cfg.Units == "deg" {
		for i := 0; i < 3; i++ {
			gyro[i] = gyro[i] * 180 / math.Pi
		}
	}

	return Sample{
		T:     e.timeS,
		Gyro:  gyro,
		Accel: accel,
	}
}

func (e *Emulator) gravityBody(o model.Orientation) [3]float64 {
	worldG := [3]float64{0, 0, -model.Gravity}
	bodyG := model.RotateWorldToBody(o.Roll, o.Pitch, o.Yaw, worldG)
	return [3]float64{-bodyG[0], -bodyG[1], -bodyG[2]}
}

func (e *Emulator) applyNoise(v [3]float64, std float64) [3]float64 {
	if std == 0 {
		return v
	}
	for i := 0; i < 3; i++ {
		v[i] += e.rng.NormFloat64() * std
	}
	return v
}

func (e *Emulator) applyGyroDrift(v [3]float64, dt float64) [3]float64 {
	if e.cfg.GyroDriftStd == 0 || dt <= 0 {
		return v
	}
	sigma := e.cfg.GyroDriftStd * math.Sqrt(dt)
	for i := 0; i < 3; i++ {
		e.drift[i] += e.rng.NormFloat64() * sigma
		v[i] += e.drift[i]
	}
	return v
}

func (e *Emulator) applyVibration(v [3]float64, dt float64) [3]float64 {
	if !e.cfg.VibrationBurst.Enabled {
		return v
	}
	if e.cfg.VibrationBurst.FreqHz <= 0 {
		return v
	}
	e.vibPhase += 2 * math.Pi * e.cfg.VibrationBurst.FreqHz * dt
	duty := e.cfg.VibrationBurst.DutyCycle
	if duty <= 0 || duty > 1 {
		duty = 0.1
	}
	if math.Mod(e.vibPhase/(2*math.Pi), 1.0) <= duty {
		v[2] += e.cfg.VibrationBurst.Amplitude * math.Sin(e.vibPhase)
	}
	return v
}
