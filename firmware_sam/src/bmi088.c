#include "bmi088.h"
#include "same51.h"
#include "sercom_spi.h"

// CS pins on PORTA
#define ACCEL_CS_PIN 20
#define GYRO_CS_PIN  21

// BMI088 register addresses
#define BMI088_ACC_CHIP_ID      0x00
#define BMI088_ACC_DATA         0x12
#define BMI088_ACC_CONF         0x40
#define BMI088_ACC_RANGE        0x41
#define BMI088_ACC_PWR_CONF     0x7C
#define BMI088_ACC_PWR_CTRL     0x7D
#define BMI088_ACC_SOFTRESET    0x7E

#define BMI088_GYR_CHIP_ID      0x00
#define BMI088_GYR_DATA         0x02
#define BMI088_GYR_RANGE        0x0F
#define BMI088_GYR_BANDWIDTH    0x10
#define BMI088_GYR_SOFTRESET    0x14

// Expected chip IDs
#define BMI088_ACC_CHIP_ID_VAL  0x1E
#define BMI088_GYR_CHIP_ID_VAL  0x0F

// Scale factors
// Accel: ±3g range -> 10920 LSB/g
#define ACCEL_SCALE (9.80665f / 10920.0f)
// Gyro: ±2000 deg/s range -> 16.4 LSB/(deg/s) -> rad/s
#define GYRO_SCALE  (1.0f / 16.4f * 3.14159265f / 180.0f)

extern void delay_ms(uint32_t ms);

static inline void cs_accel_low(void)  { PORTA->OUTCLR = (1 << ACCEL_CS_PIN); }
static inline void cs_accel_high(void) { PORTA->OUTSET = (1 << ACCEL_CS_PIN); }
static inline void cs_gyro_low(void)   { PORTA->OUTCLR = (1 << GYRO_CS_PIN); }
static inline void cs_gyro_high(void)  { PORTA->OUTSET = (1 << GYRO_CS_PIN); }

static void accel_read_regs(uint8_t reg, uint8_t *buf, uint8_t len) {
    cs_accel_low();
    spi_transfer(reg | 0x80);
    spi_transfer(0x00); // dummy byte for BMI088 accel
    for (uint8_t i = 0; i < len; i++) {
        buf[i] = spi_transfer(0x00);
    }
    cs_accel_high();
}

static void accel_write_reg(uint8_t reg, uint8_t val) {
    cs_accel_low();
    spi_transfer(reg & 0x7F);
    spi_transfer(val);
    cs_accel_high();
}

static void gyro_read_regs(uint8_t reg, uint8_t *buf, uint8_t len) {
    cs_gyro_low();
    spi_transfer(reg | 0x80);
    for (uint8_t i = 0; i < len; i++) {
        buf[i] = spi_transfer(0x00);
    }
    cs_gyro_high();
}

static void gyro_write_reg(uint8_t reg, uint8_t val) {
    cs_gyro_low();
    spi_transfer(reg & 0x7F);
    spi_transfer(val);
    cs_gyro_high();
}

void bmi088_init(void) {
    // Configure CS pins as outputs, initially high
    PORTA->DIRSET = (1 << ACCEL_CS_PIN) | (1 << GYRO_CS_PIN);
    cs_accel_high();
    cs_gyro_high();

    delay_ms(10);

    // Soft reset accelerometer
    accel_write_reg(BMI088_ACC_SOFTRESET, 0xB6);
    delay_ms(50);

    // Dummy read to switch accel to SPI mode
    uint8_t dummy;
    accel_read_regs(BMI088_ACC_CHIP_ID, &dummy, 1);
    delay_ms(1);

    // Power on accelerometer
    accel_write_reg(BMI088_ACC_PWR_CONF, 0x00); // active mode
    delay_ms(5);
    accel_write_reg(BMI088_ACC_PWR_CTRL, 0x04); // enable accel
    delay_ms(50);

    // Configure accelerometer: ODR=400Hz, OSR=normal
    accel_write_reg(BMI088_ACC_CONF, 0xAC);
    // Range: ±3g
    accel_write_reg(BMI088_ACC_RANGE, 0x00);

    // Soft reset gyroscope
    gyro_write_reg(BMI088_GYR_SOFTRESET, 0xB6);
    delay_ms(50);

    // Configure gyroscope: ±2000 deg/s
    gyro_write_reg(BMI088_GYR_RANGE, 0x00);
    // Bandwidth: ODR=400Hz, filter=47Hz
    gyro_write_reg(BMI088_GYR_BANDWIDTH, 0x03);
    delay_ms(10);
}

void bmi088_read_raw(bmi088_sample_t *out) {
    uint8_t buf[6];

    accel_read_regs(BMI088_ACC_DATA, buf, 6);
    out->ax = (int16_t)((buf[1] << 8) | buf[0]);
    out->ay = (int16_t)((buf[3] << 8) | buf[2]);
    out->az = (int16_t)((buf[5] << 8) | buf[4]);

    gyro_read_regs(BMI088_GYR_DATA, buf, 6);
    out->gx = (int16_t)((buf[1] << 8) | buf[0]);
    out->gy = (int16_t)((buf[3] << 8) | buf[2]);
    out->gz = (int16_t)((buf[5] << 8) | buf[4]);
}

void bmi088_read_scaled(bmi088_scaled_t *out) {
    bmi088_sample_t raw;
    bmi088_read_raw(&raw);

    out->ax = raw.ax * ACCEL_SCALE;
    out->ay = raw.ay * ACCEL_SCALE;
    out->az = raw.az * ACCEL_SCALE;

    out->gx = raw.gx * GYRO_SCALE;
    out->gy = raw.gy * GYRO_SCALE;
    out->gz = raw.gz * GYRO_SCALE;
}
