#include "attitude.h"

#include <math.h>

static void kalman_init(kalman_1d_t *k) {
    k->angle = 0.0f;
    k->bias = 0.0f;
    k->P00 = 0.0f;
    k->P01 = 0.0f;
    k->P10 = 0.0f;
    k->P11 = 0.0f;
}

static float kalman_update(kalman_1d_t *k, float new_angle, float new_rate, float dt) {
    const float Q_angle = 0.001f;
    const float Q_bias = 0.003f;
    const float R_measure = 0.03f;

    // Predict
    float rate = new_rate - k->bias;
    k->angle += dt * rate;

    k->P00 += dt * (dt*k->P11 - k->P01 - k->P10 + Q_angle);
    k->P01 -= dt * k->P11;
    k->P10 -= dt * k->P11;
    k->P11 += Q_bias * dt;

    // Update
    float S = k->P00 + R_measure;
    float K0 = k->P00 / S;
    float K1 = k->P10 / S;

    float y = new_angle - k->angle;
    k->angle += K0 * y;
    k->bias += K1 * y;

    float P00_temp = k->P00;
    float P01_temp = k->P01;
    k->P00 -= K0 * P00_temp;
    k->P01 -= K0 * P01_temp;
    k->P10 -= K1 * P00_temp;
    k->P11 -= K1 * P01_temp;

    return k->angle;
}

void attitude_init(attitude_filter_t *f) {
    kalman_init(&f->roll);
    kalman_init(&f->pitch);
}

void attitude_accel_angles(float ax, float ay, float az, float *roll, float *pitch) {
    float roll_acc = atan2f(ay, az);
    float pitch_acc = atan2f(-ax, sqrtf(ay*ay + az*az));
    if (roll) {
        *roll = roll_acc;
    }
    if (pitch) {
        *pitch = pitch_acc;
    }
}

void attitude_update(attitude_filter_t *f,
                     float gx, float gy, float gz,
                     float ax, float ay, float az,
                     float dt, float *roll, float *pitch) {
    (void)gz;
    float roll_acc = 0.0f;
    float pitch_acc = 0.0f;
    attitude_accel_angles(ax, ay, az, &roll_acc, &pitch_acc);

    float roll_k = kalman_update(&f->roll, roll_acc, gx, dt);
    float pitch_k = kalman_update(&f->pitch, pitch_acc, gy, dt);

    if (roll) {
        *roll = roll_k;
    }
    if (pitch) {
        *pitch = pitch_k;
    }
}
