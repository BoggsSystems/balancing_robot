#ifndef RC_INPUT_H
#define RC_INPUT_H

#include <stdbool.h>
#include <stdint.h>

typedef struct {
    float throttle;
    float turn;
    bool enabled;
    uint8_t mode;
} rc_cmd_t;

typedef struct {
    char buf[64];
    unsigned int idx;
    rc_cmd_t last;
} rc_parser_t;

void rc_init(rc_parser_t *p);
bool rc_poll(rc_parser_t *p, rc_cmd_t *out);

#endif
