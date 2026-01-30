#include "tmc2209.h"
#include "same51.h"

// TMC2209 uses STEP/DIR/EN interface
// EN is active low (LOW = enabled)
// DIR: HIGH = one direction, LOW = other direction
// STEP: rising edge triggers one microstep

void tmc2209_init(tmc2209_t *m, uint8_t step_pin, uint8_t dir_pin, uint8_t en_pin) {
    m->step_pin = step_pin;
    m->dir_pin = dir_pin;
    m->en_pin = en_pin;
    m->position = 0;
    m->target_speed = 0;
    m->step_accumulator = 0;

    // Configure pins as outputs
    PORTA->DIRSET = (1 << step_pin) | (1 << dir_pin) | (1 << en_pin);

    // Start with motor disabled (EN high)
    PORTA->OUTSET = (1 << en_pin);

    // Default direction
    PORTA->OUTCLR = (1 << dir_pin);

    // Step pin low
    PORTA->OUTCLR = (1 << step_pin);
}

void tmc2209_enable(tmc2209_t *m, int enable) {
    if (enable) {
        PORTA->OUTCLR = (1 << m->en_pin);  // EN low = enabled
    } else {
        PORTA->OUTSET = (1 << m->en_pin);  // EN high = disabled
    }
}

void tmc2209_set_speed(tmc2209_t *m, int32_t steps_per_sec) {
    m->target_speed = steps_per_sec;

    // Set direction
    if (steps_per_sec >= 0) {
        PORTA->OUTCLR = (1 << m->dir_pin);
    } else {
        PORTA->OUTSET = (1 << m->dir_pin);
    }
}

void tmc2209_step(tmc2209_t *m) {
    // Generate step pulse
    PORTA->OUTSET = (1 << m->step_pin);
    // Brief delay (TMC2209 needs ~100ns minimum)
    for (volatile int i = 0; i < 10; i++) {
        __asm__("nop");
    }
    PORTA->OUTCLR = (1 << m->step_pin);

    // Update position
    if (m->target_speed >= 0) {
        m->position++;
    } else {
        m->position--;
    }
}

// Simple velocity-based stepping
void tmc2209_tick(tmc2209_t *m, uint32_t tick_hz) {
    if (m->target_speed == 0) {
        return;
    }

    int32_t speed = m->target_speed;
    if (speed < 0) {
        speed = -speed;
    }

    // Accumulator-based step generation
    // step_accumulator += |speed|; if >= tick_hz, step and subtract tick_hz
    m->step_accumulator += speed;
    if ((uint32_t)m->step_accumulator >= tick_hz) {
        m->step_accumulator -= tick_hz;
        tmc2209_step(m);
    }
}
