#ifndef STRING_H
#define STRING_H

#include <stdint.h>

#define NULL ((void *)0)

static inline size_t strlen(const char *s) {
    size_t len = 0;
    while (*s++) len++;
    return len;
}

static inline char *strncpy(char *dst, const char *src, size_t n) {
    char *d = dst;
    while (n > 0 && *src) {
        *d++ = *src++;
        n--;
    }
    while (n > 0) {
        *d++ = '\0';
        n--;
    }
    return dst;
}

static inline void *memset(void *s, int c, size_t n) {
    uint8_t *p = (uint8_t *)s;
    while (n--) *p++ = (uint8_t)c;
    return s;
}

static inline void *memcpy(void *dst, const void *src, size_t n) {
    uint8_t *d = (uint8_t *)dst;
    const uint8_t *s = (const uint8_t *)src;
    while (n--) *d++ = *s++;
    return dst;
}

static inline char *strtok_r(char *str, const char *delim, char **saveptr) {
    char *start;
    if (str) {
        *saveptr = str;
    }
    start = *saveptr;
    if (!start) return NULL;

    // Skip leading delimiters
    while (*start) {
        const char *d = delim;
        int is_delim = 0;
        while (*d) {
            if (*start == *d) { is_delim = 1; break; }
            d++;
        }
        if (!is_delim) break;
        start++;
    }
    if (!*start) {
        *saveptr = NULL;
        return NULL;
    }

    // Find end of token
    char *end = start;
    while (*end) {
        const char *d = delim;
        int is_delim = 0;
        while (*d) {
            if (*end == *d) { is_delim = 1; break; }
            d++;
        }
        if (is_delim) {
            *end = '\0';
            *saveptr = end + 1;
            return start;
        }
        end++;
    }
    *saveptr = NULL;
    return start;
}

#endif
