/* Minimal libc stubs for -nostdlib builds.
 * GCC may emit calls to memset/memcpy for struct init/copy. */
#include <stdint.h>

typedef uint32_t size_t;
#define NULL ((void *)0)

void *memset(void *s, int c, size_t n) {
    uint8_t *p = (uint8_t *)s;
    uint8_t v = (uint8_t)c;
    while (n--) *p++ = v;
    return s;
}

void *memcpy(void *dst, const void *src, size_t n) {
    uint8_t *d = (uint8_t *)dst;
    const uint8_t *s = (const uint8_t *)src;
    while (n--) *d++ = *s++;
    return dst;
}
