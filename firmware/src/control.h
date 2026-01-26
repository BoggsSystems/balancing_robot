#ifndef CONTROL_H
#define CONTROL_H

typedef struct {
	float kp;
	float ki;
	float kd;
	float integral;
	float prev_error;
	float output_limit;
} pid_ctrl_t;

void pid_init(pid_ctrl_t *p, float kp, float ki, float kd, float output_limit);
float pid_update(pid_ctrl_t *p, float error, float dt);

typedef struct {
	float left;
	float right;
} motor_cmd_t;

motor_cmd_t motor_mix(float balance, float throttle, float turn, float limit);

#endif
