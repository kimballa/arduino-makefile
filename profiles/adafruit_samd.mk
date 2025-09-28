# Adafruit SAMD Cortex M0 / M4 build config.

ARDUINO_PACKAGE := adafruit
ARCH := samd
ARCH_VER := 1.7.16

COMPILER_TOOLS_DIR := arm-none-eabi-gcc
COMPILER_VERSION := 9-2019q4
COMPILER_BINDIR := $(ARDUINO_DATA_DIR)/packages/$(ARDUINO_PACKAGE)/tools/$(COMPILER_TOOLS_DIR)/$(COMPILER_VERSION)/bin

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

FLASH_TOOL_DIR := bossac
FLASH_VERSION := 1.8.0-48-gb176eee
FLASH_TOOL_FILE_NAME := bossac
FLASH_BINDIR := $(ARDUINO_DATA_DIR)/packages/$(ARDUINO_PACKAGE)/tools/$(FLASH_TOOL_DIR)/$(FLASH_VERSION)/

# We have found the fully-qualified path to the bossac to use.
BOSSAC := $(realpath $(FLASH_BINDIR)/bossac)
FLASH_PRGM := $(BOSSAC)
FLASH_ARGS = --info --debug --port=$(UPLOAD_PORT) -U --offset=0x4000 --arduino-erase --write $(flash_bin_file)
UPLOAD_FLASH_ARGS = $(FLASH_ARGS) --reset
VERIFY_FLASH_ARGS = $(FLASH_ARGS) --verify --reset
