#ifndef SPI_H
#define SPI_H

#include <stdint.h>

// Adjust these pins to match Curiosity Nano routing.
#define SPI_PORT PORTC
#define SPI_MOSI_PIN 0
#define SPI_MISO_PIN 1
#define SPI_SCK_PIN 2

void spi_init(void);
uint8_t spi_transfer(uint8_t data);

#endif
