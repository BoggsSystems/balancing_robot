#include "uart.h"

#include <avr/io.h>

static uint16_t baud_to_reg(uint32_t baud) {
	if (baud == 0) {
		return 0;
	}
	// AVR Dx baud calculation (async, normal): BAUD = 64*F_CPU/(16*baud)
	return (uint16_t)((64UL * F_CPU) / (16UL * baud));
}

void uart_init(uint32_t baud) {
	UART_PORT.DIRSET = (1 << UART_TX_PIN);
	UART_PORT.DIRCLR = (1 << UART_RX_PIN);

	UART_USART.BAUD = baud_to_reg(baud);
	UART_USART.CTRLC = USART_CHSIZE_8BIT_gc;
	UART_USART.CTRLB = USART_TXEN_bm | USART_RXEN_bm;
}

void uart_write_byte(uint8_t b) {
	while (!(UART_USART.STATUS & USART_DREIF_bm)) {
	}
	UART_USART.TXDATAL = b;
}

void uart_write_str(const char *s) {
	while (*s) {
		uart_write_byte((uint8_t)*s++);
	}
}

bool uart_read_byte(uint8_t *out) {
	if (UART_USART.STATUS & USART_RXCIF_bm) {
		*out = UART_USART.RXDATAL;
		return true;
	}
	return false;
}
