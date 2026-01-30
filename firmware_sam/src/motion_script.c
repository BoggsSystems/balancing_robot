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
						float *out_throttle, float *out_turn,
						float *out_target_pitch_rad) {
	if (mode != s->last_mode) {
		motion_script_reset(s);
		s->last_mode = mode;
	}
	*out_target_pitch_rad = 0.0f;

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
	} else if (mode == 5) {
		// Spin in place: zero throttle, constant turn.
		*out_throttle = 0.0f;
		*out_turn = 0.35f;
	} else if (mode == 6) {
		// Stop-and-go: 1s forward, 1s stop.
		const float period_s = 2.0f;
		float phase = s->t;
		while (phase >= period_s) {
			phase -= period_s;
		}
		if (phase < 1.0f) {
			*out_throttle = 0.3f;
		} else {
			*out_throttle = 0.0f;
		}
		*out_turn = 0.0f;
	} else if (mode == 7) {
		// Square path: forward 1s, turn 0.5s, repeat.
		const float period_s = 6.0f;
		float phase = s->t;
		while (phase >= period_s) {
			phase -= period_s;
		}
		if (phase < 1.0f) {
			*out_throttle = 0.3f;
			*out_turn = 0.0f;
		} else if (phase < 1.5f) {
			*out_throttle = 0.0f;
			*out_turn = 0.35f;
		} else if (phase < 2.5f) {
			*out_throttle = 0.3f;
			*out_turn = 0.0f;
		} else if (phase < 3.0f) {
			*out_throttle = 0.0f;
			*out_turn = 0.35f;
		} else if (phase < 4.0f) {
			*out_throttle = 0.3f;
			*out_turn = 0.0f;
		} else if (phase < 4.5f) {
			*out_throttle = 0.0f;
			*out_turn = 0.35f;
		} else if (phase < 5.5f) {
			*out_throttle = 0.3f;
			*out_turn = 0.0f;
		} else {
			*out_throttle = 0.0f;
			*out_turn = 0.35f;
		}
	} else if (mode == 8) {
		// Slalom: forward with higher-amplitude sinusoidal turn.
		const float PI = 3.14159265f;
		const float period_s = 3.0f;
		float phase = (2.0f * PI * s->t) / period_s;
		*out_throttle = 0.3f;
		*out_turn = 0.40f * sinf(phase);
	} else if (mode == 9) {
		// Balance challenge: hold +5 degrees.
		*out_target_pitch_rad = 5.0f * (3.14159265f / 180.0f);
	} else if (mode == 10) {
		// Balance challenge: hold -5 degrees.
		*out_target_pitch_rad = -5.0f * (3.14159265f / 180.0f);
	} else if (mode == 11) {
		// Balance challenge: slow oscillation +/-3 degrees.
		const float PI = 3.14159265f;
		const float period_s = 10.0f;
		float phase = (2.0f * PI * s->t) / period_s;
		*out_target_pitch_rad = (3.0f * (3.14159265f / 180.0f)) * sinf(phase);
	} else {
		*out_throttle = 0.0f;
		*out_turn = 0.0f;
	}

	if (dt > 0.0f) {
		s->t += dt;
	}
}
