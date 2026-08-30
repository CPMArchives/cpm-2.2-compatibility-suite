#!/usr/bin/env python3
"""Create deterministic raw CP/M media of the two controlled definitions."""
import sys
from pathlib import Path

kind, out = sys.argv[1:]
if kind == "ibm-3740":
    source = Path("<cpmsim-root>/disks/drivea.dsk").read_bytes()
    data = bytearray(source)
    # Preserve boot/system tracks, erase the directory and data regions.
    base=2*26*128
    data[base:] = bytes(len(data) - base)
    xlt=[1,7,13,19,25,5,11,17,23,3,9,15,21,2,8,14,20,26,6,12,18,24,4,10,16,22]
    for logical in range(16):
        physical=xlt[logical]-1
        off=base+physical*128
        data[off:off+128]=b"\xe5"*128
elif kind == "z80pack-hd":
    data = bytearray(255*128*128)
    data[:1024*32] = b"\xe5" * (1024*32)
else:
    raise SystemExit("unknown format")
Path(out).write_bytes(data)
