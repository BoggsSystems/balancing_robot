#include "control.h"

static float clamp(float v, float limit) {
    if (limit <= 0.0f) {
        return v;
    }
    if (v > limit) {
        return limit;
    }
    if (v < -limit) {
        return -limit;
    }
    return v;
}

void pid_init(pid_ctrl_t *p, float kp, float ki, float kd, float output_limit) {
    p->kp = kp;
    p->ki = ki;
    p->kd = kd;
    p->integral = 0.0f;
    p->prev_error = 0.0f;
    p->output_limit = output_limit;
}

float pid_update(pid_ctrl_t *p, float error, float dt) {
    if (dt <= 0.0f) {
        return 0.0f;
    }
    p->integral += error * dt;
    float derivative = (error - p->prev_error) / dt;
    p->prev_error = error;

    float out = p->kp * error + p->ki * p->integral + p->kd * derivative;
    return clamp(out, p->output_limit);
}

motor_cmd_t motor_mix(float balance, float throttle, float turn, float limit) {
    motor_cmd_t cmd;
    float base = balance + throttle;
    cmd.left = clamp(base + turn, limit);
    cmd.right = clamp(base - turn, limit);
    return cmd;
}
