#include "rc_input.h"

#include <stdlib.h>
#include <string.h>

#include "sercom_uart.h"

void rc_init(rc_parser_t *p) {
    p->idx = 0;
    p->last.throttle = 0.0f;
    p->last.turn = 0.0f;
    p->last.enabled = false;
}

static float clamp_unit(float v) {
    if (v > 1.0f) {
        return 1.0f;
    }
    if (v < -1.0f) {
        return -1.0f;
    }
    return v;
}

static bool parse_line(const char *line, rc_cmd_t *out) {
    // Expected format: "throttle,turn,enable"
    // Example: "0.10,-0.25,1"
    char tmp[64];
    strncpy(tmp, line, sizeof(tmp) - 1);
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
        return false;
    }
    out->throttle = clamp_unit(vals[0]);
    out->turn = clamp_unit(vals[1]);
    out->enabled = (vals[2] != 0.0f);
    return true;
}

bool rc_poll(rc_parser_t *p, rc_cmd_t *out) {
    uint8_t b;
    while (uart_read_byte(&b)) {
        if (b == '\n' || b == '\r') {
            if (p->idx == 0) {
                continue;
            }
            p->buf[p->idx] = '\0';
            p->idx = 0;
            rc_cmd_t parsed;
            if (parse_line(p->buf, &parsed)) {
                p->last = parsed;
                if (out) {
                    *out = parsed;
                }
                return true;
            }
            return false;
        }
        if (p->idx < sizeof(p->buf) - 1) {
            p->buf[p->idx++] = (char)b;
        } else {
            p->idx = 0;
        }
    }
    return false;
}
