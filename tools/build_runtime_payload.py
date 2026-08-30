#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Generate the canonical marked-record fixtures used by the suite."""
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PAYLOAD = ROOT / "suite/runtime-payload"


def records(count: int, prefix: str) -> bytes:
    result = []
    for number in range(count):
        marker = f"{prefix}-{number:03d} ".encode("ascii")
        result.append((marker * ((128 + len(marker) - 1) // len(marker)))[:128])
    return b"".join(result)


FIXTURES = {
    "BTEMPTY.DAT": (0, "EMPTY"),
    "BTONE.DAT": (1, "ONE"),
    "BTMULTI.DAT": (3, "MULTI"),
    "BTPART.DAT": (2, "PART"),
    "BTBND128.DAT": (128, "BOUND"),
    "BTBIG130.DAT": (130, "BIG"),
    "BTOPEN.DAT": (1, "OPEN"),
    "BTCLOSE.DAT": (1, "CLOSE"),
    "BTWILD1.DAT": (1, "WILD1"),
    "BTWILD2.DAT": (1, "WILD2"),
    "BTRO.DAT": (1, "READONLY"),
    "BTDIR01.DAT": (1, "DIR01"),
    "BTDIR02.DAT": (1, "DIR02"),
    "BTUSR.DAT": (1, "USER"),
}


def main() -> None:
    PAYLOAD.mkdir(parents=True, exist_ok=True)
    for name, (count, prefix) in FIXTURES.items():
        data = records(count, prefix)
        (PAYLOAD / name).write_bytes(data)
        print(f"{name}: {len(data)} bytes")


if __name__ == "__main__":
    main()
