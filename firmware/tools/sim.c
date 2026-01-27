#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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
	float vals[4];
	int count = 0;
	while (tok && count < 4) {
		vals[count++] = strtof(tok, NULL);
		tok = strtok_r(NULL, ",", &save);
	}
	if (count != 4) {
		return 0;
	}
	out->t = vals[0];
	out->throttle = vals[1];
	out->turn = vals[2];
	out->enabled = (vals[3] != 0.0f);
	return 1;
}

/* Live RC from e2e-bridge: "RC,throttle,turn,enabled" (from app M: command) */
static int parse_rc_live(const char *line, rc_entry_t *out) {
	if (strncmp(line, "RC,", 3) != 0) {
		return 0;
	}
	char tmp[128];
	strncpy(tmp, line + 3, sizeof(tmp) - 1);
	tmp[sizeof(tmp) - 1] = '\0';

	char *save = NULL;
	char *tok = strtok_r(tmp, ",", &save);
	float vals[3];
	int count = 0;
	while (tok && count < 3) {
		vals[count++] = strtof(tok, NULL);
		tok = strtok_r(NULL, ",", &save);
	}
	if (count != 3) {
		return 0;
	}
	out->t = 0.0f;
	out->throttle = vals[0];
	out->turn = vals[1];
	out->enabled = (vals[2] != 0.0f);
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
	float last_t = 0.0f;
	const float default_dt = 1.0f / 500.0f;

	attitude_filter_t filter;
	attitude_init(&filter);
	pid_ctrl_t pid;
	pid_init(&pid, 2.5f, 0.0f, 0.05f, 10.0f);

	unsigned int calib_count = 0;
	float roll_offset = 0.0f;
	float pitch_offset = 0.0f;
	const unsigned int calib_samples = 200;

	const char *rc_path = NULL;
	for (int i = 1; i < argc - 1; i++) {
		if (strcmp(argv[i], "--rc") == 0) {
			rc_path = argv[i + 1];
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

	puts("t,roll,pitch,balance,left,right");
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
		float dt = (last_t > 0.0f) ? (t - last_t) : default_dt;
		last_t = t;

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

		float roll = 0.0f;
		float pitch = 0.0f;
		attitude_update(&filter, gx, gy, gz, ax, ay, az, dt, &roll, &pitch);
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
		float balance = pid_update(&pid, 0.0f - pitch, dt);
		float throttle = (rc.enabled) ? rc.throttle : 0.0f;
		float turn = (rc.enabled) ? rc.turn : 0.0f;
		motor_cmd_t cmd = motor_mix(balance, throttle, turn, 10.0f);

		printf("%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
			   t, roll, pitch, balance, cmd.left, cmd.right);
	}
	free(rc_entries);
	return 0;
}
