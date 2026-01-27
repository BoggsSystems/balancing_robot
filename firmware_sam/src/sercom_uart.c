#include "sercom_uart.h"
#include "same51.h"

// SERCOM0 UART pins (SAME51J20A):
// PA04 = SERCOM0 PAD[0] = TX (PMUX D)
// PA05 = SERCOM0 PAD[1] = RX (PMUX D)

#define UART_TX_PIN 4
#define UART_RX_PIN 5

void uart_init(uint32_t baud) {
    // Disable SERCOM0 before configuration
    SERCOM0_USART->CTRLA = SERCOM_CTRLA_SWRST;
    while (SERCOM0_USART->SYNCBUSY & 1) {
    }

    // Configure pins for SERCOM0 (PMUX function D = 0x03)
    // TX (PA04)
    PORTA->PINCFG[UART_TX_PIN] = PORT_PINCFG_PMUXEN;
    PORTA->PMUX[UART_TX_PIN / 2] &= ~0x0F;
    PORTA->PMUX[UART_TX_PIN / 2] |= 0x03; // Function D

    // RX (PA05)
    PORTA->PINCFG[UART_RX_PIN] = PORT_PINCFG_PMUXEN | PORT_PINCFG_INEN;
    PORTA->PMUX[UART_RX_PIN / 2] &= ~0xF0;
    PORTA->PMUX[UART_RX_PIN / 2] |= (0x03 << 4); // Function D

    // Configure SERCOM0 as USART
    // CTRLA: MODE=USART_INT_CLK, TXPO=0 (TX=PAD0), RXPO=1 (RX=PAD1), DORD=1 (LSB first)
    SERCOM0_USART->CTRLA = SERCOM_CTRLA_MODE_USART
                         | (0 << 16)   // TXPO: TX on PAD0
                         | (1 << 20)   // RXPO: RX on PAD1
                         | (1 << 30);  // DORD: LSB first

    // CTRLB: enable TX and RX, 8-bit
    SERCOM0_USART->CTRLB = SERCOM_USART_CTRLB_TXEN | SERCOM_USART_CTRLB_RXEN;
    while (SERCOM0_USART->SYNCBUSY) {
    }

    // BAUD register (async arithmetic mode):
    // Pre-calculated for common baud rates at 48 MHz
    // BAUD = 65536 * (1 - 16 * fBAUD / fREF)
    uint16_t br;
    if (baud <= 9600) br = 62898;
    else if (baud <= 19200) br = 60293;
    else if (baud <= 38400) br = 55079;
    else if (baud <= 57600) br = 49564;
    else if (baud <= 115200) br = 63019;
    else br = 63019;  // default 115200
    SERCOM0_USART->BAUD = br;

    // Enable SERCOM0
    SERCOM0_USART->CTRLA |= SERCOM_CTRLA_ENABLE;
    while (SERCOM0_USART->SYNCBUSY) {
    }
}

void uart_write_byte(uint8_t b) {
    while (!(SERCOM0_USART->INTFLAG & SERCOM_USART_INTFLAG_DRE)) {
    }
    SERCOM0_USART->DATA = b;
}

void uart_write_str(const char *s) {
    while (*s) {
        uart_write_byte((uint8_t)*s++);
    }
}

bool uart_read_byte(uint8_t *out) {
    if (SERCOM0_USART->INTFLAG & SERCOM_USART_INTFLAG_RXC) {
        *out = (uint8_t)SERCOM0_USART->DATA;
        return true;
    }
    return false;
}
