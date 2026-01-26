package motion

import (
	"errors"
	"math"

	"balancing_robot/internal/config"
	"balancing_robot/internal/model"
)

type State struct {
	Orientation model.Orientation
	AngVelBody  [3]float64
}

type Model interface {
	StateAt(t float64) State
}

func New(cfg config.MotionConfig) (Model, error) {
	switch cfg.Type {
	case "", "static":
		return Static{}, nil
	case "slow_tilt":
		amp := degToRad(defaultIfZero(cfg.AmplitudeDeg, 10))
		dur := defaultIfZero(cfg.DurationS, 5)
		return SlowTilt{AmplitudeRad: amp, DurationS: dur}, nil
	case "sine":
		amp := degToRad(defaultIfZero(cfg.AmplitudeDeg, 5))
		freq := defaultIfZero(cfg.FreqHz, 1)
		return SinePitch{AmplitudeRad: amp, FreqHz: freq}, nil
	case "impulse_push":
		imp := cfg.Impulse
		rate := degToRad(defaultIfZero(imp.RateDegS, 90))
		dur := defaultIfZero(imp.DurationS, 0.05)
		axis := defaultIfEmpty(imp.Axis, "pitch")
		return Impulse{Axis: axis, RateRadS: rate, DurationS: dur}, nil
	case "scripted":
		if len(cfg.Scripted) == 0 {
			return nil, errors.New("scripted motion requires segments")
		}
		var segs []Segment
		var t0 float64
		for _, s := range cfg.Scripted {
			m, err := New(config.MotionConfig{
				Type:         s.Type,
				AmplitudeDeg: s.AmplitudeDeg,
				FreqHz:       s.FreqHz,
				DurationS:    s.DurationS,
				Impulse:      s.Impulse,
			})
			if err != nil {
				return nil, err
			}
			dur := defaultIfZero(s.DurationS, 1)
			segs = append(segs, Segment{
				StartS: t0,
				EndS:   t0 + dur,
				Model:  m,
			})
			t0 += dur
		}
		return Scripted{Segments: segs}, nil
	default:
		return nil, errors.New("unknown motion type: " + cfg.Type)
	}
}

type Static struct{}

func (Static) StateAt(t float64) State {
	return State{}
}

type SlowTilt struct {
	AmplitudeRad float64
	DurationS    float64
}

func (m SlowTilt) StateAt(t float64) State {
	if m.DurationS <= 0 {
		return State{}
	}
	half := m.DurationS / 2
	var pitch float64
	var pitchRate float64
	if t <= half {
		pitch = m.AmplitudeRad * (t / half)
		pitchRate = m.AmplitudeRad / half
	} else if t <= m.DurationS {
		pitch = m.AmplitudeRad * (1 - (t-half)/half)
		pitchRate = -m.AmplitudeRad / half
	} else {
		pitch = 0
		pitchRate = 0
	}
	return State{
		Orientation: model.Orientation{Pitch: pitch},
		AngVelBody:  [3]float64{0, pitchRate, 0},
	}
}

type SinePitch struct {
	AmplitudeRad float64
	FreqHz       float64
}

func (m SinePitch) StateAt(t float64) State {
	w := 2 * math.Pi * m.FreqHz
	pitch := m.AmplitudeRad * math.Sin(w*t)
	pitchRate := m.AmplitudeRad * w * math.Cos(w*t)
	return State{
		Orientation: model.Orientation{Pitch: pitch},
		AngVelBody:  [3]float64{0, pitchRate, 0},
	}
}

type Impulse struct {
	Axis      string
	RateRadS  float64
	DurationS float64
}

func (m Impulse) StateAt(t float64) State {
	if t < 0 {
		return State{}
	}
	var angVel [3]float64
	var orient model.Orientation
	if t <= m.DurationS {
		angVel = axisRate(m.Axis, m.RateRadS)
		orient = axisAngle(m.Axis, m.RateRadS*t)
	} else {
		angVel = [3]float64{}
		orient = axisAngle(m.Axis, m.RateRadS*m.DurationS)
	}
	return State{Orientation: orient, AngVelBody: angVel}
}

type Segment struct {
	StartS float64
	EndS   float64
	Model  Model
}

type Scripted struct {
	Segments []Segment
}

func (s Scripted) StateAt(t float64) State {
	if len(s.Segments) == 0 {
		return State{}
	}
	for _, seg := range s.Segments {
		if t >= seg.StartS && t < seg.EndS {
			return seg.Model.StateAt(t - seg.StartS)
		}
	}
	last := s.Segments[len(s.Segments)-1]
	if t >= last.EndS {
		return last.Model.StateAt(last.EndS - last.StartS)
	}
	return State{}
}

func defaultIfZero(v float64, def float64) float64 {
	if v == 0 {
		return def
	}
	return v
}

func defaultIfEmpty(v string, def string) string {
	if v == "" {
		return def
	}
	return v
}

func degToRad(deg float64) float64 {
	return deg * math.Pi / 180
}

func axisRate(axis string, rate float64) [3]float64 {
	switch axis {
	case "roll":
		return [3]float64{rate, 0, 0}
	case "yaw":
		return [3]float64{0, 0, rate}
	default:
		return [3]float64{0, rate, 0}
	}
}

func axisAngle(axis string, ang float64) model.Orientation {
	switch axis {
	case "roll":
		return model.Orientation{Roll: ang}
	case "yaw":
		return model.Orientation{Yaw: ang}
	default:
		return model.Orientation{Pitch: ang}
	}
}
