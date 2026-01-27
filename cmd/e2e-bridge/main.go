package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"math"
	"net"
	"os"
	"os/exec"
	"os/signal"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
)

func main() {
	config := flag.String("config", "configs/default.yaml", "path to imu-streamer YAML config")
	port := flag.Int("port", 9001, "TCP port for iOS E2E clients")
	durationS := flag.String("duration_s", "0", "duration in seconds for imu-streamer (0 = run until Ctrl+C)")
	telemetryHz := flag.Float64("telemetry-hz", 20, "max rate (Hz) to send R: P: Y: to clients")
	armRestPitch := flag.Float64("arm-rest-pitch", -25, "pitch (deg) for R: P: Y: when disarmed (resting on arm)")
	motion := flag.String("motion", "", "motion type for imu-streamer (e.g. static for balancing-at-0); overrides config")
	imuStreamer := flag.String("imu-streamer", "./bin/imu-streamer", "path to imu-streamer binary")
	sim := flag.String("sim", "./firmware/tools/sim", "path to firmware sim binary")
	flag.Parse()

	// Build imu-streamer args
	imuArgs := []string{"--config", *config, "--duration_s", *durationS}
	if *motion != "" {
		imuArgs = append(imuArgs, "--motion", *motion)
	}

	// Start imu-streamer
	cmdImu := exec.Command(*imuStreamer, imuArgs...)
	cmdImu.Stderr = os.Stderr
	imuOut, err := cmdImu.StdoutPipe()
	if err != nil {
		log.Fatalf("imu-streamer stdout pipe: %v", err)
	}
	if err := cmdImu.Start(); err != nil {
		log.Fatalf("imu-streamer start: %v", err)
	}
	defer func() {
		_ = cmdImu.Process.Kill()
		_ = cmdImu.Wait()
	}()

	// Start sim: stdin is a pipe so we can merge IMU lines with live RC from the app
	pipeReader, pipeWriter := io.Pipe()
	cmdSim := exec.Command(*sim)
	cmdSim.Stdin = pipeReader
	cmdSim.Stderr = os.Stderr
	simOut, err := cmdSim.StdoutPipe()
	if err != nil {
		log.Fatalf("sim stdout pipe: %v", err)
	}
	if err := cmdSim.Start(); err != nil {
		log.Fatalf("sim start: %v", err)
	}
	defer func() {
		_ = pipeWriter.Close()
		_ = cmdSim.Process.Kill()
		_ = cmdSim.Wait()
	}()

	// Pending RC: app sends M:throttle,turn; we inject "RC,throttle,turn,1" before the next IMU line
	var pendingRCMu sync.Mutex
	var pendingRCLine string

	// Merge goroutine: read imu-streamer, inject any pending RC before each IMU line, write to sim stdin
	go func() {
		sc := bufio.NewScanner(imuOut)
		for sc.Scan() {
			line := sc.Text()
			pendingRCMu.Lock()
			pl := pendingRCLine
			pendingRCLine = ""
			pendingRCMu.Unlock()
			if pl != "" {
				if _, err := pipeWriter.Write([]byte(pl)); err != nil {
					return
				}
			}
			if _, err := pipeWriter.Write([]byte(line + "\n")); err != nil {
				return
			}
		}
		_ = pipeWriter.Close()
		if err := sc.Err(); err != nil {
			log.Printf("imu-streamer read: %v", err)
		}
	}()

	// Shared latest telemetry (radians from sim; we convert when sending)
	var mu sync.Mutex
	latestRoll := 0.0
	latestPitch := 0.0
	hasTelemetry := false

	// Sim reader: parse "t,roll,pitch,balance,left,right", skip header, convert later when sending
	go func() {
		sc := bufio.NewScanner(simOut)
		for sc.Scan() {
			line := sc.Text()
			if line == "" {
				continue
			}
			// Parse "t,roll,pitch,balance,left,right" (header "t,roll,pitch,..." fails to parse)
			parts := strings.Split(line, ",")
			if len(parts) != 6 {
				continue
			}
			_, err1 := strconv.ParseFloat(parts[0], 64)
			roll, err2 := strconv.ParseFloat(parts[1], 64)
			pitch, err3 := strconv.ParseFloat(parts[2], 64)
			if err1 != nil || err2 != nil || err3 != nil {
				continue
			}
			mu.Lock()
			latestRoll = roll
			latestPitch = pitch
			hasTelemetry = true
			mu.Unlock()
		}
		if err := sc.Err(); err != nil {
			log.Printf("sim stdout read: %v", err)
		}
	}()

	// TCP listener
	listener, err := net.Listen("tcp", fmt.Sprintf(":%d", *port))
	if err != nil {
		log.Fatalf("listen :%d: %v", *port, err)
	}
	defer listener.Close()
	log.Printf("E2E bridge listening on :%d (telemetry %.0f Hz); imu-streamer | sim running", *port, *telemetryHz)

	// connState: per-connection; streaming gates whether we send R: P: Y: (START/STOP)
	// disarmed: when true, send fixed R:0 P:armRestPitch Y:0 (resting on arm) instead of sim
	type connState struct {
		mu        sync.Mutex
		streaming bool
		disarmed  bool
	}

	// Accept loop
	go func() {
		for {
			conn, err := listener.Accept()
			if err != nil {
				return
			}
			log.Printf("E2E client connected: %s (streaming=off until START)", conn.RemoteAddr())
			state := &connState{streaming: false}

			// Send loop: at telemetry_hz, send latest R: P: Y: only when state.streaming
			// When disarmed, send fixed R:0 P:armRestPitch Y:0 (resting on arm)
			interval := time.Duration(float64(time.Second) / *telemetryHz)
			ticker := time.NewTicker(interval)
			go func(c net.Conn, st *connState) {
				defer ticker.Stop()
				defer c.Close()
				for range ticker.C {
					st.mu.Lock()
					on := st.streaming
					dis := st.disarmed
					st.mu.Unlock()
					if !on {
						continue
					}
					var msg string
					if dis {
						msg = fmt.Sprintf("R:0 P:%.2f Y:0\n", *armRestPitch)
					} else {
						mu.Lock()
						r, p := latestRoll, latestPitch
						ok := hasTelemetry
						mu.Unlock()
						if !ok {
							continue
						}
						rollDeg := r * 180 / math.Pi
						pitchDeg := p * 180 / math.Pi
						msg = fmt.Sprintf("R:%.2f P:%.2f Y:0\n", rollDeg, pitchDeg)
					}
					if _, err := c.Write([]byte(msg)); err != nil {
						break
					}
				}
			}(conn, state)

			// Read loop: START/STOP gate streaming; DISARM sets disarmed (cleared on START); M: and LED as before
			go func(c net.Conn, st *connState) {
				sc := bufio.NewScanner(c)
				for sc.Scan() {
					line := strings.TrimSpace(sc.Text())
					if line == "" {
						continue
					}
					switch line {
					case "START":
						st.mu.Lock()
						st.streaming = true
						st.disarmed = false
						st.mu.Unlock()
					case "STOP":
						st.mu.Lock()
						st.streaming = false
						st.mu.Unlock()
					case "DISARM":
						st.mu.Lock()
						st.disarmed = true
						st.mu.Unlock()
					default:
						if strings.HasPrefix(line, "M:") {
							parts := strings.SplitN(strings.TrimPrefix(line, "M:"), ",", 2)
							if len(parts) == 2 {
								if throttle, e1 := strconv.ParseFloat(strings.TrimSpace(parts[0]), 64); e1 == nil {
									if turn, e2 := strconv.ParseFloat(strings.TrimSpace(parts[1]), 64); e2 == nil {
										pendingRCMu.Lock()
										pendingRCLine = fmt.Sprintf("RC,%g,%g,1\n", throttle, turn)
										pendingRCMu.Unlock()
									}
								}
							}
						}
					}
					log.Printf("E2E command from app: %q", line)
				}
			}(conn, state)
		}
	}()

	// Wait for SIGINT or for sim to exit (imu-streamer exits -> sim EOF)
	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
	<-sig
	log.Printf("E2E bridge shutting down")
}
