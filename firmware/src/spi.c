#include "spi.h"

#include <avr/io.h>

void spi_init(void) {
	SPI_PORT.DIRSET = (1 << SPI_MOSI_PIN) | (1 << SPI_SCK_PIN);
	SPI_PORT.DIRCLR = (1 << SPI_MISO_PIN);

	// SPI mode 3 by default; adjust CPOL/CPHA as needed.
	SPI0.CTRLA = SPI_ENABLE_bm | SPI_MASTER_bm | SPI_PRESC_DIV4_gc;
	SPI0.CTRLB = SPI_MODE_3_gc;
}

uint8_t spi_transfer(uint8_t data) {
	SPI0.DATA = data;
	while (!(SPI0.INTFLAGS & SPI_IF_bm)) {
	}
	return SPI0.DATA;
}
