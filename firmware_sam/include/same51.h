#ifndef SAME51_H
#define SAME51_H

#include <stdint.h>

// Base addresses
#define SERCOM0_BASE 0x40003000UL
#define SERCOM1_BASE 0x40003400UL
#define PORT_BASE    0x41008000UL
#define GCLK_BASE    0x40001C00UL
#define MCLK_BASE    0x40000800UL
#define NVMCTRL_BASE 0x41004000UL
#define CPU_HZ       48000000UL

// PORT registers (Group A = 0, Group B = 1)
typedef struct {
	volatile uint32_t DIR;
	volatile uint32_t DIRCLR;
	volatile uint32_t DIRSET;
	volatile uint32_t DIRTGL;
	volatile uint32_t OUT;
	volatile uint32_t OUTCLR;
	volatile uint32_t OUTSET;
	volatile uint32_t OUTTGL;
	volatile uint32_t IN;
	volatile uint32_t CTRL;
	volatile uint32_t WRCONFIG;
	volatile uint32_t EVCTRL;
	volatile uint8_t  PMUX[16];
	volatile uint8_t  PINCFG[32];
} PortGroup;

#define PORT ((PortGroup *)(PORT_BASE))
#define PORTA (&PORT[0])
#define PORTB (&PORT[1])

// SERCOM USART mode registers
typedef struct {
	volatile uint32_t CTRLA;
	volatile uint32_t CTRLB;
	volatile uint32_t CTRLC;
	volatile uint16_t BAUD;
	volatile uint8_t  RXPL;
	volatile uint8_t  RESERVED0[5];
	volatile uint8_t  INTENCLR;
	volatile uint8_t  RESERVED1;
	volatile uint8_t  INTENSET;
	volatile uint8_t  RESERVED2;
	volatile uint8_t  INTFLAG;
	volatile uint8_t  RESERVED3;
	volatile uint16_t STATUS;
	volatile uint32_t SYNCBUSY;
	volatile uint8_t  RXERRCNT;
	volatile uint8_t  RESERVED4[7];
	volatile uint16_t DATA;
	volatile uint8_t  RESERVED5[6];
	volatile uint8_t  DBGCTRL;
} SercomUsart;

// SERCOM SPI mode registers
typedef struct {
	volatile uint32_t CTRLA;
	volatile uint32_t CTRLB;
	volatile uint32_t CTRLC;
	volatile uint8_t  BAUD;
	volatile uint8_t  RESERVED0[7];
	volatile uint8_t  INTENCLR;
	volatile uint8_t  RESERVED1;
	volatile uint8_t  INTENSET;
	volatile uint8_t  RESERVED2;
	volatile uint8_t  INTFLAG;
	volatile uint8_t  RESERVED3;
	volatile uint16_t STATUS;
	volatile uint32_t SYNCBUSY;
	volatile uint8_t  RESERVED4[4];
	volatile uint32_t ADDR;
	volatile uint32_t DATA;
	volatile uint8_t  RESERVED5[4];
	volatile uint8_t  DBGCTRL;
} SercomSpi;

#define SERCOM0_USART ((SercomUsart *)SERCOM0_BASE)
#define SERCOM1_SPI   ((SercomSpi *)SERCOM1_BASE)

// GCLK
typedef struct {
	volatile uint32_t CTRLA;
	volatile uint32_t SYNCBUSY;
	volatile uint32_t RESERVED0[6];
	volatile uint32_t GENCTRL[12];
	volatile uint32_t RESERVED1[12];
	volatile uint32_t PCHCTRL[48];
} Gclk;

#define GCLK ((Gclk *)GCLK_BASE)

// MCLK
typedef struct {
	volatile uint8_t  RESERVED0[1];
	volatile uint8_t  INTENCLR;
	volatile uint8_t  INTENSET;
	volatile uint8_t  INTFLAG;
	volatile uint8_t  HSDIV;
	volatile uint8_t  CPUDIV;
	volatile uint8_t  RESERVED1[10];
	volatile uint32_t AHBMASK;
	volatile uint32_t APBAMASK;
	volatile uint32_t APBBMASK;
	volatile uint32_t APBCMASK;
	volatile uint32_t APBDMASK;
} Mclk;

#define MCLK ((Mclk *)MCLK_BASE)

// SERCOM CTRLA bits
#define SERCOM_CTRLA_ENABLE     (1 << 1)
#define SERCOM_CTRLA_SWRST      (1 << 0)
#define SERCOM_CTRLA_MODE_SPI   (0x3 << 2)
#define SERCOM_CTRLA_MODE_USART (0x1 << 2)

// SERCOM SPI CTRLB bits
#define SERCOM_SPI_CTRLB_RXEN   (1 << 17)

// SERCOM SPI INTFLAG bits
#define SERCOM_SPI_INTFLAG_RXC  (1 << 2)
#define SERCOM_SPI_INTFLAG_TXC  (1 << 1)
#define SERCOM_SPI_INTFLAG_DRE  (1 << 0)

// SERCOM USART CTRLB bits
#define SERCOM_USART_CTRLB_RXEN (1 << 17)
#define SERCOM_USART_CTRLB_TXEN (1 << 16)

// SERCOM USART INTFLAG bits
#define SERCOM_USART_INTFLAG_RXC (1 << 2)
#define SERCOM_USART_INTFLAG_DRE (1 << 0)

// Pin function macros
#define PORT_PMUX_PMUXE(x) ((x) & 0xF)
#define PORT_PMUX_PMUXO(x) (((x) & 0xF) << 4)
#define PORT_PINCFG_PMUXEN (1 << 0)
#define PORT_PINCFG_INEN   (1 << 1)
#define PORT_PINCFG_PULLEN (1 << 2)

// GCLK peripheral channel IDs
#define GCLK_SERCOM0_CORE 7
#define GCLK_SERCOM1_CORE 8

// Cortex-M4 NVIC
#define NVIC_ISER ((volatile uint32_t *)0xE000E100UL)

// Cortex-M4 SysTick
typedef struct {
	volatile uint32_t CTRL;
	volatile uint32_t LOAD;
	volatile uint32_t VAL;
	volatile uint32_t CALIB;
} SysTick_Type;

#define SYSTICK ((SysTick_Type *)0xE000E010UL)

#define SYSTICK_CTRL_ENABLE    (1 << 0)
#define SYSTICK_CTRL_TICKINT   (1 << 1)
#define SYSTICK_CTRL_CLKSOURCE (1 << 2)

#endif
