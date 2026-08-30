#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
# Build, archive, refresh, and verify the complete maintained suite.
set -eu

suite=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo=$(CDPATH= cd -- "$suite/.." && pwd)
if [ "$#" -ne 0 ]; then
    echo "Usage: $0" >&2
    exit 2
fi

runtime="$suite/disk-images/trs80-montezuma/Conformance Suite.dmk"
source_image="$suite/disk-images/trs80-montezuma/Conformance Suite Source.dmk"
off_scratch="$suite/disk-images/trs80-montezuma/BIOSTEST OFF Scratch.dmk"

"$suite/build.sh"
python3 "$repo/tools/build_crunched_sources.py"
python3 "$repo/tools/build_montezuma_runtime_880k.py" "$runtime"
python3 "$repo/tools/build_montezuma_source_880k.py" "$source_image"
python3 "$repo/tools/build_montezuma_biostest_off_scratch_880k.py" "$off_scratch"

(
    cd "$suite/build"
    shasum -a 256 -c SHA256SUMS.txt
)

echo "Release artifacts refreshed and verified in: $repo"
shasum -a 256 "$runtime" "$source_image" "$off_scratch"
