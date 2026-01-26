package config

import (
	"os"

	"gopkg.in/yaml.v3"
)

type Config struct {
	RateHz         float64      `yaml:"rate_hz"`
	DurationS      float64      `yaml:"duration_s"`
	Units          string       `yaml:"units"`
	Seed           int64        `yaml:"seed"`
	Motion         MotionConfig `yaml:"motion"`
	GyroNoiseStd   float64      `yaml:"gyro_noise_std"`
	AccelNoiseStd  float64      `yaml:"accel_noise_std"`
	GyroBias       [3]float64   `yaml:"gyro_bias"`
	GyroDriftStd   float64      `yaml:"gyro_bias_drift_std"`
	VibrationBurst BurstConfig  `yaml:"vibration_burst"`
	UDP            UDPConfig    `yaml:"udp"`
}

type MotionConfig struct {
	Type         string          `yaml:"type"`
	AmplitudeDeg float64         `yaml:"amplitude_deg"`
	FreqHz       float64         `yaml:"freq_hz"`
	DurationS    float64         `yaml:"duration_s"`
	Impulse      ImpulseConfig   `yaml:"impulse"`
	Scripted     []SegmentConfig `yaml:"scripted"`
}

type ImpulseConfig struct {
	Axis      string  `yaml:"axis"`
	RateDegS  float64 `yaml:"rate_deg_s"`
	DurationS float64 `yaml:"duration_s"`
}

type SegmentConfig struct {
	Type         string        `yaml:"type"`
	DurationS    float64       `yaml:"duration_s"`
	AmplitudeDeg float64       `yaml:"amplitude_deg"`
	FreqHz       float64       `yaml:"freq_hz"`
	Impulse      ImpulseConfig `yaml:"impulse"`
}

type BurstConfig struct {
	Enabled   bool    `yaml:"enabled"`
	Amplitude float64 `yaml:"amplitude"`
	FreqHz    float64 `yaml:"freq_hz"`
	DutyCycle float64 `yaml:"duty_cycle"`
}

type UDPConfig struct {
	Enabled bool   `yaml:"enabled"`
	Addr    string `yaml:"addr"`
	Format  string `yaml:"format"`
}

func Load(path string) (Config, error) {
	var cfg Config
	b, err := os.ReadFile(path)
	if err != nil {
		return cfg, err
	}
	if err := yaml.Unmarshal(b, &cfg); err != nil {
		return cfg, err
	}
	return cfg, nil
}
