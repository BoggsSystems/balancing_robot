#ifndef BMI088_H
#define BMI088_H

#include <stdint.h>

typedef struct {
    int16_t ax, ay, az;
    int16_t gx, gy, gz;
} bmi088_sample_t;

typedef struct {
    float ax, ay, az;
    float gx, gy, gz;
} bmi088_scaled_t;

void bmi088_init(void);
void bmi088_read_raw(bmi088_sample_t *out);
void bmi088_read_scaled(bmi088_scaled_t *out);

#endif
