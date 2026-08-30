#!/usr/bin/env python3
"""Report literal CP/M interface instruction patterns in preserved COM files.

This is a reproducible executable-screening aid, not a disassembler. A byte
match can occur in data, so results are dependency leads unless corroborated by
source, documentation, or execution.
"""
from pathlib import Path
import hashlib
import sys

PATTERNS = {
    "CALL_0005": bytes.fromhex("cd0500"),
    "JP_0005": bytes.fromhex("c30500"),
    "JP_0000": bytes.fromhex("c30000"),
    "CALL_0000": bytes.fromhex("cd0000"),
    "LD_HL_0006": bytes.fromhex("2a0600"),
    "LD_HL_0001": bytes.fromhex("2a0100"),
}

def offsets(data: bytes, needle: bytes):
    found, start = [], 0
    while True:
        pos = data.find(needle, start)
        if pos < 0:
            return found
        found.append(pos + 0x100)  # CP/M COM load origin
        start = pos + 1

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
print("file\tbytes\tsha256\t" + "\t".join(PATTERNS))
for path in sorted(root.glob("*.COM")):
    data = path.read_bytes()
    cols = []
    for needle in PATTERNS.values():
        hits = offsets(data, needle)
        cols.append(",".join(f"{x:04X}" for x in hits) if hits else "-")
    print(f"{path.name}\t{len(data)}\t{hashlib.sha256(data).hexdigest()}\t" + "\t".join(cols))

