# Adafruit SAMD Cortex M0 / M4 build config.

ARDUINO_PACKAGE := teensy
ARCH := avr
ARCH_VER := 1.59.0

# The 'arch' element of the fqbn and the teensy package path is 'avr' but
# this is actually running on an ARM Cortex M7.
install_arch = armv7

# The /cores/arduino dir is actually at cores/teensy4 in this package.
arduino_core_name=teensy4

COMPILER_TOOLS_DIR := teensy-compile
COMPILER_VERSION := 11.3.1
COMPILER_BINDIR := $(ARDUINO_DATA_DIR)/packages/$(ARDUINO_PACKAGE)/tools/$(COMPILER_TOOLS_DIR)/$(COMPILER_VERSION)/arm/bin

COMPILER_NAME := arm-none-eabi-g++
AVR_CXX := $(realpath $(COMPILER_BINDIR)/$(COMPILER_NAME))
CXX := $(AVR_CXX)

AR_NAME := arm-none-eabi-ar
AVR_AR := $(realpath $(COMPILER_BINDIR)/$(AR_NAME))
AR := $(AVR_AR)

OBJCOPY_NAME := arm-none-eabi-objcopy
AVR_OBJCOPY := $(realpath $(COMPILER_BINDIR)/$(OBJCOPY_NAME))
OBJCOPY := $(AVR_OBJCOPY)

SIZE_NAME := arm-none-eabi-size
AVR_SIZE := $(realpath $(COMPILER_BINDIR)/$(SIZE_NAME))
SIZE := $(AVR_SIZE)


FLASH_TOOL_DIR := teensy-monitor
FLASH_VERSION := 1.59.0
FLASH_TOOL_FILE_NAME := teensy_loader_cli
FLASH_BINDIR := $(ARDUINO_DATA_DIR)/packages/$(ARDUINO_PACKAGE)/tools/$(FLASH_TOOL_DIR)/$(FLASH_VERSION)/

# We have found the fully-qualified path to the teensy-monitor to use.
TEENSY_CLI := $(realpath $(shell which teensy_loader_cli))
FLASH_PRGM := $(TEENSY_CLI)
FLASH_ARGS = -w -s -v --mcu=TEENSY41 $(flash_hex_file)
UPLOAD_FLASH_ARGS = $(FLASH_ARGS) 
VERIFY_FLASH_ARGS = $(FLASH_ARGS)


### Teensy-4.1-specific gcc config

# Teensy does a lot of funky things in its boards.txt and our janky parser can't keep up.
# So we just set a bunch of flags explicitly here rather than extract from boards.txt.

build_f_cpu = 600000000
build_board_def=ARM_TEENSY41

arduino_arch_preproc_def = -DARDUINO_TEENSY41 -D__IMXRT1062__ -DTEENSYDUINO=159

CFLAGS += -DLAYOUT_US_ENGLISH
CFLAGS += -DUSB_SERIAL

# Need to explicitly point to Teensy's linker script since it's not put in
# a 'variant' dir as-expected by Arduino.
__linker_script_base_path = $(ARDUINO_DATA_DIR)/packages/$(ARDUINO_PACKAGE)/hardware/$(ARCH)/$(ARCH_VER)/cores/teensy4
__linker_script_filename = imxrt1062_t41.ld
LDFLAGS += -T$(__linker_script_base_path)/$(__linker_script_filename)


# The build_mcu value of 'imxrt1062' declared by Teensy is not a valid microarchitecture
# for gcc. In fact it is a cortex-m7. Override how this value is sent to gcc.
build_cpu = cortex-m7


### ARM-specific gcc config (common to samd, teensy)

CFLAGS += -mcpu=$(build_cpu) -mthumb -nostdlib
# We generally want the L1 cache enabled on Arm devices.
CFLAGS += -DENABLE_CACHE
CFLAGS += -DUSBCON -DUSB_CONFIG_POWER=100

# Could consider promoting to general CXXFLAGS area? Why keep Arm-specific?
CXXFLAGS += -fno-rtti

LDARCH = -mcpu=$(build_cpu) -mthumb
LDFLAGS += --specs=nano.specs --specs=nosys.specs
