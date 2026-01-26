#include "imu_input.h"

#include <string.h>
#include <stdlib.h>

#include "uart.h"

void imu_csv_init(imu_csv_parser_t *p) {
	p->idx = 0;
}

static bool parse_line(const char *line, imu_sample_t *out) {
	if (line[0] == 't') {
		return false; // header
	}
	char tmp[128];
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
		return false;
	}
	out->t = vals[0];
	out->gx = vals[1];
	out->gy = vals[2];
	out->gz = vals[3];
	out->ax = vals[4];
	out->ay = vals[5];
	out->az = vals[6];
	return true;
}

bool imu_csv_poll(imu_csv_parser_t *p, imu_sample_t *out) {
	uint8_t b;
	while (uart_read_byte(&b)) {
		if (b == '\n' || b == '\r') {
			if (p->idx == 0) {
				continue;
			}
			p->buf[p->idx] = '\0';
			p->idx = 0;
			return parse_line(p->buf, out);
		}
		if (p->idx < sizeof(p->buf) - 1) {
			p->buf[p->idx++] = (char)b;
		} else {
			p->idx = 0;
		}
	}
	return false;
}
