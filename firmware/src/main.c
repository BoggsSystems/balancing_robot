#include <avr/io.h>
#include <stdlib.h>
#include <util/delay.h>

#include "attitude.h"
#include "bmi088.h"
#include "control.h"
#include "imu_input.h"
#include "spi.h"
#include "system.h"
#include "uart.h"

#ifndef USE_EMULATOR_UART
#define USE_EMULATOR_UART 1
#endif

#define OUTPUT_EVERY_N 50
#define CALIB_SAMPLES 200
#define TARGET_PITCH 0.0f

static void print_hex16(int16_t v) {
	const char hex[] = "0123456789ABCDEF";
	uint16_t u = (uint16_t)v;
	char out[7];
	out[0] = '0';
	out[1] = 'x';
	out[2] = hex[(u >> 12) & 0xF];
	out[3] = hex[(u >> 8) & 0xF];
	out[4] = hex[(u >> 4) & 0xF];
	out[5] = hex[u & 0xF];
	out[6] = '\0';
	uart_write_str(out);
}

static void print_float(float v) {
	char buf[16];
	dtostrf(v, 0, 4, buf);
	uart_write_str(buf);
}

int main(void) {
	system_init();
	uart_init(UART_BAUD);
	spi_init();
	bmi088_init();

	uart_write_str("IMU firmware ready\r\n");

	attitude_filter_t filter;
	attitude_init(&filter);
	pid_t pid;
	pid_init(&pid, 2.5f, 0.0f, 0.05f, 10.0f);

#if USE_EMULATOR_UART
	imu_csv_parser_t parser;
	imu_csv_init(&parser);
	float last_t = 0.0f;
	unsigned int sample_count = 0;
	unsigned int calib_count = 0;
	float roll_offset = 0.0f;
	float pitch_offset = 0.0f;
	uart_write_str("UART CSV mode (t,gx,gy,gz,ax,ay,az)\r\n");
#endif

	while (1) {
#if USE_EMULATOR_UART
		imu_sample_t s;
		if (imu_csv_poll(&parser, &s)) {
			float dt = (last_t > 0.0f) ? (s.t - last_t) : (1.0f / 500.0f);
			last_t = s.t;

			float roll = 0.0f;
			float pitch = 0.0f;

			if (calib_count < CALIB_SAMPLES) {
				float roll_acc = 0.0f;
				float pitch_acc = 0.0f;
				attitude_accel_angles(s.ax, s.ay, s.az, &roll_acc, &pitch_acc);
				roll_offset += roll_acc;
				pitch_offset += pitch_acc;
				calib_count++;
				if (calib_count == CALIB_SAMPLES) {
					roll_offset /= (float)CALIB_SAMPLES;
					pitch_offset /= (float)CALIB_SAMPLES;
					uart_write_str("Calibration done\r\n");
				}
				continue;
			}

			attitude_update(&filter, s.gx, s.gy, s.gz, s.ax, s.ay, s.az, dt, &roll, &pitch);
			roll -= roll_offset;
			pitch -= pitch_offset;

			float error = TARGET_PITCH - pitch;
			float control = pid_update(&pid, error, dt);

			if ((sample_count++ % OUTPUT_EVERY_N) == 0) {
				uart_write_str("RP ");
				print_float(roll);
				uart_write_str(" ");
				print_float(pitch);
				uart_write_str(" U ");
				print_float(control);
				uart_write_str("\r\n");
			}
		}
#else
		bmi088_sample_t s;
		bmi088_read_sample(&s);

		uart_write_str("ACC ");
		print_hex16(s.ax);
		uart_write_str(" ");
		print_hex16(s.ay);
		uart_write_str(" ");
		print_hex16(s.az);

		uart_write_str(" GYR ");
		print_hex16(s.gx);
		uart_write_str(" ");
		print_hex16(s.gy);
		uart_write_str(" ");
		print_hex16(s.gz);
		uart_write_str("\r\n");

		_delay_ms(20);
#endif
	}
}
