#include "motion_script.h"
#include <math.h>

void motion_script_init(motion_script_t *s) {
	s->t = 0.0f;
	s->last_mode = 0;
}

void motion_script_reset(motion_script_t *s) {
	s->t = 0.0f;
}

void motion_script_step(motion_script_t *s, uint8_t mode, float dt,
						float *out_throttle, float *out_turn) {
	if (mode != s->last_mode) {
		motion_script_reset(s);
		s->last_mode = mode;
	}

	if (mode == 1) {
		// Circle: constant forward + constant turn.
		*out_throttle = 0.3f;
		*out_turn = 0.2f;
	} else if (mode >= 2 && mode <= 4) {
		// Figure-8 variants: constant forward, sinusoidal turn.
		const float PI = 3.14159265f;
		float period_s = 4.0f;
		float turn_amp = 0.25f;
		if (mode == 3) {
			period_s = 6.0f;
			turn_amp = 0.20f;
		} else if (mode == 4) {
			period_s = 3.0f;
			turn_amp = 0.30f;
		}
		float phase = (2.0f * PI * s->t) / period_s;
		*out_throttle = 0.3f;
		*out_turn = turn_amp * sinf(phase);
	} else {
		*out_throttle = 0.0f;
		*out_turn = 0.0f;
	}

	if (dt > 0.0f) {
		s->t += dt;
	}
}
