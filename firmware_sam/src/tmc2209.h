#ifndef TMC2209_H
#define TMC2209_H

#include <stdint.h>

typedef struct {
    uint8_t step_pin;
    uint8_t dir_pin;
    uint8_t en_pin;
    int32_t position;
    int32_t target_speed;  // steps per second (signed for direction)
} tmc2209_t;

void tmc2209_init(tmc2209_t *m, uint8_t step_pin, uint8_t dir_pin, uint8_t en_pin);
void tmc2209_enable(tmc2209_t *m, int enable);
void tmc2209_set_speed(tmc2209_t *m, int32_t steps_per_sec);
void tmc2209_step(tmc2209_t *m);

// Call from timer interrupt at fixed rate (e.g., 10 kHz)
void tmc2209_tick(tmc2209_t *m, uint32_t tick_hz);

#endif
