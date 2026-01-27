#ifndef MATH_H
#define MATH_H

// Use ARM Cortex-M4 FPU for basic operations
// For transcendental functions, use simple approximations

static inline float fabsf(float x) {
    return x < 0 ? -x : x;
}

// Fast inverse square root (Quake-style, good enough for IMU)
static inline float invsqrtf(float x) {
    float xhalf = 0.5f * x;
    int i = *(int*)&x;
    i = 0x5f3759df - (i >> 1);
    x = *(float*)&i;
    x = x * (1.5f - xhalf * x * x);
    return x;
}

static inline float sqrtf(float x) {
    if (x <= 0) return 0;
    return x * invsqrtf(x);
}

// Simple Taylor series approximations for trig functions
// These are accurate enough for IMU filtering

static inline float sinf(float x) {
    // Reduce to [-pi, pi]
    const float PI = 3.14159265f;
    while (x > PI) x -= 2*PI;
    while (x < -PI) x += 2*PI;
    // Taylor series: x - x^3/6 + x^5/120
    float x2 = x * x;
    float x3 = x2 * x;
    float x5 = x3 * x2;
    return x - x3 / 6.0f + x5 / 120.0f;
}

static inline float cosf(float x) {
    const float PI = 3.14159265f;
    return sinf(x + PI / 2.0f);
}

// atan2f approximation
static inline float atan2f(float y, float x) {
    const float PI = 3.14159265f;
    if (x == 0) {
        if (y > 0) return PI / 2;
        if (y < 0) return -PI / 2;
        return 0;
    }
    float abs_y = fabsf(y) + 1e-10f;
    float angle;
    if (x >= 0) {
        float r = (x - abs_y) / (x + abs_y);
        angle = 0.1963f * r * r * r - 0.9817f * r + PI / 4;
    } else {
        float r = (x + abs_y) / (abs_y - x);
        angle = 0.1963f * r * r * r - 0.9817f * r + 3 * PI / 4;
    }
    return y < 0 ? -angle : angle;
}

#endif
