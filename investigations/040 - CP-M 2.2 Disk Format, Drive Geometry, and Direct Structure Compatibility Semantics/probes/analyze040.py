#!/usr/bin/env python3
"""Deterministic CP/M 2.2 raw-directory and allocation cross-check."""
import argparse, hashlib, json
from pathlib import Path

FORMATS = {
    "ibm-3740": dict(seclen=128, tracks=77, spt=26, block=1024,
                     maxdir=64, boottrk=2, dsm=242, drm=63,
                     al0=0xC0, al1=0x00,
                     xlt=[1,7,13,19,25,5,11,17,23,3,9,15,21,2,8,14,20,26,6,12,18,24,4,10,16,22]),
    "z80pack-hd": dict(seclen=128, tracks=255, spt=128, block=2048,
                       maxdir=1024, boottrk=0, dsm=2039, drm=1023,
                       al0=0xFF, al1=0xFF, xlt=None),
}

def sha(data): return hashlib.sha256(data).hexdigest()

def entries(data, f):
    start = f["boottrk"] * f["spt"] * f["seclen"]
    count = (f["maxdir"] * 32) // f["seclen"]
    sectors=[]
    for logical in range(count):
        track=logical//f["spt"]; index=logical%f["spt"]
        physical=(f["xlt"][index]-1) if f["xlt"] else index
        off=start+(track*f["spt"]+physical)*f["seclen"]
        sectors.append(data[off:off+f["seclen"]])
    raw=b"".join(sectors)
    out = []
    for slot in range(f["maxdir"]):
        e = raw[slot*32:(slot+1)*32]
        if len(e) < 32 or e[0] == 0xE5 or e[0] > 0x0F: continue
        name = bytes(x & 0x7f for x in e[1:9]).decode("ascii", "replace").rstrip()
        ext = bytes(x & 0x7f for x in e[9:12]).decode("ascii", "replace").rstrip()
        if f["dsm"] < 256:
            blocks = [x for x in e[16:32] if x]
        else:
            blocks = [int.from_bytes(e[x:x+2], "little") for x in range(16,32,2)]
            blocks = [x for x in blocks if x]
        out.append(dict(slot=slot, user=e[0], file=name+("."+ext if ext else ""),
                        ex=e[12], s1=e[13], s2=e[14], rc=e[15], blocks=blocks))
    return start, raw, out

def inspect(path, fmt):
    data = Path(path).read_bytes(); f = FORMATS[fmt]
    start, raw, es = entries(data, f)
    owners = {}; invalid=[]
    for e in es:
        for b in e["blocks"]:
            if b > f["dsm"]: invalid.append([e["slot"], b])
            owners.setdefault(b, []).append(e["slot"])
    duplicates = {str(b): s for b,s in owners.items() if len(set(s)) > 1}
    reserved = sum(bin(x).count("1") for x in (f["al0"],f["al1"]))
    used = len(owners)
    return dict(image=str(path), format=fmt, sha256=sha(data), bytes=len(data),
                expected_bytes=f["tracks"]*f["spt"]*f["seclen"],
                directory_offset=start, directory_bytes=len(raw),
                active_entries=len(es), reserved_directory_blocks=reserved,
                used_data_blocks=used, free_data_blocks=(f["dsm"]+1-reserved-used),
                duplicate_blocks=duplicates, out_of_range_blocks=invalid,
                entries=es)

def damage(src, dst, fmt):
    data=bytearray(Path(src).read_bytes()); f=FORMATS[fmt]
    start, raw, es=entries(data,f)
    candidates=[e for e in es if e["blocks"]]
    if len(candidates)<2: raise SystemExit("need two allocated entries")
    block=candidates[0]["blocks"][0]; slot=candidates[1]["slot"]
    logical_byte=slot*32+16
    logical_sector=logical_byte//f["seclen"]
    within=logical_byte%f["seclen"]
    track=logical_sector//f["spt"]; index=logical_sector%f["spt"]
    physical=(f["xlt"][index]-1) if f["xlt"] else index
    off=start+(track*f["spt"]+physical)*f["seclen"]+within
    if f["dsm"]<256: data[off]=block
    else: data[off:off+2]=block.to_bytes(2,"little")
    Path(dst).write_bytes(data)
    print(f"duplicated block {block} into directory slot {slot}")

ap=argparse.ArgumentParser(); sub=ap.add_subparsers(dest="cmd",required=True)
i=sub.add_parser("inspect"); i.add_argument("format",choices=FORMATS); i.add_argument("images",nargs="+")
d=sub.add_parser("damage"); d.add_argument("format",choices=FORMATS); d.add_argument("src"); d.add_argument("dst")
a=ap.parse_args()
if a.cmd=="damage": damage(a.src,a.dst,a.format)
else:
    for p in a.images: print(json.dumps(inspect(p,a.format),sort_keys=True))
