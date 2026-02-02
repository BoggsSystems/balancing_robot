#include "sercom_uart.h"
#include "same51.h"

// SERCOM0 UART pins (SAME51J20A) - XBee:
// PA04 = SERCOM0 PAD[0] = TX (PMUX D)
// PA05 = SERCOM0 PAD[1] = RX (PMUX D)

// SERCOM5 UART pins - EDBG virtual serial (USB), so boot messages appear on Mac:
// PB16 = SERCOM5 PAD[0] = TX (PMUX C)
// PB17 = SERCOM5 PAD[1] = RX (PMUX C)

#define UART_TX_PIN 4
#define UART_RX_PIN 5
#define EDBG_TX_PIN 16
#define EDBG_RX_PIN 17

static uint16_t uart_baud_reg(uint32_t baud) {
    if (baud <= 9600) return 62898;
    if (baud <= 19200) return 60293;
    if (baud <= 38400) return 55079;
    if (baud <= 57600) return 49564;
    return 63019;  // 115200 default
}

void uart_init(uint32_t baud) {
    uint16_t br = uart_baud_reg(baud);

    // ---- SERCOM0 (XBee) ----
    SERCOM0_USART->CTRLA = SERCOM_CTRLA_SWRST;
    while (SERCOM0_USART->SYNCBUSY & 1) {
    }

    PORTA->PINCFG[UART_TX_PIN] = PORT_PINCFG_PMUXEN;
    PORTA->PMUX[UART_TX_PIN / 2] &= ~0x0F;
    PORTA->PMUX[UART_TX_PIN / 2] |= 0x03; // Function D

    PORTA->PINCFG[UART_RX_PIN] = PORT_PINCFG_PMUXEN | PORT_PINCFG_INEN;
    PORTA->PMUX[UART_RX_PIN / 2] &= ~0xF0;
    PORTA->PMUX[UART_RX_PIN / 2] |= (0x03 << 4);

    SERCOM0_USART->CTRLA = SERCOM_CTRLA_MODE_USART
                         | (0 << 16) | (1 << 20) | (1 << 30);
    SERCOM0_USART->CTRLB = SERCOM_USART_CTRLB_TXEN | SERCOM_USART_CTRLB_RXEN;
    while (SERCOM0_USART->SYNCBUSY) {
    }
    SERCOM0_USART->BAUD = br;
    SERCOM0_USART->CTRLA |= SERCOM_CTRLA_ENABLE;
    while (SERCOM0_USART->SYNCBUSY) {
    }

    // ---- SERCOM5 (EDBG virtual serial → USB) ----
    SERCOM5_USART->CTRLA = SERCOM_CTRLA_SWRST;
    while (SERCOM5_USART->SYNCBUSY & 1) {
    }

    PORTB->PINCFG[EDBG_TX_PIN] = PORT_PINCFG_PMUXEN;
    PORTB->PINCFG[EDBG_RX_PIN] = PORT_PINCFG_PMUXEN | PORT_PINCFG_INEN;
    PORTB->PMUX[EDBG_TX_PIN / 2] &= ~0x0F;
    PORTB->PMUX[EDBG_TX_PIN / 2] |= 0x02; // Function C = SERCOM5
    PORTB->PMUX[EDBG_RX_PIN / 2] &= ~0xF0;
    PORTB->PMUX[EDBG_RX_PIN / 2] |= (0x02 << 4);

    SERCOM5_USART->CTRLA = SERCOM_CTRLA_MODE_USART
                          | (0 << 16) | (1 << 20) | (1 << 30);
    SERCOM5_USART->CTRLB = SERCOM_USART_CTRLB_TXEN | SERCOM_USART_CTRLB_RXEN;
    while (SERCOM5_USART->SYNCBUSY) {
    }
    SERCOM5_USART->BAUD = br;
    SERCOM5_USART->CTRLA |= SERCOM_CTRLA_ENABLE;
    while (SERCOM5_USART->SYNCBUSY) {
    }
}

void uart_write_byte(uint8_t b) {
    while (!(SERCOM0_USART->INTFLAG & SERCOM_USART_INTFLAG_DRE)) {
    }
    SERCOM0_USART->DATA = b;
    while (!(SERCOM5_USART->INTFLAG & SERCOM_USART_INTFLAG_DRE)) {
    }
    SERCOM5_USART->DATA = b;
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
