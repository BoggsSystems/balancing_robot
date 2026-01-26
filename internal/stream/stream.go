package stream

import (
	"encoding/binary"
	"fmt"
	"math"
	"net"
	"os"

	"balancing_robot/internal/config"
	"balancing_robot/internal/imu"
)

type Streamer struct {
	stdout *os.File
	udp    *net.UDPConn
	format string
}

func New(cfg config.Config) (*Streamer, error) {
	s := &Streamer{stdout: os.Stdout, format: cfg.UDP.Format}
	if cfg.UDP.Enabled {
		addr, err := net.ResolveUDPAddr("udp", cfg.UDP.Addr)
		if err != nil {
			return nil, err
		}
		conn, err := net.DialUDP("udp", nil, addr)
		if err != nil {
			return nil, err
		}
		s.udp = conn
	}
	if s.format == "" {
		s.format = "csv"
	}
	return s, nil
}

func (s *Streamer) Close() error {
	if s.udp != nil {
		return s.udp.Close()
	}
	return nil
}

func (s *Streamer) WriteHeader() error {
	_, err := fmt.Fprintln(s.stdout, "t,gx,gy,gz,ax,ay,az")
	return err
}

func (s *Streamer) WriteSample(sample imu.Sample) error {
	line := fmt.Sprintf("%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f",
		sample.T,
		sample.Gyro[0], sample.Gyro[1], sample.Gyro[2],
		sample.Accel[0], sample.Accel[1], sample.Accel[2],
	)
	if _, err := fmt.Fprintln(s.stdout, line); err != nil {
		return err
	}
	if s.udp != nil {
		if s.format == "binary" {
			buf := make([]byte, 7*8)
			vals := []float64{
				sample.T,
				sample.Gyro[0], sample.Gyro[1], sample.Gyro[2],
				sample.Accel[0], sample.Accel[1], sample.Accel[2],
			}
			for i, v := range vals {
				binary.LittleEndian.PutUint64(buf[i*8:(i+1)*8], math.Float64bits(v))
			}
			_, _ = s.udp.Write(buf)
		} else {
			_, _ = s.udp.Write([]byte(line + "\n"))
		}
	}
	return nil
}
