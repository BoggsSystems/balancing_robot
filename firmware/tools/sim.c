#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "../src/attitude.h"
#include "../src/control.h"

static int parse_line(const char *line,
					  float *t, float *gx, float *gy, float *gz,
					  float *ax, float *ay, float *az) {
	if (line[0] == 't') {
		return 0;
	}
	char tmp[256];
	strncpy(tmp, line, sizeof(tmp) - 1);
	tmp[sizeof(tmp) - 1] = '\0';

	char *save = NULL;
	char *tok = strtok_r(tmp, ",", &save);
	float vals[7];
	int count = 0;
	while (tok && count < 7) {
		vals[count++] = strtof(tok, NULL);
		tok = strtok_r(NULL, ",", &save);
	}
	if (count != 7) {
		return 0;
	}
	*t = vals[0];
	*gx = vals[1];
	*gy = vals[2];
	*gz = vals[3];
	*ax = vals[4];
	*ay = vals[5];
	*az = vals[6];
	return 1;
}

typedef struct {
	float t;
	float throttle;
	float turn;
	int enabled;
	int mode;
} rc_entry_t;

static int parse_rc_line(const char *line, rc_entry_t *out) {
	if (line[0] == 't') {
		return 0;
	}
	char tmp[128];
	strncpy(tmp, line, sizeof(tmp) - 1);
	tmp[sizeof(tmp) - 1] = '\0';

	char *save = NULL;
	char *tok = strtok_r(tmp, ",", &save);
	float vals[5];
	int count = 0;
	while (tok && count < 5) {
		vals[count++] = strtof(tok, NULL);
		tok = strtok_r(NULL, ",", &save);
	}
	if (count < 4) {
		return 0;
	}
	out->t = vals[0];
	out->throttle = vals[1];
	out->turn = vals[2];
	out->enabled = (vals[3] != 0.0f);
	if (count >= 5) {
		int mode = (int)vals[4];
		if (mode < 0) {
			mode = 0;
		}
		out->mode = mode;
	} else {
		out->mode = 0;
	}
	return 1;
}

/* Live RC from e2e-bridge: "RC,throttle,turn,enabled[,mode]" */
static int parse_rc_live(const char *line, rc_entry_t *out) {
	if (strncmp(line, "RC,", 3) != 0) {
		return 0;
	}
	char tmp[128];
	strncpy(tmp, line + 3, sizeof(tmp) - 1);
	tmp[sizeof(tmp) - 1] = '\0';

	char *save = NULL;
	char *tok = strtok_r(tmp, ",", &save);
	float vals[4];
	int count = 0;
	while (tok && count < 4) {
		vals[count++] = strtof(tok, NULL);
		tok = strtok_r(NULL, ",", &save);
	}
	if (count < 3) {
		return 0;
	}
	out->t = 0.0f;
	out->throttle = vals[0];
	out->turn = vals[1];
	out->enabled = (vals[2] != 0.0f);
	if (count >= 4) {
		int mode = (int)vals[3];
		if (mode < 0) {
			mode = 0;
		}
		out->mode = mode;
	} else {
		out->mode = 0;
	}
	return 1;
}

static rc_entry_t *load_rc_profile(const char *path, size_t *out_count) {
	FILE *f = fopen(path, "r");
	if (!f) {
		return NULL;
	}
	rc_entry_t *entries = NULL;
	size_t count = 0;
	size_t cap = 0;
	char line[128];
	while (fgets(line, sizeof(line), f)) {
		rc_entry_t e;
		if (!parse_rc_line(line, &e)) {
			continue;
		}
		if (count == cap) {
			cap = (cap == 0) ? 16 : cap * 2;
			rc_entry_t *next = realloc(entries, cap * sizeof(rc_entry_t));
			if (!next) {
				free(entries);
				fclose(f);
				return NULL;
			}
			entries = next;
		}
		entries[count++] = e;
	}
	fclose(f);
	*out_count = count;
	return entries;
}

