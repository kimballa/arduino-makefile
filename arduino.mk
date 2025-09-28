# (c) Copyright 2021 Aaron Kimball
#
# Redistribution and use in source and binary forms, with or without modification, are
# permitted provided that the following conditions are met:
#
#   1. Redistributions of source code must retain the above copyright notice, this list of
#      conditions and the following disclaimer.
#   2. Redistributions in binary form must reproduce the above copyright notice, this list
#      of conditions and the following disclaimer in the documentation and/or other materials
#      provided with the distribution.
#   3. Neither the name of the copyright holder nor the names of its contributors may be
#      used to endorse or promote products derived from this software without specific prior
#      written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
#
#           A Makefile for Arduino-based build and upload capabilities
#
#
#
# You must set the following variables in your Makefile before including this .mk file:
#
#   BOARD 		- The fqbn of the board to use (e.g. 'arduino:avr:uno') or "auto" to autodetect
#               the connected board.
#   prog_name - The name of the program you're compiling (will generate '$(prog_name).elf', .hex...
#   lib_name  - The name of the library you're compiling (will generate 'lib$(lib_name).a')
#
#   You can also forcibly set $(TARGET) to override the default usage of $(prog_name) or
#   $(lib_name).
#
# Further configuration you can add to your Makefile:
#   build_dir - By default, outputs are put in "./build/"
#   src_dirs  - Specify all dirs of .cpp files to compile. (Default is '.')
#
#   libs      - List of libraries to link (e.g., "libs = foo bar" will link with -lfoo -lbar
#
#   include_dirs     - List of header directories to use with -I
#   sys_include_dirs - List of header directories to use with -isystem
#   lib_dirs     		 - List of lib directories to use with -L
#
#   CXXFLAGS  - Additional compiler flags
#   LDFLAGS   - Additional linker flags
#
#   OPTFLAGS  - Included in CFLAGS/CXXFLAGS, specific to optimization.
#   DBGFLAGS  - Included in CFLAGS/CXXFLAGS, specific to debugging.
#
#   XFLAGS    - More flags, added to .c, .cpp, and linker phase gcc/g++ inputs, *after*
#               all of the above. Intended to be useful for specifying overrides on the
#               `make` command line rather than to set within the config file directly.
#
#   install_headers - Specific list of header files to copy in `make install`;
#                     default is *.h in each of $(install_header_dirs).
#   install_header_dirs  - List of dirs containing *.h files to install. Defaults to $(src_dirs).
#   include_install_dir  - Directory where headers are copied to.
#                          Defaults to $(install_dir)/include/.
#   arch_specific_h - If defined, sets include_install_dir to an arch-specific subdir of include/.
#   mcu_specific_h  - If defined, sets include_install_dir to an MCU-specific subdir of include/.
#   use_header_suffix_dir - If set to 1, headers are copied to $(include_install_dir)/$(lib_name).
#   include_install_dir_suffix - If defined, headers are copied to
#                                $(include_install_dir)/$(include_install_dir_suffix).
#
# You can use the example Makefile (`Makefile.template`) as a basis to work from to get started
# quickly:
#     $ cp Makefile.template /path/to/your/project/Makefile
#
#
# If you have a file named .arduino_mk.conf in your home dir, it will be included
# to enable you to set defaults.
#
# Global config you may want to set there:
# BOARD 					  - The fqbn of the board to use (e.g. 'arduino:avr:uno') or 'auto' to autodetect
#                     the current connected board.
# ARDUINO_CLI       - Path to the `arduino-cli` tool (default is to discover via which(1))
# UPLOAD_PORT       - The serial port to deploy to
# UPLOAD_PROTOCOL   - 'serial' or 'usb'
# AVR_PROGRAMMER    - Programmer to invoke, e.g. 'avr109'
# TAGS_FILE         - filename to build for ctags
#
# install_dir       - Where library binaries & headers are installed. Used to install new
#                     libraries as well as link against existing ones.
#
# There is a template `arduino_mk_conf.template` config file for you to get started:
#     $ cp arduino_mk_conf.template $HOME/.arduino_mk.conf
#
# Use `make config` to see the active configuration.
# Use `make help` to see a list of available targets.

ARDUINO_MK_VER := 2.0.0
ARDUINO_MK_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

# If the user has a config file to set $BOARD, etc., include it here.
MAKE_CONF_FILE := $(HOME)/.arduino_mk.conf
ifeq ($(shell ls -1 $(MAKE_CONF_FILE) 2>/dev/null),$(MAKE_CONF_FILE))
$(info Loading user config file: $(MAKE_CONF_FILE)...)
include $(MAKE_CONF_FILE)
else
$(info No user config file found; it is recommended you copy arduino_mk_conf.template to)
$(info ~/.arduino_mk.conf and customize the template there.)
endif


.DEFAULT_GOAL := all

help:
	@echo "Available targets:"
	@echo "===================================="
ifneq ($(origin lib_name), undefined)
	@echo "all           : Same as 'library'"
else ifneq ($(origin prog_name), undefined)
	@echo "all           : Same as 'image'"
endif
	@echo "clean         : Remove intermediate / output files"
	@echo "config        : Show configuration"
	@echo "core          : Build the Arduino core (but not your code)"
	@echo "help          : Print this message"
