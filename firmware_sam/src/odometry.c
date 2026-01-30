#include "odometry.h"
#include <math.h>

// Distance per step: (pi * diameter) / steps_per_rev
#define METERS_PER_STEP  (3.14159265f * (WHEEL_DIAMETER_MM / 1000.0f) / STEPS_PER_REV)

void odometry_update(odometry_t *o,
                    int32_t pos_left, int32_t pos_right,
                    int32_t speed_left, int32_t speed_right,
                    float ax, float ay, float az,
                    float roll, float pitch,
                    float dt) {
    (void)dt;

    // Distance: average of left and right wheel travel
    float steps_avg = 0.5f * ((float)pos_left + (float)pos_right);
    o->distance_m = steps_avg * METERS_PER_STEP;

    // Velocity: from commanded speed (steps/sec) -> m/s, positive = forward
    float speed_avg = 0.5f * ((float)speed_left + (float)speed_right);
    o->velocity_mps = speed_avg * METERS_PER_STEP;

    // Linear acceleration: subtract gravity from accel (body frame)
    // g in body frame when tilted: g_x = g*sin(pitch), g_y = -g*sin(roll)*cos(pitch), g_z = g*cos(roll)*cos(pitch)
    float cr = cosf(roll);
    float sr = sinf(roll);
    float cp = cosf(pitch);
    float sp = sinf(pitch);
    float gx = GRAVITY_MPS2 * sp;
    float gy = -GRAVITY_MPS2 * sr * cp;
    float gz = GRAVITY_MPS2 * cr * cp;
    o->accel_fwd = ax - gx;   // body x = forward
    o->accel_lat = ay - gy;   // body y = lateral
    (void)az;
    (void)gz;
}
