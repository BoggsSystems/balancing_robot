#ifndef UART_H
#define UART_H

#include <stdbool.h>
#include <stdint.h>

// Adjust these pins to match Curiosity Nano routing.
#define UART_USART USART0
#define UART_PORT PORTA
#define UART_TX_PIN 0
#define UART_RX_PIN 1

void uart_init(uint32_t baud);
void uart_write_byte(uint8_t b);
void uart_write_str(const char *s);
bool uart_read_byte(uint8_t *out);

#endif