ifneq ($(origin lib_name), undefined)
	@echo "install       : Install the library to $(install_dir)"
	@echo "library       : (default) Compile code for this library"
	@echo "lint          : Run arduino-lint on this library's source code"
else ifneq ($(origin prog_name), undefined)
	@echo "image         : (default) Compile code and prepare upload-ready files"
endif
	@echo "serial        : Open serial connection to Arduino"
	@echo "tags          : Run ctags"
ifneq ($(origin prog_name), undefined)
	@echo "upload        : Upload a compiled image to Arduino"
	@echo "verify        : Verify an uploaded image"
endif
	@echo ""
	@echo "$(TARGET)     : Compile your code"


########## Configuration settings ##########

# Set target dirs
build_dir ?= build

# Specify all directories containing .cpp files to compile.
src_dirs ?= .

# Set to serial port device for upload.
UPLOAD_PORT ?= /dev/ttyACM0
UPLOAD_PROTOCOL ?= serial
AVR_PROGRAMMER ?= avr109

TAGS_FILE = tags

PROFILES_DIR = $(ARDUINO_MK_DIR)/profiles
BOARD_PROFILE_INDEX_FILE = $(PROFILES_DIR)/profile_index.txt

# Set variables for compilation dependencies

ifneq (,$(install_dir))
# Directories where header files for Arduino libraries are installed to.
include_root=$(install_dir)/include
arch_include_root=$(include_root)/arch/$(install_arch)
mcu_include_root=$(arch_include_root)/$(build_mcu)

sys_include_dirs += $(mcu_include_root)
sys_include_dirs += $(arch_include_root)
sys_include_dirs += $(include_root)

lib_dirs += $(install_dir)/lib/arch/$(install_arch)/$(build_mcu)
else
$(info Warning: $$install_dir is not defined. It is recommended you set this in ~/.arduno_mk.conf)
$(info so that libraries and header files can be located.)
$(info )
endif # install_dir

sys_include_dirs += $(build_dir)/core/variant $(build_dir)/core

include_flags = $(addprefix -I,$(include_dirs)) $(addprefix -isystem,$(sys_include_dirs))
lib_flags = $(addprefix -L,$(lib_dirs)) $(addprefix -l,$(libs))

ifdef lib_name
ifndef install_header_dirs
# By default, install headers from all src directories to the shared /include/ dir.
install_header_dirs = $(src_dirs)
endif

