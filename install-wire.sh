#!/usr/bin/env bash
#
# (c) Copyright 2022 Aaron Kimball
#
# Build and install the Wire library for your specific Arduino.
#
# You must configure BOARD=your:fqbn:here in ~/.arduino_mk.conf
# or have an Arduino device connected to this computer which can
# be auto-detected by arduino-cli.

bindir=`dirname "$0"`
bindir=`cd ${bindir} && pwd`

cd "$bindir"

echo "Determining Arduino architecture..."
arch=`prog_name=x make -f arduino.mk config | grep -e '^install_arch' | cut -d ':' -f 2 | tr -d '[:blank:]'`

if [ -z "$arch" ]; then
  echo 'Could not determine Arduino architecture!'
  echo "You must set BOARD=your:fqbn:here in $HOME/.arduino_mk.conf and try again."
  echo "A starter config file is available at:"
  echo "  ${bindir}/arduino_mk_conf.template"

  exit 1
fi

if [ ! -d "wire/${arch}" ]; then
  echo "Wire library not available for architecture: ${arch}"
  exit 1
fi

echo "Building Wire for architecture: ${arch}"

make -C "wire/${arch}" install

