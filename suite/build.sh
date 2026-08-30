#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
python3 "$root/../tools/build_zsm4_suite.py" --output "$root/build"
python3 "$root/../tools/archive_utility_versions.py"
