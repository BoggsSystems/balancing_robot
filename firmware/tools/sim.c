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

int main(void) {
	char line[256];
	float last_t = 0.0f;
	const float default_dt = 1.0f / 500.0f;

	attitude_filter_t filter;
	attitude_init(&filter);
	pid_t pid;
	pid_init(&pid, 2.5f, 0.0f, 0.05f, 10.0f);

	unsigned int calib_count = 0;
	float roll_offset = 0.0f;
	float pitch_offset = 0.0f;
	const unsigned int calib_samples = 200;

	puts("t,roll,pitch,control");
	while (fgets(line, sizeof(line), stdin)) {
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

		float control = pid_update(&pid, 0.0f - pitch, dt);

		printf("%.6f,%.6f,%.6f,%.6f\n", t, roll, pitch, control);
	}
	return 0;
}
