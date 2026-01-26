#include "bmi088.h"

#include <avr/io.h>
#include <util/delay.h>

#include "spi.h"

// Adjust CS pins to your wiring.
#define ACCEL_CS_PORT PORTB
#define ACCEL_CS_PIN 0
#define GYRO_CS_PORT PORTB
#define GYRO_CS_PIN 1

#define BMI088_ACCEL_CHIP_ID 0x00
#define BMI088_GYRO_CHIP_ID 0x00

#define BMI088_ACCEL_X_LSB 0x12
#define BMI088_GYRO_X_LSB 0x02

static inline void cs_accel_low(void) { ACCEL_CS_PORT.OUTCLR = (1 << ACCEL_CS_PIN); }
static inline void cs_accel_high(void) { ACCEL_CS_PORT.OUTSET = (1 << ACCEL_CS_PIN); }
static inline void cs_gyro_low(void) { GYRO_CS_PORT.OUTCLR = (1 << GYRO_CS_PIN); }
static inline void cs_gyro_high(void) { GYRO_CS_PORT.OUTSET = (1 << GYRO_CS_PIN); }

static void read_regs(uint8_t reg, uint8_t *buf, uint8_t len, uint8_t accel) {
	uint8_t i;
	if (accel) {
		cs_accel_low();
	} else {
		cs_gyro_low();
	}
	spi_transfer(reg | 0x80);
	for (i = 0; i < len; i++) {
		buf[i] = spi_transfer(0x00);
	}
	if (accel) {
		cs_accel_high();
	} else {
		cs_gyro_high();
	}
}

static void write_reg(uint8_t reg, uint8_t val, uint8_t accel) {
	if (accel) {
		cs_accel_low();
	} else {
		cs_gyro_low();
	}
	spi_transfer(reg & 0x7F);
	spi_transfer(val);
	if (accel) {
		cs_accel_high();
	} else {
		cs_gyro_high();
	}
}

void bmi088_init(void) {
	ACCEL_CS_PORT.DIRSET = (1 << ACCEL_CS_PIN);
	GYRO_CS_PORT.DIRSET = (1 << GYRO_CS_PIN);
	cs_accel_high();
	cs_gyro_high();

	_delay_ms(10);

	// TODO: Configure accelerometer and gyro ranges/ODR based on desired rate.
	// This is a minimal stub to validate wiring.
	(void)BMI088_ACCEL_CHIP_ID;
	(void)BMI088_GYRO_CHIP_ID;
}

void bmi088_read_accel(int16_t *ax, int16_t *ay, int16_t *az) {
	uint8_t buf[6];
	read_regs(BMI088_ACCEL_X_LSB, buf, 6, 1);
	*ax = (int16_t)((buf[1] << 8) | buf[0]);
	*ay = (int16_t)((buf[3] << 8) | buf[2]);
	*az = (int16_t)((buf[5] << 8) | buf[4]);
}

void bmi088_read_gyro(int16_t *gx, int16_t *gy, int16_t *gz) {
	uint8_t buf[6];
	read_regs(BMI088_GYRO_X_LSB, buf, 6, 0);
	*gx = (int16_t)((buf[1] << 8) | buf[0]);
	*gy = (int16_t)((buf[3] << 8) | buf[2]);
	*gz = (int16_t)((buf[5] << 8) | buf[4]);
}

void bmi088_read_sample(bmi088_sample_t *out) {
	bmi088_read_accel(&out->ax, &out->ay, &out->az);
	bmi088_read_gyro(&out->gx, &out->gy, &out->gz);
}
