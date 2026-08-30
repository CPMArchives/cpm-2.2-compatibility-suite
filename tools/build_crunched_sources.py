#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Regenerate CP/M CRUNCH 2.x source payloads for the source disk."""
from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "suite/src"
OUT = ROOT / "suite/crunched-source"
BOOT = ROOT / "suite/disk-images/z80pack/ibm-3740/drivea.dsk"
UTILITY_NAMES = (
    "FILETEST", "RANDTEST", "DIRTEST", "CONSTEST", "BDOSTEST", "ENTRYTST",
    "CCPTEST", "DISKTEST", "BIOSTEST", "ERRTEST", "ECOTEST",
    "CPUTEST", "SCRATCH",
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def zsm4_source(path: Path) -> bytes:
    text = path.read_text(encoding="ascii")
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    return text.replace("\n", "\r\n").encode("ascii") + b"\x1a"


def run(*args: str, check: bool = True) -> None:
    subprocess.run(args, check=check)


def locate_cpmsim(explicit: Path | None) -> Path:
    candidates = (
        explicit,
        Path(os.environ["CPMSIM"]) if "CPMSIM" in os.environ else None,
        Path.home() / "z80pack/cpmsim/cpmsim",
    )
    for candidate in candidates:
        if candidate and candidate.is_file():
            return candidate
    raise SystemExit("cpmsim not found; use --cpmsim or set CPMSIM")


def locate_hd_template(explicit: Path | None, cpmsim: Path) -> Path:
    candidates = (
        explicit,
        Path(os.environ["Z80PACK_HD_TEMPLATE"])
        if "Z80PACK_HD_TEMPLATE" in os.environ else None,
        cpmsim.parent / "disks/library/hd-tools.dsk",
    )
    for candidate in candidates:
        if candidate and candidate.is_file():
            return candidate
    raise SystemExit(
        "z80pack 4MB hard-disk template not found; use --hd-template or "
        "set Z80PACK_HD_TEMPLATE"
    )


def locate_crunch(explicit: Path | None) -> Path:
    candidates = (
        explicit,
        Path(os.environ["CRUNCH_COM"]) if "CRUNCH_COM" in os.environ else None,
        ROOT / "suite/build-tools/CRUNCH.COM",
    )
    for candidate in candidates:
        if candidate and candidate.is_file():
            return candidate
    raise SystemExit(
        "CRUNCH.COM not found; restore suite/build-tools/CRUNCH.COM, use "
        "--crunch, or set CRUNCH_COM."
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cpmsim", type=Path)
    parser.add_argument("--hd-template", type=Path)
    parser.add_argument("--crunch", type=Path)
    parser.add_argument("--output", type=Path, default=OUT)
    args = parser.parse_args()

    cpmsim = locate_cpmsim(args.cpmsim)
    template = locate_hd_template(args.hd_template, cpmsim)
    crunch = locate_crunch(args.crunch)
    if not BOOT.is_file():
        raise SystemExit(f"missing z80pack boot image: {BOOT}")

    with tempfile.TemporaryDirectory(prefix="cpm-crunch-") as temporary:
        work = Path(temporary)
        disks = work / "disks"
        source_dir = work / "source"
        output_dir = work / "output"
        disks.mkdir()
        source_dir.mkdir()
        output_dir.mkdir()
        shutil.copy2(BOOT, disks / "drivea.dsk")
        shutil.copy2(template, disks / "drivei.dsk")
        for user in range(16):
            run("cpmrm", "-f", "z80pack-hd", str(disks / "drivei.dsk"),
                f"{user}:*.*", check=False)

        mac_data: dict[str, bytes] = {}
        for name in UTILITY_NAMES:
            data = zsm4_source(SOURCES / f"{name}.ASM")
            mac_data[name] = data
            (source_dir / f"{name}.MAC").write_bytes(data)
        run("cpmcp", "-f", "z80pack-hd", str(disks / "drivei.dsk"),
            str(crunch), "0:CRUNCH.COM")
        for name in UTILITY_NAMES:
            run("cpmcp", "-f", "z80pack-hd", str(disks / "drivei.dsk"),
                str(source_dir / f"{name}.MAC"), f"0:{name}.MAC")

        commands = " ".join(f'"CRUNCH {name}.MAC /Q"' for name in UTILITY_NAMES)
        expect_program = f'''set timeout 180
spawn {cpmsim} -z -d {disks}
expect "A>"
send -- "I:\\r"
expect "I>"
foreach cmd {{{commands}}} {{
    send -- "$cmd\\r"
    expect "I>"
}}
send "\\034"
expect eof
'''
        run("expect", "-c", expect_program)

        records = []
        for name in UTILITY_NAMES:
            target = output_dir / f"{name}.MZC"
            run("cpmcp", "-f", "z80pack-hd", str(disks / "drivei.dsk"),
                f"0:{name}.MZC", str(target))
            compressed = target.read_bytes()
            records.append((name, mac_data[name], compressed))

        destination = args.output.expanduser().resolve()
        destination.mkdir(parents=True, exist_ok=True)
        for old in destination.glob("*.MZC"):
            old.unlink()
        for name, _, compressed in records:
            (destination / f"{name}.MZC").write_bytes(compressed)
        lines = ["utility\tmac_size\tmac_sha256\tmzc_size\tmzc_sha256"]
        for name, mac, compressed in records:
            lines.append(
                f"{name}\t{len(mac)}\t{sha256(mac)}\t"
                f"{len(compressed)}\t{sha256(compressed)}"
            )
        (destination / "MANIFEST.tsv").write_text(
            "\n".join(lines) + "\n", encoding="ascii"
        )
        print(f"generated {len(records)} crunched sources in {destination}")
        print(f"uncompressed: {sum(len(row[1]) for row in records)} bytes")
        print(f"crunched:     {sum(len(row[2]) for row in records)} bytes")


if __name__ == "__main__":
    main()
