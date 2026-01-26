#ifndef IMU_INPUT_H
#define IMU_INPUT_H

#include <stdbool.h>

typedef struct {
	float t;
	float gx, gy, gz;
	float ax, ay, az;
} imu_sample_t;

typedef struct {
	char buf[128];
	unsigned int idx;
} imu_csv_parser_t;

void imu_csv_init(imu_csv_parser_t *p);
bool imu_csv_poll(imu_csv_parser_t *p, imu_sample_t *out);

#endif
