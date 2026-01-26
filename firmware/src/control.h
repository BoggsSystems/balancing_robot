#ifndef CONTROL_H
#define CONTROL_H

typedef struct {
	float kp;
	float ki;
	float kd;
	float integral;
	float prev_error;
	float output_limit;
} pid_t;

void pid_init(pid_t *p, float kp, float ki, float kd, float output_limit);
float pid_update(pid_t *p, float error, float dt);

#endif
