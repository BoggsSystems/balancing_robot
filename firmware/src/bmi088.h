#ifndef BMI088_H
#define BMI088_H

#include <stdint.h>

typedef struct {
	int16_t ax, ay, az;
	int16_t gx, gy, gz;
} bmi088_sample_t;

void bmi088_init(void);
void bmi088_read_accel(int16_t *ax, int16_t *ay, int16_t *az);
void bmi088_read_gyro(int16_t *gx, int16_t *gy, int16_t *gz);
void bmi088_read_sample(bmi088_sample_t *out);

#endif
