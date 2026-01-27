#include <stdint.h>
#include <stdbool.h>

#include "same51.h"
#include "sercom_spi.h"
#include "sercom_uart.h"
#include "bmi088.h"
#include "attitude.h"
#include "control.h"
#include "rc_input.h"
#include "tmc2209.h"

// Configuration
#define UART_BAUD       115200
#define LOOP_HZ         400
#define CALIB_SAMPLES   200
#define TARGET_PITCH    0.0f
#define MOTOR_LIMIT     1000.0f  // steps/sec limit

// LED pin on SAME51 Curiosity Nano (directly, typical is PA14)
#define LED_PIN 14

// Motor pins (adjust to your wiring)
#define LEFT_STEP_PIN   8
#define LEFT_DIR_PIN    9
#define LEFT_EN_PIN     10
#define RIGHT_STEP_PIN  11
#define RIGHT_DIR_PIN   12
#define RIGHT_EN_PIN    13

extern void system_init(void);
extern void delay_ms(uint32_t ms);

static void print_int(int32_t val) {
    char buf[12];
    int i = 0;
    int neg = 0;
    if (val < 0) { neg = 1; val = -val; }
    if (val == 0) { uart_write_byte('0'); return; }
    while (val > 0) {
        buf[i++] = '0' + (val % 10);
        val /= 10;
    }
    if (neg) uart_write_byte('-');
    while (i > 0) uart_write_byte(buf[--i]);
}

static void print_float(float val, int decimals) {
    if (val < 0) { uart_write_byte('-'); val = -val; }
    int32_t integer = (int32_t)val;
    print_int(integer);
    uart_write_byte('.');
    val -= integer;
    for (int d = 0; d < decimals; d++) {
        val *= 10;
        int digit = (int)val;
        uart_write_byte('0' + digit);
        val -= digit;
    }
}

static void led_init(void) {
    PORTA->DIRSET = (1 << LED_PIN);
}

static void led_on(void) {
    PORTA->OUTCLR = (1 << LED_PIN);  // Typically active low
}

static void led_off(void) {
    PORTA->OUTSET = (1 << LED_PIN);
}

__attribute__((unused))
static void led_toggle(void) {
    PORTA->OUTTGL = (1 << LED_PIN);
}

// Convert angle to degrees for display
static float rad_to_deg(float rad) {
    return rad * 180.0f / 3.14159265f;
}

int main(void) {
    system_init();
    led_init();
    uart_init(UART_BAUD);
    spi_init();
    bmi088_init();

    uart_write_str("SAME51 Balancing Robot Ready\r\n");

    // Initialize motors
    tmc2209_t motor_left, motor_right;
    tmc2209_init(&motor_left, LEFT_STEP_PIN, LEFT_DIR_PIN, LEFT_EN_PIN);
    tmc2209_init(&motor_right, RIGHT_STEP_PIN, RIGHT_DIR_PIN, RIGHT_EN_PIN);

    // Initialize filter and controller
    attitude_filter_t filter;
    attitude_init(&filter);

    pid_ctrl_t pid;
    pid_init(&pid, 50.0f, 0.0f, 2.0f, MOTOR_LIMIT);  // Tuning needed

    // RC input parser
    rc_parser_t rc_parser;
    rc_init(&rc_parser);
    rc_cmd_t rc = {0};

    // Calibration
    float roll_offset = 0.0f;
    float pitch_offset = 0.0f;
    uint32_t calib_count = 0;

    uart_write_str("Calibrating... hold still\r\n");

    // Timing
    const float dt = 1.0f / LOOP_HZ;
    uint32_t sample_count = 0;

    while (1) {
        // Poll XBee for RC commands
        rc_poll(&rc_parser, &rc);

        // Handle LED test command (enable toggles LED)
        static int last_enabled = 0;
        if (rc.enabled != last_enabled) {
            if (rc.enabled) {
                led_on();
                tmc2209_enable(&motor_left, 1);
                tmc2209_enable(&motor_right, 1);
            } else {
                led_off();
                tmc2209_enable(&motor_left, 0);
                tmc2209_enable(&motor_right, 0);
            }
            last_enabled = rc.enabled;
        }

        // Read IMU
        bmi088_scaled_t imu;
        bmi088_read_scaled(&imu);

        // Calibration phase
        if (calib_count < CALIB_SAMPLES) {
            float roll_acc = 0.0f, pitch_acc = 0.0f;
            attitude_accel_angles(imu.ax, imu.ay, imu.az, &roll_acc, &pitch_acc);
            roll_offset += roll_acc;
            pitch_offset += pitch_acc;
            calib_count++;

            if (calib_count == CALIB_SAMPLES) {
                roll_offset /= (float)CALIB_SAMPLES;
                pitch_offset /= (float)CALIB_SAMPLES;
                uart_write_str("Calibration done\r\n");
            }
            delay_ms(1000 / LOOP_HZ);
            continue;
        }

        // Update attitude filter
        float roll = 0.0f, pitch = 0.0f;
        attitude_update(&filter, imu.gx, imu.gy, imu.gz,
                        imu.ax, imu.ay, imu.az, dt, &roll, &pitch);
        roll -= roll_offset;
        pitch -= pitch_offset;

        // Balance control
        float error = TARGET_PITCH - pitch;
        float balance = pid_update(&pid, error, dt);

        // Apply RC mixing
        float throttle = rc.enabled ? (rc.throttle * 500.0f) : 0.0f;
        float turn = rc.enabled ? (rc.turn * 200.0f) : 0.0f;
        motor_cmd_t cmd = motor_mix(balance, throttle, turn, MOTOR_LIMIT);

        // Set motor speeds
        tmc2209_set_speed(&motor_left, (int32_t)cmd.left);
        tmc2209_set_speed(&motor_right, (int32_t)cmd.right);

        // Output telemetry (every 50 samples)
        if ((sample_count++ % 50) == 0) {
            uart_write_str("R:");
            print_float(rad_to_deg(roll), 1);
            uart_write_str(" P:");
            print_float(rad_to_deg(pitch), 1);
            uart_write_str(" L:");
            print_float(cmd.left, 0);
            uart_write_str(" R:");
            print_float(cmd.right, 0);
            uart_write_str("\r\n");
        }

        // Loop timing (simple delay - could use timer)
        delay_ms(1000 / LOOP_HZ);
    }

    return 0;
}
