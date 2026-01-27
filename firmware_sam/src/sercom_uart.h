#ifndef SERCOM_UART_H
#define SERCOM_UART_H

#include <stdbool.h>
#include <stdint.h>

void uart_init(uint32_t baud);
void uart_write_byte(uint8_t b);
void uart_write_str(const char *s);
bool uart_read_byte(uint8_t *out);

#endif
