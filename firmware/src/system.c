#include "system.h"

#include <avr/io.h>

void system_init(void) {
	// Keep default clock settings for now (4 MHz internal oscillator).
	// If you change clock sources, update F_CPU in the Makefile.
	(void)CLKCTRL.MCLKCTRLA;
}
