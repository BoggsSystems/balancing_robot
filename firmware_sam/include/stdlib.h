#ifndef STDLIB_H
#define STDLIB_H

#include <stdint.h>

#define NULL ((void *)0)

// Simple strtof implementation
static inline float strtof(const char *s, char **endptr) {
    float result = 0.0f;
    float sign = 1.0f;
    float fraction = 0.0f;
    float divisor = 1.0f;
    int in_fraction = 0;

    while (*s == ' ' || *s == '\t') s++;
    if (*s == '-') { sign = -1.0f; s++; }
    else if (*s == '+') { s++; }

    while (*s) {
        if (*s >= '0' && *s <= '9') {
            if (in_fraction) {
                divisor *= 10.0f;
                fraction += (*s - '0') / divisor;
            } else {
                result = result * 10.0f + (*s - '0');
            }
        } else if (*s == '.' && !in_fraction) {
            in_fraction = 1;
        } else {
            break;
        }
        s++;
    }

    if (endptr) *endptr = (char *)s;
    return sign * (result + fraction);
}

#endif
