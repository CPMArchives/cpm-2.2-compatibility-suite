#!/bin/zsh
set -e
here=${0:A:h}
make -C "$here/emulator-src/cpmsim/srcsim" -j4
shasum -a 256 "$here/emulator-src/cpmsim/cpmsim"
