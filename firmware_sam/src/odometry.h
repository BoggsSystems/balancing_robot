#ifndef ODOMETRY_H
#define ODOMETRY_H

#include <stdint.h>

// Physical constants - adjust for your robot
#define WHEEL_DIAMETER_MM  60.0f
#define STEPS_PER_REV      3200.0f   // 200 steps/rev * 16 microsteps
#define GRAVITY_MPS2       9.80665f

typedef struct {
    float distance_m;      // Total distance travelled (m)
    float velocity_mps;    // Linear velocity (m/s), positive = forward
    float accel_fwd;       // Forward acceleration (m/s^2), body frame
    float accel_lat;       // Lateral acceleration (m/s^2), body frame
} odometry_t;

void odometry_update(odometry_t *o,
                    int32_t pos_left, int32_t pos_right,
                    int32_t speed_left, int32_t speed_right,
                    float ax, float ay, float az,
                    float roll, float pitch,
                    float dt);

#endif
