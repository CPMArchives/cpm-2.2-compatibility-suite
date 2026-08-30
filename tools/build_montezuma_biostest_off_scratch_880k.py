#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Build the blank 880K BIOSTEST fixture used with a nonzero-OFF DPB."""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

from build_blank_montezuma_880k import build, extract_raw, verify


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUT = ROOT / "suite/disk-images/trs80-montezuma/BIOSTEST OFF Scratch.dmk"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", nargs="?", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()
    output = args.output.expanduser().resolve()

    image = build()
    verify(image)
    raw = extract_raw(image)
    if any(byte != 0xE5 for byte in raw):
        raise SystemExit("scratch image is not logically blank")

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(image)
    digest = hashlib.sha256(image).hexdigest()
    (output.parent / "BIOSTEST-OFF-Scratch-SHA256.txt").write_text(
        f"{digest}  {output.name}\n", encoding="ascii"
    )
    print(f"created: {output}")
    print(f"sha256:  {digest}")
    print("logical contents: blank (all E5h)")


if __name__ == "__main__":
    main()