ifndef install_headers
# Calculate list of header files to use with `make install`
install_headers_raw := $(abspath $(foreach dir,$(install_header_dirs),$(wildcard $(dir)/*.h)))
ifndef install_headers_root
install_headers_root := $(shell $(ARDUINO_MK_DIR)/common-prefix.py $(install_headers_raw))
endif
install_headers = $(install_headers_raw:$(install_headers_root)%=%)
endif

ifndef include_install_dir
ifneq ($(origin mcu_specific_h), undefined)
include_install_dir_base = $(mcu_include_root)
else ifneq ($(origin arch_specific_h), undefined)
include_install_dir_base = $(arch_include_root)
else
include_install_dir_base = $(include_root)
endif # flags controlling include_install_dir_base definition.

ifneq ($(origin include_install_dir_suffix), undefined)
# User has specified a particular "suffix dir" to install the header files to.
include_install_dir = $(include_install_dir_base)/$(include_install_dir_suffix)
else ifeq ($(use_header_suffix_dir), 1)
# User has requested that the libname be used as a header installation suffix dir.
include_install_dir = $(include_install_dir_base)/$(lib_name)
else
# Just use the "base" header installation dir.
include_install_dir = $(include_install_dir_base)
endif # if suffix dir defined

endif # if include_install_dir already defined
endif # if creating a library

# Set variables for programs we need access to.

ARDUINO_CLI := $(realpath $(shell which arduino-cli))
ifeq ($(origin CTAGS), undefined)
	CTAGS := ctags
endif

# Set conventions
SHELL ?= /bin/bash
.SUFFIXES:
.SUFFIXES: .ino .cpp .cxx .C .o

src_extensions ?= .ino .cpp .cxx .C .c .S

ifndef prog_name
ifndef lib_name
$(error "You must specify a target program with `prog_name` or target lib with `lib_name` to compile.")
endif
endif

ifdef prog_name
ifdef lib_name
$(error "You must specify at most one of `prog_name` or `lib_name`")
endif
endif

ifndef TARGET
ifneq ($(origin prog_name), undefined)
TARGET = $(build_dir)/$(prog_name).elf
else ifneq ($(origin lib_name), undefined)
TARGET = $(build_dir)/lib$(lib_name).a
endif
endif

eeprom_file = $(build_dir)/$(prog_name).eep
flash_hex_file = $(build_dir)/$(prog_name).hex
flash_bin_file = $(build_dir)/$(prog_name).bin

CACHED_ARDUINO_CONF_FILE := $(build_dir)/arduno-conf.mk
ifeq ($(shell ls -1 $(CACHED_ARDUINO_CONF_FILE) 2>/dev/null),$(CACHED_ARDUINO_CONF_FILE))

	# If we have already run arduino-cli to discover the build requirements, load them from
	# the cached makefile fragment.
$(info Loading cached Arduino config: $(CACHED_ARDUINO_CONF_FILE)...)
include $(CACHED_ARDUINO_CONF_FILE)

else ### (if cached arduino conf file exists) ###

	# Need to run arduino-cli to determine the connected board 
	# and then match that to a board profile.
	# Cache the results in $(CACHED_ARDUINO_CONF_FILE).
$(info Discovering Arduino build configuration...)

ifndef ARDUINO_DATA_DIR
	ARDUINO_DATA_DIR := $(HOME)/.arduino15
endif

ifndef BOARD
	BOARD := auto
endif

ifeq ($(BOARD), auto)
	# The user has asked us to auto-detect the board fqbn.
	# Use the first board in the list from `arduino-cli board list`
	TRUE_BOARD = $(strip $(shell $(ARDUINO_CLI) board list --no-color | awk '{ if (NR == 2) print $$(NF-1) }'))
else
  TRUE_BOARD = $(BOARD)
endif

ifeq ($(TRUE_BOARD),)
$(error "Empty board name specified or could not auto-detect board. You must specify BOARD=some:fqbn:here")
endif

	# Specific Arduino variant within fqbn.
	VARIANT := $(strip $(shell echo $(TRUE_BOARD) | head -1 | cut -d ':' -f 3))

	# Based on the current $TRUE_BOARD, determine which makefile include to use
	# to look up complete toolchain information for the architecture.
	BOARD_PROFILE_FILENAME = $(shell grep -v -e "^#" "$(BOARD_PROFILE_INDEX_FILE)" | grep -e "$(TRUE_BOARD)" "$(BOARD_PROFILE_INDEX_FILE)" | head -1 | awk --field-separator ',' '{print $$2}')
ifeq ($(BOARD_PROFILE_FILENAME),)
$(error "No Makefile profile available for fqbn: $(TRUE_BOARD)")
endif

$(info Resolved fqbn: $(TRUE_BOARD))
$(info Loading board profile: $(BOARD_PROFILE_FILENAME)...)
include $(PROFILES_DIR)/$(BOARD_PROFILE_FILENAME)


# The profile file includes values to assign to the following variables, which may be overridden
# in advance:
# ARDUINO_PACKAGE - should be 'arduino', 'adafruit', etc; subdir of packages/
# ARCH - should be 'avr', 'samd', etc.
# ARCH_VER - version number for the arch (core file, etc.)
# AVR_CXX - the fully-resolved path to the cross-compiler.


ARDUINO_PACKAGE_UPPER := $(strip $(shell echo $(ARDUINO_PACKAGE) | tr [:lower:] [:upper:]))

# True arch for compiler, install dir, etc., is /typically/ what is declared for $(ARCH)
# but this might be overridden in the profile, because Teensy.
install_arch ?= $(ARCH)

	arch_root_dir = $(ARDUINO_DATA_DIR)/packages/$(ARDUINO_PACKAGE)/hardware/$(ARCH)/$(ARCH_VER)
	arch_upper := $(strip $(shell echo $(ARCH) | tr [:lower:] [:upper:]))

	# Board definitions file for this hardware set.
	boards_txt := "$(arch_root_dir)/boards.txt"

	# Optimization flags to add to CFLAGS and LDFLAGS.
	OPTFLAGS += -Os -fdata-sections -ffunction-sections -Wl,--relax,--gc-sections

	# Debug-mode compilation options.
ifeq ($(origin DBGFLAGS), undefined)
	DBGFLAGS = -g
endif

	# Compiler flags we (might) want from arduino-ide's option set.
	CFLAGS += $(OPTFLAGS)
	CFLAGS += $(DBGFLAGS)

	# Compiler flags we need

	# This may be slightly different than $(VARIANT); indicates directory under /variants/
	build_variant := $(strip $(shell grep -e "^$(VARIANT).build.variant" $(boards_txt) | cut -d '=' -f 2-))

	# Arduino Core is usually at cores/arduino/ but some variants (e.g. Teensy) rename this.
	arduino_core_name ?= arduino
	core_dir := $(arch_root_dir)/cores/$(arduino_core_name)
	variant_dir := $(arch_root_dir)/variants/$(build_variant)

	# What directory structure exists under /core/ that we should pay attention to?
	# Used for -I as well as copying core files to build target.
	# Add a '.' on the front to capture the root of the $core_dir/ search (otherwise it's an empty str)
	core_subdirs = . $(shell find $(core_dir) -type d -printf '%P\n')

	sys_include_dirs += $(core_dir) $(variant_dir)

	# Common system architecture identification preprocessor definitions
	arduino_arch_preproc_def ?= -DARCH_$(arch_upper) -DARDUINO_ARCH_$(arch_upper) -DARDUINO_$(arch_upper)_$(ARDUINO_PACKAGE_UPPER)
	CFLAGS += $(arduino_arch_preproc_def)

	# Act as if we are a 1.8.0 Arduino IDE
	# This number really just needs to be > 100.
	ARDUINO_RUNTIME_VER=10800
	CFLAGS += -DARDUINO=$(ARDUINO_RUNTIME_VER)

	lib_dirs += $(variant_dir)

	# Get 'extra_flags' from boards.txt; disregard any requested interpolations
	raw_extra_flags := $(strip $(shell grep -e "^$(VARIANT).build.extra_flags" $(boards_txt) | cut -d '=' -f 2-))
	extra_flags := $(strip $(shell echo "$(raw_extra_flags)" | sed -e 's/{.*}//'))
	CFLAGS += $(extra_flags)

	# Add architecture-specific compiler and linker flags.
	# At minimum, we need to specify the architecture and subarchitecture/step compilation target.
		build_mcu := $(strip $(shell grep -e "^$(VARIANT).build.mcu" $(boards_txt) | cut -d '=' -f 2-))
	ifeq ($(install_arch), avr)
		# AVR-specific compiler options.
		CFLAGS += -mmcu=$(build_mcu)
		LDARCH = -mmcu=$(build_mcu)

		# link-time optimization creates great space savings, critical for AVR.
		# A bug in binutils (fixed in 2.35; see https://gcc.gnu.org/bugzilla/show_bug.cgi?id=83967)
		# makes it challenging to use in ARM projects with IRQ handlers, so AVR-only for now.
		# Fixed in ARM 2020-q4 toolchain but not available in Arduino / Adafruit SAMD toolchains.
		OPTFLAGS += -flto
	endif
	ifeq ($(install_arch), samd)
		# SAMD/ARM-specific compiler options.

		CMSIS_VER = $(strip $(shell \
			ls --reverse -1 $(ARDUINO_DATA_DIR)/packages/$(ARDUINO_PACKAGE)/tools/CMSIS | \
			head -1))

		CMSIS_ATMEL_VER = $(strip $(shell \
			ls --reverse -1 $(ARDUINO_DATA_DIR)/packages/$(ARDUINO_PACKAGE)/tools/CMSIS-Atmel | \
			head -1))

		CMSIS_DIR = $(ARDUINO_DATA_DIR)/packages/$(ARDUINO_PACKAGE)/tools/CMSIS/$(CMSIS_VER)
		CMSIS_ATMEL_DIR = $(ARDUINO_DATA_DIR)/packages/$(ARDUINO_PACKAGE)/tools/CMSIS-Atmel/$(CMSIS_ATMEL_VER)

		CFLAGS += -mcpu=$(build_mcu) -mthumb -nostdlib
		# We generally want the L1 cache enabled on SAMD devices.
		CFLAGS += -DENABLE_CACHE
		CFLAGS += -DUSBCON -DUSB_CONFIG_POWER=100
		# Add flags specific to Atmel/ARM standard library paths: math and signal processing lib code
		# is outside default search path; needed by Arduino core.
		sys_include_dirs += $(CMSIS_ATMEL_DIR)/CMSIS/Device/ATMEL
		sys_include_dirs += $(CMSIS_ATMEL_DIR)/CMSIS-Atmel/CMSIS/Device/ATMEL
		sys_include_dirs += $(CMSIS_DIR)/CMSIS/Core/Include
		sys_include_dirs += $(CMSIS_DIR)/CMSIS/DSP/Include

		# Could consider promoting to general CXXFLAGS area? Why keep SAMD-specific?
		CXXFLAGS += -fno-rtti

		LDARCH = -mcpu=$(build_mcu) -mthumb
		LDFLAGS += --specs=nano.specs --specs=nosys.specs
		# Add ARM CMSIS standard library paths for linker.
		lib_dirs += $(CMSIS_DIR)/CMSIS/Lib/GCC
		lib_dirs += $(CMSIS_DIR)/CMSIS/DSP/Lib/GCC
	endif

		# Define flags for architecture-specific ldscript if available.
	linker_script_arg := $(strip $(shell grep -e "^$(VARIANT).build.ldscript" $(boards_txt) | cut -d '=' -f 2-))
ifneq ($(linker_script_arg),)
	# We have a custom linker script to deploy; its path is relative to the variant dir.
  linker_script := $(variant_dir)/$(linker_script_arg)
	LDFLAGS += -T$(linker_script)
endif

	build_board_def ?= $(strip $(shell grep -e "^$(VARIANT).build.board" $(boards_txt) | cut -d '=' -f 2))
	CFLAGS += -DARDUINO_$(build_board_def) # e.g. -DARDUINO_AVR_LEONARDO

	build_f_cpu ?= $(strip $(shell grep -e "^$(VARIANT).build.f_cpu" $(boards_txt) | cut -d '=' -f 2))
	CFLAGS += -DF_CPU=$(build_f_cpu)

	build_vid ?= $(strip $(shell grep -e "^$(VARIANT).build.vid" $(boards_txt) | cut -d '=' -f 2))
	CFLAGS += -DUSB_VID=$(build_vid)

	build_pid ?= $(strip $(shell grep -e "^$(VARIANT).build.pid" $(boards_txt) | cut -d '=' -f 2))
	CFLAGS += -DUSB_PID=$(build_pid)

	build_usb_product := $(strip $(shell grep -e "^$(VARIANT).build.usb_product" $(boards_txt) | cut -d '=' -f 2))
	build_usb_mfr := $(strip $(shell grep -e "^$(VARIANT).build.usb_manufacturer" $(boards_txt) | \
			cut -d '=' -f 2))
	CFLAGS += "-DUSB_PRODUCT=\"\"$(subst ",\",$(build_usb_product))\"\""
	CFLAGS += "-DUSB_MANUFACTURER=\"\"$(subst ",\",$(build_usb_mfr))\"\""

	CFLAGS += -fno-exceptions

	CFLAGS += $(include_flags)


	# Include all the CFLAGS for C++ too.
	CXXFLAGS += $(CFLAGS)
	# TODO(aaron): Questionable to enforce by default... do we want to? (arduino-ide does...)
	CXXFLAGS += -Wno-error=narrowing

	# Additional flags specific to C++ compilation
	CXXFLAGS += -std=gnu++20
	CXXFLAGS += -fno-threadsafe-statics

	# g++ flags to use for invoking the linker
	LDFLAGS += $(OPTFLAGS) $(DBGFLAGS) -w -fuse-linker-plugin $(LDARCH)

	# Get additional LDFLAGS from boards.txt; disregard any lib dirs (we add separately).
	# Mostly kicking those out because they involve interpolations we can't do.
	raw_board_ld_flags := $(strip $(shell \
			grep -e "^$(VARIANT).compiler.*ldflags=" $(boards_txt) | cut -d '=' -f 2-))
	board_ld_flags := $(strip $(shell \
		echo '$(raw_board_ld_flags)' | awk 'BEGIN {RS=" "} !/-L/ {print $$1}' | xargs))

	LDFLAGS += $(board_ld_flags)

# Now that we've invested the time in discovering all these settings, write them out
# to a file that can be reloaded more quickly for the next build.
define CACHED_ARDUINO_CONF_TEXT
ARDUINO_DATA_DIR := $(ARDUINO_DATA_DIR)\n
BOARD := $(BOARD)\n
TRUE_BOARD := $(TRUE_BOARD)\n
VARIANT := $(VARIANT)\n
ARDUINO_PACKAGE := $(ARDUINO_PACKAGE)\n
ARDUINO_PACKAGE_UPPER := $(ARDUINO_PACKAGE_UPPER)\n
ARCH := $(ARCH)\n
ARCH_VER := $(ARCH_VER)\n
install_arch := $(install_arch)\n
COMPILER_TOOLS_DIR := $(COMPILER_TOOLS_DIR)\n
COMPILER_VERSION := $(COMPILER_VERSION)\n
COMPILER_BINDIR := $(COMPILER_BINDIR)\n
COMPILER_NAME := $(COMPILER_NAME)\n
AVR_CXX := $(AVR_CXX)\n
AR_NAME := $(AR_NAME)\n
AVR_AR := $(AVR_AR)\n
OBJCOPY_NAME := $(OBJCOPY_NAME)\n
AVR_OBJCOPY := $(AVR_OBJCOPY)\n
SIZE_NAME := $(SIZE_NAME)\n
AVR_SIZE := $(AVR_SIZE)\n
CXX := $(CXX)\n
AR := $(AR)\n
OBJCOPY := $(OBJCOPY)\n
SIZE := $(SIZE)\n
FLASH_TOOLS_DIR := $(FLASH_TOOLS_DIR)\n
FLASH_VERSION := $(FLASH_VERSION)\n
FLASH_BINDIR := $(FLASH_BINDIR)\n
FLASH_PRGM := $(FLASH_PRGM)\n
FLASH_ARGS := $(FLASH_ARGS)\n
UPLOAD_FLASH_ARGS := $(UPLOAD_FLASH_ARGS)\n
VERIFY_FLASH_ARGS := $(VERIFY_FLASH_ARGS)\n
arch_root_dir := $(arch_root_dir)\n
arch_upper := $(arch_upper)\n
boards_txt := $(boards_txt)\n
OPTFLAGS := $(OPTFLAGS)\n
DBGFLAGS := $(DBGFLAGS)\n
CFLAGS := $(CFLAGS)\n
CXXFLAGS := $(CXXFLAGS)\n
build_variant := $(build_variant)\n
core_dir := $(core_dir)\n
variant_dir := $(variant_dir)\n
core_subdirs := $(core_subdirs)\n
include_dirs := $(include_dirs)\n
sys_include_dirs := $(sys_include_dirs)\n
ARDUINO_RUNTIME_VER := $(ARDUINO_RUNTIME_VER)\n
lib_dirs := $(lib_dirs)\n
raw_extra_flags := $(raw_extra_flags)\n
extra_flags := $(extra_flags)\n
build_mcu := $(build_mcu)\n
LDARCH := $(LDARCH)\n
LDFLAGS := $(LDFLAGS)\n
linker_script_arg := $(linker_script_arg)\n
build_board_def := $(build_board_def)\n
build_f_cpu := $(build_f_cpu)\n
build_vid := $(build_vid)\n
build_pid := $(build_pid)\n
build_usb_product := $(build_usb_product)\n
build_usb_mfr := $(build_usb_mfr)\n
raw_board_ld_flags := $(raw_board_ld_flags)\n
board_ld_flags := $(board_ld_flags)
endef # CACHED_ARDUINO_CONF_TEXT

# avr-specific variables:
define CACHED_ARCH_VARS
AVRDUDE_NAME := $(AVRDUDE_NAME)\n
AVRDUDE := $(AVRDUDE)\n
AVRDUDE_CONF := $(AVRDUDE_CONF)
endef

# samd-specific variables:
define CACHED_ARCH_VARS
BOSSAC_NAME := $(BOSSAC_NAME)\n
BOSSAC := $(BOSSAC)\n
CMSIS_VER := $(CMSIS_VER)\n
CMSIS_ATMEL_VER := $(CMSIS_ATMEL_VER)\n
CMSIS_DIR := $(CMSIS_DIR)\n
CMSIS_ATMEL_DIR := $(CMSIS_ATMEL_DIR)
endef

$(info Caching configuration to file: $(CACHED_ARDUINO_CONF_FILE)...)
mkdir_cached_file_out := $(shell mkdir -p `dirname "$(CACHED_ARDUINO_CONF_FILE)"`)
make_cached_file_out := $(shell echo '$(CACHED_ARDUINO_CONF_TEXT)' > "$(CACHED_ARDUINO_CONF_FILE)")
append_cached_file_out := $(shell echo '$(CACHED_ARCH_VARS)' >> "$(CACHED_ARDUINO_CONF_FILE)")

endif ### (if cached arduino conf file exists) ###


# Finally, add extra 'XFLAGS' at end of each cli arg set.
CFLAGS += $(XFLAGS)
CXXFLAGS += $(XFLAGS)
LDFLAGS += $(XFLAGS)

$(info Building for target: $(TRUE_BOARD) [$(build_variant); $(build_mcu)])
$(info Toolchain (version $(COMPILER_VERSION)) location: $(COMPILER_BINDIR))
$(info )
######### end configuration section #########

config:
	@echo "Arduino build configuration:"
	@echo "===================================="
	@echo "arduino.mk    : $(ARDUINO_MK_VER)"
	@echo "BOARD (fqdn)  : $(TRUE_BOARD)"
	@echo ""
	@echo "Package       : $(ARDUINO_PACKAGE)"
	@echo "Architecture  : $(ARCH)"
	@echo "Arch version  : $(ARCH_VER)"
	@echo "Variant       : $(VARIANT) [$(build_variant)]"
	@echo "install_arch  : $(install_arch)"
	@echo "Chipset       : $(build_mcu)"
	@echo "Toolchain ver : $(COMPILER_VERSION)"
	@echo "Toolchain     : $(COMPILER_BINDIR)"
	@echo "Compiler      : $(COMPILER_NAME)"
	@echo ""
	@echo "Tool paths:"
	@echo "===================================="
	@echo "arduino-cli   : $(ARDUINO_CLI)"
ifneq ($(origin AVRDUDE), undefined)
	@echo "AVRDUDE       : $(AVRDUDE)"
endif
ifneq ($(origin BOSSAC), undefined)
	@echo "BOSSAC        : $(BOSSAC)"
endif
	@echo ""
	@echo "AR            : $(AR)"
	@echo "CXX           : $(CXX)"
	@echo "OBJCOPY       : $(OBJCOPY)"
	@echo "SIZE          : $(SIZE)"
	@echo ""
	@echo "Build paths:"
	@echo "===================================="
	@echo "build_dir     : $(build_dir)"
	@echo "src_dirs      : $(src_dirs)"
ifneq ($(origin prog_name), undefined)
	@echo "prog_name     : $(prog_name)"
endif
ifneq ($(origin lib_name), undefined)
	@echo "lib_name      : $(lib_name)"
endif
	@echo "TARGET        : $(TARGET)"
	@echo "src_files     : $(src_files)"
	@echo "obj_files     : $(obj_files)"
	@echo ""
	@echo "System paths:"
	@echo "===================================="
	@echo "install_dir       : $(install_dir)"
	@echo "include_dirs      : $(include_dirs)"
	@echo "sys_include_dirs  : $(sys_include_dirs)"
	@echo "lib_dirs          : $(lib_dirs)"
	@echo "include_root      : $(include_root)"
	@echo "arch_include_root : $(arch_include_root)"
	@echo "mcu_include_root  : $(mcu_include_root)"
	@echo ""
	@echo "Options:"
	@echo "===================================="
	@echo "libs            : $(libs)"
ifdef lib_name
	@echo "install_headers    : $(install_headers)"
	@echo "include_install_dir : $(include_install_dir)"
endif
	@echo ""
	@echo 'CFLAGS          : $(CFLAGS)'
	@echo ""
	@echo 'CXXFLAGS        : $(CXXFLAGS)'
	@echo ""
	@echo 'LDFLAGS         : $(LDFLAGS) $${...obj files...} $(lib_flags)'

serial:
	$(ARDUINO_CLI) monitor -p $(UPLOAD_PORT)

clean:
	-rm "$(TARGET)"
	-rm "$(CACHED_ARDUINO_CONF_FILE)"
	-rm -r "$(build_dir)"
	find . -name "*.o" -delete

distclean: clean
	-rm $(TAGS_FILE)


# The src files in build/core/ need to be copied into that dir by the core setup task, so their names can't
# be used as wildcard in depends; rely on the names of the upstream source files in the package
# core_dir.
core_cpp_filenames = $(shell find $(core_dir) -type f -name '*.cpp' -printf '%P\n')
core_c_filenames   = $(shell find $(core_dir) -type f -name '*.c'   -printf '%P\n')
core_asm_filenames = $(shell find $(core_dir) -type f -name '*.S'   -printf '%P\n')
core_h_filenames   = $(shell find $(core_dir) -type f -name '*.h'   -printf '%P\n')

core_h_dest_filenames = $(addprefix $(build_dir)/core/,$(core_h_filenames))

# Map the directory structure under /core/ to one we should replicate in our build target dir.
core_build_subdirs = $(addprefix $(build_dir)/core/,$(core_subdirs) variant)

# Map input cpp/c/asm files in real core dir tree to .o files in our build target tree.
core_obj_files = $(patsubst %.cpp,%.o,$(addprefix $(build_dir)/core/,$(core_cpp_filenames))) \
		$(patsubst %.c,%.o,$(addprefix $(build_dir)/core/,$(core_c_filenames))) \
		$(patsubst %.S,%.o,$(addprefix $(build_dir)/core/,$(core_asm_filenames)))

# Add
variant_cpp_filenames = $(notdir $(wildcard $(variant_dir)/*.cpp))
variant_c_filenames = $(notdir $(wildcard $(variant_dir)/*.c))
variant_asm_filenames = $(notdir $(wildcard $(variant_dir)/*.S))
variant_h_filenames = $(notdir $(wildcard) $(variant_dir)/*.h)
variant_obj_files = $(patsubst %.cpp,%.o,$(addprefix $(build_dir)/core/variant/,$(variant_cpp_filenames))) \
		$(patsubst %.c,%.o,$(addprefix $(build_dir)/core/variant/,$(variant_c_filenames))) \
		$(patsubst %.S,%.o,$(addprefix $(build_dir)/core/variant/,$(variant_asm_filenames)))

core_setup_file = $(build_dir)/.copied_core
core_lib = $(build_dir)/core.a

$(core_lib) : $(core_setup_file) $(core_obj_files) $(variant_obj_files)
	$(AR) rcs $(core_lib) $(core_obj_files) $(variant_obj_files)

# Copy core cpp files to build dir (don't overwrite existing; don't force it to be out of date)
# Because we expect the upstream to barely ever change, instead of making this a phony task (or
# go through the trouble of depending on the actual upstream .cpp files) we just `touch(1)` a
# file to mark that this task is done, so it doesn't continually make our build out of date.
$(core_setup_file):
	mkdir -p $(core_build_subdirs)
	cp -n $(variant_dir)/*.h $(build_dir)/core/variant/
	touch $(core_setup_file)

# Copy each file from the core source directory into our working copy within build/.

$(build_dir)/core/%.cpp : $(core_dir)/%.cpp $(core_setup_file) $(core_h_dest_filenames)
	cp -n $< $@

$(build_dir)/core/%.c : $(core_dir)/%.c $(core_setup_file) $(core_h_dest_filenames)
	cp -n $< $@

$(build_dir)/core/%.S : $(core_dir)/%.S $(core_setup_file) $(core_h_dest_filenames)
	cp -n $< $@

$(build_dir)/core/%.h : $(core_dir)/%.h $(core_setup_file)
	cp -n $< $@

# Also copy in variant-specific sources, if any.
$(build_dir)/core/variant/%.cpp : $(variant_dir)/%.cpp $(core_setup_file)
	cp -n $< $@

$(build_dir)/core/variant/%.c : $(variant_dir)/%.c $(core_setup_file)
	cp -n $< $@

$(build_dir)/core/variant/%.S : $(variant_dir)/%.S $(core_setup_file)
	cp -n $< $@

# Don't delete our local copy of the core source.
.PRECIOUS: $(build_dir)/core/%.cpp $(build_dir)/core/%.c $(build_dir)/core/%.S \
	$(build_dir)/core/variant/%.cpp $(build_dir)/core/variant/%.c $(build_dir)/core/variant/%.S \
	$(core_setup_file) $(build_dir)/core/%.h

core: $(core_lib)

src_files = $(filter %,$(foreach dir,$(src_dirs),$(foreach ext,$(src_extensions),$(wildcard $(dir)/*$(ext)))))
obj_files = $(filter %.o,$(foreach ext,$(src_extensions),$(patsubst %$(ext),%.o,$(src_files))))

max_sketch_size := $(strip $(shell grep -e "^$(VARIANT).upload.maximum_size" $(boards_txt) \
	| cut -d '=' -f 2 | tr -s ' '))
user_ram := $(strip $(shell grep -e "^$(VARIANT).upload.maximum_data_size" $(boards_txt) \
	| cut -d '=' -f 2 | tr -s ' '))


size_report_file = $(build_dir)/size_stats.txt
size_summary_file = $(build_dir)/size_summary.txt

# A short bash script that uses the size(1) command to calculate the memory consumption of the
# compiled image:
define SIZE_SCRIPT
DATA=`grep $(size_report_file) -e "^.data" | tr -s " " | cut -d " " -f 2`; \
TEXT=`grep $(size_report_file) -e "^.text" | tr -s " " | cut -d " " -f 2`; \
BSS=`grep $(size_report_file)  -e "^.bss"  | tr -s " " | cut -d " " -f 2`; \
SKETCH_SZ=$$[DATA + TEXT]; \
RAM_USED=$$[DATA + BSS]; \
MAX_SKETCH=$(max_sketch_size); \
if [ -z "$(user_ram)" -o "$(user_ram)" == "0" ]; then \
  MAX_RAM="(unknown)"; \
	RAM_USE_PCT="--"; \
else \
	MAX_RAM=$(user_ram); \
	RAM_USE_PCT=$$[100 * RAM_USED / MAX_RAM]; \
fi; \
SKETCH_PCT=$$[100 * SKETCH_SZ / MAX_SKETCH]; \
echo "Global memory used: $$RAM_USED bytes ($$RAM_USE_PCT%); max is $$MAX_RAM bytes"; \
echo "Sketch size: $$[SKETCH_SZ] bytes ($$SKETCH_PCT%); max is $$MAX_SKETCH bytes"
endef

$(size_report_file): $(TARGET) $(eeprom_file) $(flash_hex_file) $(flash_bin_file)
	$(SIZE) -A $(TARGET) > $(size_report_file)

$(size_summary_file): $(size_report_file)
	@bash -c '$(SIZE_SCRIPT)' > $(size_summary_file)
	@echo ""
	@cat $(size_summary_file)


ifneq ($(origin prog_name), undefined)
# Build the main ELF executable containing user code, Arduino core, any required libraries.
$(TARGET): $(obj_files) $(core_lib)
	$(CXX) $(LDFLAGS) -o $(TARGET) -Wl,--start-group $(obj_files) \
			$(lib_flags) $(core_lib) -lm -Wl,--end-group

else ifneq ($(origin lib_name), undefined)
# Build the main library containing user code.
$(TARGET): $(obj_files)
	mkdir -p $(dir $(TARGET))
	$(AR) rcs $(TARGET) $(obj_files)
endif

$(eeprom_file): $(TARGET)
	$(OBJCOPY) -O ihex -j .eeprom --set-section-flags=.eeprom=alloc,load --no-change-warnings \
			--change-section-lma .eeprom=0 $(TARGET) $(eeprom_file)

$(flash_hex_file): $(TARGET) $(eeprom_file)
	$(OBJCOPY) -O ihex -R .eeprom $(TARGET) $(flash_hex_file)

$(flash_bin_file): $(TARGET) $(eeprom_file)
	$(OBJCOPY) -O binary -R .eeprom $(TARGET) $(flash_bin_file)

eeprom: $(eeprom_file)

flash: $(flash_hex_file) $(flash_bin_file)

ifneq ($(origin prog_name), undefined)

# Main compile/link target for programs. Convert from the ELF executable into files to flash to EEPROM.
image: $(TARGET) $(core_lib) $(eeprom_file) $(flash_hex_file) $(filash_bin_file) $(size_summary_file)

upload: image
	# Force reset of device through port knocking on serial port.
	# TODO(aaron): Only do this for Leonardo and Feather... need to make configurable.
	stty 1200 -F $(UPLOAD_PORT) raw -echo
	@sleep 1
	@echo "Waiting for port to re-appear"
	while true; do ls -l $(UPLOAD_PORT); if [ $$? -eq 0 ]; then break; fi; sleep 1; done
	@echo "Serial port available at $(UPLOAD_PORT)"
	$(FLASH_PRGM) $(UPLOAD_FLASH_ARGS)

verify: image
	# Force reset of device through port knocking on serial port.
	# TODO(aaron): Only do this for Leonardo and Feather ... need to make configurable.
	# (see '1200_bps_touch' option in boards.txt)
	stty 1200 -F $(UPLOAD_PORT) raw -echo
	@sleep 1
	@echo "Waiting for port to re-appear"
	while true; do ls -l $(UPLOAD_PORT); if [ $$? -eq 0 ]; then break; fi; sleep 1; done
	@echo "Serial port available at $(UPLOAD_PORT)"
	$(FLASH_PRGM) $(VERIFY_FLASH_ARGS)

endif

# Main compile/link target for libraries.
ifneq ($(origin lib_name), undefined)
ifeq ($(origin install_dir), undefined)
$(error "You must specify an installation target with `install_dir` to build a library.")
endif # defined(install_dir)

library: $(TARGET)

install: $(TARGET)
	mkdir -p $(install_dir)
	mkdir -p $(include_install_dir)
	mkdir -p $(install_dir)/lib/arch/$(install_arch)/$(build_mcu)/
	cp $(TARGET) $(install_dir)/lib/arch/$(install_arch)/$(build_mcu)/
	cd $(install_headers_root) && rsync -R $(install_headers) $(include_install_dir)

lint:
	arduino-lint

endif

tags:
	$(CTAGS) -R $(CTAGS_OPTS) --exclude=build/* . $(core_dir) $(variant_dir)

TAGS: tags

ifneq ($(origin prog_name), undefined)
all: image
else ifneq ($(origin lib_name), undefined)
all: library
endif

# Rule for compiling c++ source replicated for various equivalent c++ extensions.
%.o : %.cpp
	$(CXX) -x c++ -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@

%.o : %.cxx
	$(CXX) -x c++ -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@

%.o : %.C
	$(CXX) -x c++ -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@

# Arduino-specific C++ file ext.
%.o : %.ino
	$(CXX) -x c++ -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@

# Additional gcc-supported languages.
%.o : %.c
	$(CXX) -x c -c $(CPPFLAGS) $(CFLAGS) $< -o $@

%.o : %.S
	$(CXX) -x assembler-with-cpp -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@


# Rules that help with debugging this makefile

# To print debug info about a macro $(FOO), use `make dbgprint-FOO` 
dbgprint-%:
	@echo "$*" value: "$($*)"
	@echo Defined as "$(value $*)"
	@echo From: "$(origin $*)"
	@false



# coda

.PHONY: all config help clean core install image library eeprom flash upload verify \
		distclean serial tags TAGS

