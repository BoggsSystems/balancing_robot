package model

import "math"

const Gravity = 9.80665

// Frame conventions:
// - World frame: X forward, Y right, Z up. Gravity points toward -Z.
// - Body frame: X forward, Y right, Z up (aligned with world at zero angles).
// - Euler angles: roll about +X, pitch about +Y, yaw about +Z (right-hand rule).
// With zero angles and no linear acceleration, accel reads (0, 0, +g).
type Orientation struct {
	Roll  float64 // rad
	Pitch float64 // rad
	Yaw   float64 // rad
}

func EulerToRotation(roll, pitch, yaw float64) [3][3]float64 {
	cr := math.Cos(roll)
	sr := math.Sin(roll)
	cp := math.Cos(pitch)
	sp := math.Sin(pitch)
	cy := math.Cos(yaw)
	sy := math.Sin(yaw)

	// R = Rz(yaw) * Ry(pitch) * Rx(roll)
	return [3][3]float64{
		{cy*cp, cy*sp*sr - sy*cr, cy*sp*cr + sy*sr},
		{sy*cp, sy*sp*sr + cy*cr, sy*sp*cr - cy*sr},
		{-sp, cp*sr, cp*cr},
	}
}

// RotateWorldToBody rotates a vector from world to body frame.
func RotateWorldToBody(roll, pitch, yaw float64, v [3]float64) [3]float64 {
	r := EulerToRotation(roll, pitch, yaw)
	return [3]float64{
		r[0][0]*v[0] + r[1][0]*v[1] + r[2][0]*v[2],
		r[0][1]*v[0] + r[1][1]*v[1] + r[2][1]*v[2],
		r[0][2]*v[0] + r[1][2]*v[1] + r[2][2]*v[2],
	}
}
