TARGET := balancing_robot
MCU := ATSAME51J20A

CC := arm-none-eabi-gcc
OBJCOPY := arm-none-eabi-objcopy
SIZE := arm-none-eabi-size

BUILD := build

CFLAGS := -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
CFLAGS += -D__$(MCU)__ -DSAME51
CFLAGS += -Iinclude -Isrc
CFLAGS += -Os -Wall -Wextra -std=gnu11
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -ffreestanding -nostdinc

LDFLAGS := -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
LDFLAGS += -Tlinker/same51j20a.ld
LDFLAGS += -Wl,--gc-sections
LDFLAGS += -nostdlib -lgcc

SRC := src/startup.c src/system.c src/sercom_spi.c src/sercom_uart.c
SRC += src/bmi088.c src/attitude.c src/control.c src/rc_input.c
SRC += src/tmc2209.c src/main.c

OBJ := $(SRC:src/%.c=$(BUILD)/%.o)

.PHONY: all clean flash

all: $(BUILD)/$(TARGET).bin

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/%.o: src/%.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/$(TARGET).elf: $(OBJ)
	$(CC) $(LDFLAGS) $(OBJ) -o $@
	$(SIZE) $@

$(BUILD)/$(TARGET).bin: $(BUILD)/$(TARGET).elf
	$(OBJCOPY) -O binary $< $@

flash: $(BUILD)/$(TARGET).bin
	@echo "Use Microchip tools or OpenOCD to flash"

clean:
	rm -rf $(BUILD)
