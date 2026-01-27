#include "sercom_spi.h"
#include "same51.h"

// SERCOM1 SPI pins (SAME51J20A):
// PA16 = SERCOM1 PAD[0] = MOSI (PMUX C)
// PA17 = SERCOM1 PAD[1] = SCK  (PMUX C)
// PA19 = SERCOM1 PAD[3] = MISO (PMUX C)
// CS pins are GPIO: PA20 (accel), PA21 (gyro)

#define SPI_MOSI_PIN 16
#define SPI_SCK_PIN  17
#define SPI_MISO_PIN 19

void spi_init(void) {
    // Disable SERCOM1 before configuration
    SERCOM1_SPI->CTRLA = SERCOM_CTRLA_SWRST;
    while (SERCOM1_SPI->SYNCBUSY & 1) {
    }

    // Configure pins for SERCOM1 (PMUX function C = 0x02)
    // MOSI (PA16)
    PORTA->PINCFG[SPI_MOSI_PIN] = PORT_PINCFG_PMUXEN;
    PORTA->PMUX[SPI_MOSI_PIN / 2] &= ~0x0F;
    PORTA->PMUX[SPI_MOSI_PIN / 2] |= 0x02; // Function C

    // SCK (PA17)
    PORTA->PINCFG[SPI_SCK_PIN] = PORT_PINCFG_PMUXEN;
    PORTA->PMUX[SPI_SCK_PIN / 2] &= ~0xF0;
    PORTA->PMUX[SPI_SCK_PIN / 2] |= (0x02 << 4); // Function C

    // MISO (PA19)
    PORTA->PINCFG[SPI_MISO_PIN] = PORT_PINCFG_PMUXEN | PORT_PINCFG_INEN;
    PORTA->PMUX[SPI_MISO_PIN / 2] &= ~0xF0;
    PORTA->PMUX[SPI_MISO_PIN / 2] |= (0x02 << 4); // Function C

    // Configure SERCOM1 as SPI master
    // CTRLA: MODE=SPI_MASTER, DOPO=0 (MOSI=PAD0, SCK=PAD1), DIPO=3 (MISO=PAD3)
    // CPOL=1, CPHA=1 for SPI mode 3 (BMI088 default)
    SERCOM1_SPI->CTRLA = SERCOM_CTRLA_MODE_SPI
                       | (0 << 16)   // DOPO: PAD0=MOSI, PAD1=SCK
                       | (3 << 20)   // DIPO: PAD3=MISO
                       | (1 << 28)   // CPOL
                       | (1 << 29);  // CPHA

    // CTRLB: enable receiver
    SERCOM1_SPI->CTRLB = SERCOM_SPI_CTRLB_RXEN;
    while (SERCOM1_SPI->SYNCBUSY) {
    }

    // BAUD: fBAUD = fREF / (2 * (BAUD + 1))
    // For 48 MHz and ~4 MHz SPI: BAUD = 48/(2*4) - 1 = 5
    SERCOM1_SPI->BAUD = 5;

    // Enable SERCOM1
    SERCOM1_SPI->CTRLA |= SERCOM_CTRLA_ENABLE;
    while (SERCOM1_SPI->SYNCBUSY) {
    }
}

uint8_t spi_transfer(uint8_t data) {
    // Wait for data register empty
    while (!(SERCOM1_SPI->INTFLAG & SERCOM_SPI_INTFLAG_DRE)) {
    }
    SERCOM1_SPI->DATA = data;

    // Wait for receive complete
    while (!(SERCOM1_SPI->INTFLAG & SERCOM_SPI_INTFLAG_RXC)) {
    }
    return (uint8_t)SERCOM1_SPI->DATA;
}
