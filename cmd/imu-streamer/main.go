package main

import (
	"flag"
	"fmt"
	"log"
	"math/rand"
	"os"
	"strings"

	"balancing_robot/internal/config"
	"balancing_robot/internal/imu"
	"balancing_robot/internal/motion"
	"balancing_robot/internal/runtime"
	"balancing_robot/internal/stream"
)

func main() {
	cfgPath := flag.String("config", "configs/default.yaml", "path to YAML config")
	rateHz := flag.Float64("rate_hz", 0, "sample rate in Hz (overrides config)")
	durationS := flag.Float64("duration_s", 0, "duration in seconds (overrides config)")
	seed := flag.Int64("seed", 0, "random seed (overrides config)")
	udpEnabled := flag.Bool("udp", false, "enable UDP output (overrides config)")
	udpAddr := flag.String("udp_addr", "", "udp host:port (overrides config)")
	units := flag.String("units", "", "units: si or deg (overrides config)")
	flag.Parse()

	cfg, err := config.Load(*cfgPath)
	if err != nil {
		log.Fatalf("load config: %v", err)
	}
	if *rateHz > 0 {
		cfg.RateHz = *rateHz
	}
	if *durationS > 0 {
		cfg.DurationS = *durationS
	}
	if *seed != 0 {
		cfg.Seed = *seed
	}
	if *udpEnabled {
		cfg.UDP.Enabled = true
	}
	if *udpAddr != "" {
		cfg.UDP.Addr = *udpAddr
	}
	if *units != "" {
		cfg.Units = strings.ToLower(*units)
	}
	if cfg.RateHz <= 0 {
		cfg.RateHz = 500
	}
	if cfg.Units == "" {
		cfg.Units = "si"
	}

	model, err := motion.New(cfg.Motion)
	if err != nil {
		log.Fatalf("motion model: %v", err)
	}
	rng := rand.New(rand.NewSource(cfg.Seed))
	source := imu.NewEmulator(cfg, model, rng)
	streamer, err := stream.New(cfg)
	if err != nil {
		log.Fatalf("stream: %v", err)
	}
	defer func() {
		_ = streamer.Close()
	}()

	if err := streamer.WriteHeader(); err != nil {
		log.Fatalf("write header: %v", err)
	}

	runner := runtime.Runner{RateHz: cfg.RateHz, IMU: source}
	stats, err := runner.Run(cfg.DurationS, streamer)
	if err != nil {
		log.Fatalf("run: %v", err)
	}
	fmt.Fprintf(os.Stderr, "dt stats: mean=%.6f s std=%.6f s min=%.6f s max=%.6f s n=%d\n",
		stats.Mean, stats.StdDev(), stats.Min, stats.Max, stats.Count)
}