int main(int argc, char **argv) {
	char line[256];
	float control_hz = 400.0f;
	float control_dt = 1.0f / 400.0f;
	float next_control_t = 0.0f;
	int control_started = 0;
	float step_hz = 0.0f;
	int step_emulate = 0;
	int32_t step_pos_left = 0;
	int32_t step_pos_right = 0;
	float step_acc_left = 0.0f;
	float step_acc_right = 0.0f;
	int trace = 0;
	float script_time = 0.0f;
	int last_mode = 0;
	int last_enabled = 0;
	int standup_active = 0;
	float standup_elapsed = 0.0f;

	attitude_filter_t filter;
	attitude_init(&filter);
	pid_ctrl_t pid;
	pid_init(&pid, 2.5f, 0.0f, 0.05f, 10.0f);

	unsigned int calib_count = 0;
	float roll_offset = 0.0f;
	float pitch_offset = 0.0f;
	const unsigned int calib_samples = 200;

	const char *rc_path = NULL;
	for (int i = 1; i < argc; i++) {
		if (strcmp(argv[i], "--rc") == 0) {
			if (i + 1 >= argc) {
				continue;
			}
			rc_path = argv[i + 1];
			i++;
			continue;
		}
		if (strcmp(argv[i], "--control-hz") == 0) {
			if (i + 1 >= argc) {
				continue;
			}
			control_hz = strtof(argv[i + 1], NULL);
			if (control_hz <= 0.0f) {
				control_hz = 400.0f;
			}
			control_dt = 1.0f / control_hz;
			i++;
			continue;
		}
		if (strcmp(argv[i], "--step-hz") == 0) {
			if (i + 1 >= argc) {
				continue;
			}
			step_hz = strtof(argv[i + 1], NULL);
			if (step_hz > 0.0f) {
				step_emulate = 1;
			}
			i++;
			continue;
		}
		if (strcmp(argv[i], "--trace") == 0) {
			trace = 1;
			continue;
		}
	}
	size_t rc_count = 0;
	rc_entry_t *rc_entries = NULL;
	size_t rc_idx = 0;
	rc_entry_t rc = {0};
	int use_live_rc = 0;
	rc_entry_t live_rc = {0};
	if (rc_path) {
		rc_entries = load_rc_profile(rc_path, &rc_count);
	}

	if (trace && step_emulate) {
		puts("t,roll,pitch,balance,left,right,pos_left,pos_right,mode,cmd_throttle,cmd_turn,target_pitch_deg");
	} else if (trace) {
		puts("t,roll,pitch,balance,left,right,mode,cmd_throttle,cmd_turn,target_pitch_deg");
	} else if (step_emulate) {
		puts("t,roll,pitch,balance,left,right,pos_left,pos_right");
	} else {
		puts("t,roll,pitch,balance,left,right");
	}
	while (fgets(line, sizeof(line), stdin)) {
		/* Live RC from e2e-bridge (app M: command) overrides file-based RC */
		if (parse_rc_live(line, &live_rc)) {
			use_live_rc = 1;
			continue;
		}

		float t, gx, gy, gz, ax, ay, az;
		if (!parse_line(line, &t, &gx, &gy, &gz, &ax, &ay, &az)) {
			continue;
		}

		if (calib_count < calib_samples) {
			float roll_acc = 0.0f;
			float pitch_acc = 0.0f;
			attitude_accel_angles(ax, ay, az, &roll_acc, &pitch_acc);
			roll_offset += roll_acc;
			pitch_offset += pitch_acc;
			calib_count++;
			if (calib_count == calib_samples) {
				roll_offset /= (float)calib_samples;
				pitch_offset /= (float)calib_samples;
			}
			continue;
		}

		if (!control_started) {
			next_control_t = t;
			control_started = 1;
		}
		if (t + 1e-6f < next_control_t) {
			continue;
		}
		next_control_t += control_dt;

		float roll = 0.0f;
		float pitch = 0.0f;
		attitude_update(&filter, gx, gy, gz, ax, ay, az, control_dt, &roll, &pitch);
		roll -= roll_offset;
		pitch -= pitch_offset;

		if (use_live_rc) {
			rc = live_rc;
		} else if (rc_entries) {
			while (rc_idx + 1 < rc_count && rc_entries[rc_idx + 1].t <= t) {
				rc_idx++;
			}
			if (rc_count > 0 && rc_entries[rc_idx].t <= t) {
				rc = rc_entries[rc_idx];
			}
		}
		if (!rc.enabled || rc.mode != last_mode || rc.enabled != last_enabled) {
			script_time = 0.0f;
			last_mode = rc.mode;
			last_enabled = rc.enabled;
		}
		if (rc.enabled && !last_enabled) {
			standup_active = 1;
			standup_elapsed = 0.0f;
		}
		if (!rc.enabled) {
			standup_active = 0;
		}
		float cmd_throttle = (rc.enabled) ? rc.throttle : 0.0f;
		float cmd_turn = (rc.enabled) ? rc.turn : 0.0f;
		float target_pitch = 0.0f;
		float target_pitch_deg = 0.0f;
		if (standup_active) {
			const float DEG2RAD = 3.14159265f / 180.0f;
			const float duration_s = 1.5f;
			float start_rad = -25.0f * DEG2RAD;
			float t_norm = standup_elapsed / duration_s;
			if (t_norm >= 1.0f) {
				t_norm = 1.0f;
				standup_active = 0;
			}
			target_pitch = start_rad + (0.0f - start_rad) * t_norm;
			target_pitch_deg = target_pitch * (180.0f / 3.14159265f);
			cmd_throttle = 0.0f;
			cmd_turn = 0.0f;
			standup_elapsed += control_dt;
		} else if (rc.enabled && rc.mode != 0) {
			if (rc.mode == 1) {
				cmd_throttle = 0.3f;
				cmd_turn = 0.2f;
			} else if (rc.mode >= 2 && rc.mode <= 4) {
				const float PI = 3.14159265f;
				float period_s = 4.0f;
				float turn_amp = 0.25f;
				if (rc.mode == 3) {
					period_s = 6.0f;
					turn_amp = 0.20f;
				} else if (rc.mode == 4) {
					period_s = 3.0f;
					turn_amp = 0.30f;
				}
				float phase = (2.0f * PI * script_time) / period_s;
				cmd_throttle = 0.3f;
				cmd_turn = turn_amp * sinf(phase);
			} else if (rc.mode == 5) {
				cmd_throttle = 0.0f;
				cmd_turn = 0.35f;
			} else if (rc.mode == 6) {
				const float period_s = 2.0f;
				float phase = script_time;
				while (phase >= period_s) {
					phase -= period_s;
				}
				cmd_throttle = (phase < 1.0f) ? 0.3f : 0.0f;
				cmd_turn = 0.0f;
			} else if (rc.mode == 7) {
				const float period_s = 6.0f;
				float phase = script_time;
				while (phase >= period_s) {
					phase -= period_s;
				}
				if (phase < 1.0f) {
					cmd_throttle = 0.3f;
					cmd_turn = 0.0f;
				} else if (phase < 1.5f) {
					cmd_throttle = 0.0f;
					cmd_turn = 0.35f;
				} else if (phase < 2.5f) {
					cmd_throttle = 0.3f;
					cmd_turn = 0.0f;
				} else if (phase < 3.0f) {
					cmd_throttle = 0.0f;
					cmd_turn = 0.35f;
				} else if (phase < 4.0f) {
					cmd_throttle = 0.3f;
					cmd_turn = 0.0f;
				} else if (phase < 4.5f) {
					cmd_throttle = 0.0f;
					cmd_turn = 0.35f;
				} else if (phase < 5.5f) {
					cmd_throttle = 0.3f;
					cmd_turn = 0.0f;
				} else {
					cmd_throttle = 0.0f;
					cmd_turn = 0.35f;
				}
			} else if (rc.mode == 8) {
				const float PI = 3.14159265f;
				const float period_s = 3.0f;
				float phase = (2.0f * PI * script_time) / period_s;
				cmd_throttle = 0.3f;
				cmd_turn = 0.40f * sinf(phase);
			} else if (rc.mode == 9) {
				const float DEG2RAD = 3.14159265f / 180.0f;
				cmd_throttle = 0.0f;
				cmd_turn = 0.0f;
				target_pitch = 5.0f * DEG2RAD;
				target_pitch_deg = 5.0f;
			} else if (rc.mode == 10) {
				const float DEG2RAD = 3.14159265f / 180.0f;
				cmd_throttle = 0.0f;
				cmd_turn = 0.0f;
				target_pitch = -5.0f * DEG2RAD;
				target_pitch_deg = -5.0f;
			} else if (rc.mode == 11) {
				const float PI = 3.14159265f;
				const float DEG2RAD = 3.14159265f / 180.0f;
				const float period_s = 10.0f;
				float phase = (2.0f * PI * script_time) / period_s;
				cmd_throttle = 0.0f;
				cmd_turn = 0.0f;
				target_pitch = (3.0f * DEG2RAD) * sinf(phase);
				target_pitch_deg = target_pitch * (180.0f / 3.14159265f);
			}
			script_time += control_dt;
		} else if (!rc.enabled) {
			cmd_throttle = 0.0f;
			cmd_turn = 0.0f;
		}
		float balance = pid_update(&pid, target_pitch - pitch, control_dt);
		motor_cmd_t cmd = motor_mix(balance, cmd_throttle, cmd_turn, 10.0f);

		if (step_emulate) {
			float speed_left = (cmd.left < 0.0f) ? -cmd.left : cmd.left;
			float speed_right = (cmd.right < 0.0f) ? -cmd.right : cmd.right;
			float ticks_f = step_hz * control_dt;
			int32_t ticks = (int32_t)(ticks_f + 0.5f);
			step_acc_left += speed_left * ticks;
			step_acc_right += speed_right * ticks;
			int32_t steps_left = 0;
			int32_t steps_right = 0;
			if (step_hz > 0.0f) {
				steps_left = (int32_t)(step_acc_left / step_hz);
				steps_right = (int32_t)(step_acc_right / step_hz);
				step_acc_left -= steps_left * step_hz;
				step_acc_right -= steps_right * step_hz;
			}
			if (cmd.left >= 0.0f) {
				step_pos_left += steps_left;
			} else {
				step_pos_left -= steps_left;
			}
			if (cmd.right >= 0.0f) {
				step_pos_right += steps_right;
			} else {
				step_pos_right -= steps_right;
			}

			if (trace) {
				printf("%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%d,%d,%d,%.3f,%.3f,%.2f\n",
					   t, roll, pitch, balance, cmd.left, cmd.right,
					   step_pos_left, step_pos_right, rc.mode, cmd_throttle, cmd_turn,
					   target_pitch_deg);
			} else {
				printf("%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%d,%d\n",
					   t, roll, pitch, balance, cmd.left, cmd.right,
					   step_pos_left, step_pos_right);
			}
		} else {
			if (trace) {
				printf("%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%d,%.3f,%.3f,%.2f\n",
					   t, roll, pitch, balance, cmd.left, cmd.right,
					   rc.mode, cmd_throttle, cmd_turn, target_pitch_deg);
			} else {
				printf("%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
					   t, roll, pitch, balance, cmd.left, cmd.right);
			}
		}
	}
	free(rc_entries);
	return 0;
}
