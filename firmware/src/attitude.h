#ifndef ATTITUDE_H
#define ATTITUDE_H

typedef struct {
	float angle;
	float bias;
	float P00, P01, P10, P11;
} kalman_1d_t;

typedef struct {
	kalman_1d_t roll;
	kalman_1d_t pitch;
} attitude_filter_t;

void attitude_init(attitude_filter_t *f);
void attitude_accel_angles(float ax, float ay, float az, float *roll, float *pitch);
void attitude_update(attitude_filter_t *f,
					 float gx, float gy, float gz,
					 float ax, float ay, float az,
					 float dt, float *roll, float *pitch);

#endif
