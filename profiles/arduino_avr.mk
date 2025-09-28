



# TODO(aaron): Point to avr-gcc stuff a la adafruit-samd.mk and the arm g++.



# TODO(aaron): Clean this up and don't rely on $(__DETAILS), just code in the paths we
# know we need. This is just copied out of arduino.mk for posterity.

__FLASH_TOOLS := $(strip $(shell $(__DETAILS) | grep "Required tool" | grep "avrdude" | tail -1 ))
FLASH_VENDOR := $(strip $(shell echo "$(__FLASH_TOOLS)" | cut -d ' ' -f 3 | cut -d ':' -f 1))
FLASH_TOOLS_DIR := $(strip $(shell echo "$(__FLASH_TOOLS)" | cut -d ' ' -f 3 | cut -d ':' -f 2))
FLASH_VERSION := $(strip $(shell echo "$(__FLASH_TOOLS)" | cut -d ' ' -f 4))
FLASH_BINDIR := $(ARDUINO_DATA_DIR)/packages/$(FLASH_VENDOR)/tools/$(FLASH_TOOLS_DIR)/$(FLASH_VERSION)/bin
ifeq ($(origin AVRDUDE), undefined)
	AVRDUDE_NAME := $(strip $(shell ls -1 $(FLASH_BINDIR) | grep -e 'avrdude$$' | head -1))
	# We have found the fully-qualified path to the avrdude to use.
	AVRDUDE := $(realpath $(FLASH_BINDIR)/$(AVRDUDE_NAME))
endif
ifeq ($(origin AVRDUDE_CONF), undefined)
	AVRDUDE_CONF := $(realpath $(FLASH_BINDIR)/../etc/avrdude.conf)
endif
FLASH_PRGM := $(AVRDUDE)
FLASH_ARGS = -C$(AVRDUDE_CONF) -v -p$(build_mcu) -c$(AVR_PROGRAMMER) -P$(UPLOAD_PORT) -D -Uflash:w:$(flash_hex_file):i
# -V argument suppresses verification.
UPLOAD_FLASH_ARGS = -V $(FLASH_ARGS)
VERIFY_FLASH_ARGS = $(FLASH_ARGS)

