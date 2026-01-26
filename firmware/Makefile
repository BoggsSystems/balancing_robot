MCU := avr64dd32
F_CPU := 4000000UL

CC := avr-gcc
OBJCOPY := avr-objcopy

BAUD ?= 115200
EMU ?= 1
UPDI_PORT ?= /dev/tty.usbmodemXXXX
UART_PORT ?= /dev/tty.usbmodemYYYY

SRC := src/main.c src/system.c src/uart.c src/spi.c src/bmi088.c src/imu_input.c src/attitude.c src/control.c
BUILD := build
ELF := $(BUILD)/firmware.elf
HEX := $(BUILD)/firmware.hex

CFLAGS := -mmcu=$(MCU) -DF_CPU=$(F_CPU) -DUART_BAUD=$(BAUD) -DUSE_EMULATOR_UART=$(EMU) -Os -Wall -Wextra -std=gnu11
LDFLAGS := -mmcu=$(MCU)
LDLIBS := -lm

.PHONY: build flash monitor clean

build: $(HEX)

$(BUILD):
	mkdir -p $(BUILD)

$(ELF): $(SRC) | $(BUILD)
	$(CC) $(CFLAGS) $(SRC) -o $(ELF) $(LDLIBS)

$(HEX): $(ELF)
	$(OBJCOPY) -O ihex -R .eeprom $(ELF) $(HEX)

flash: build
	pymcuprog -d $(MCU) -t uart -u $(UPDI_PORT) -f $(HEX)

monitor:
	screen $(UART_PORT) $(BAUD)

clean:
	rm -rf $(BUILD)
