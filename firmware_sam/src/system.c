#include "same51.h"

// System runs at 48 MHz from DFLL48M (default after reset on SAME51)
// For simplicity, we use the default clock configuration.

void system_init(void) {
    // Enable SERCOM0 and SERCOM1 in MCLK
    MCLK->APBAMASK |= (1 << 12); // SERCOM0
    MCLK->APBAMASK |= (1 << 13); // SERCOM1

    // Route GCLK0 (48 MHz) to SERCOM0 and SERCOM1
    GCLK->PCHCTRL[GCLK_SERCOM0_CORE] = (1 << 6) | 0; // Enable, GCLK0
    GCLK->PCHCTRL[GCLK_SERCOM1_CORE] = (1 << 6) | 0; // Enable, GCLK0
}

void delay_ms(uint32_t ms) {
    // Simple busy-wait delay (assumes ~48 MHz, rough estimate)
    for (volatile uint32_t i = 0; i < ms * 6000; i++) {
        __asm__("nop");
    }
}
