#ifndef MOTION_SCRIPT_H
#define MOTION_SCRIPT_H

#include <stdint.h>

typedef struct {
	float t;
	uint8_t last_mode;
} motion_script_t;

void motion_script_init(motion_script_t *s);
void motion_script_reset(motion_script_t *s);

// mode: 0 = manual, 1 = circle, 2-4 = figure-8 variants, 5 = spin,
// 6 = stop-and-go, 7 = square, 8 = slalom (more modes can be added)
void motion_script_step(motion_script_t *s, uint8_t mode, float dt,
						float *out_throttle, float *out_turn);

#endif
