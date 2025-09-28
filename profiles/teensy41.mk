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

build_f_cpu = 600000000
build_board_def=ARM_TEENSY41

arduino_arch_preproc_def = -DARDUINO_TEENSY41 -D__IMXRT1062__ -DTEENSYDUINO=159

CFLAGS += -DLAYOUT_US_ENGLISH
CFLAGS += -DUSB_SERIAL


FLASH_TOOL_DIR := teensy-monitor
FLASH_VERSION := 1.59.0
FLASH_TOOL_FILE_NAME := teensy-monitor
FLASH_BINDIR := $(ARDUINO_DATA_DIR)/packages/$(ARDUINO_PACKAGE)/tools/$(FLASH_TOOL_DIR)/$(FLASH_VERSION)/

# We have found the fully-qualified path to the teensy-monitor to use.
TEENSY_MON := $(realpath $(FLASH_BINDIR)/teensy-monitor)
FLASH_PRGM := $(TEENSY_MON)
FLASH_ARGS = --info --debug --port=$(UPLOAD_PORT) -U --offset=0x4000 --arduino-erase --write $(flash_bin_file)
UPLOAD_FLASH_ARGS = $(FLASH_ARGS) --reset
VERIFY_FLASH_ARGS = $(FLASH_ARGS) --verify --reset
