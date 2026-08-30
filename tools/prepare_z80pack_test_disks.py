#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Create a disposable IBM 3740 test layout for z80pack cpmsim."""
from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BOOT = ROOT / "suite/disk-images/z80pack/ibm-3740/drivea.dsk"
BUILD = ROOT / "suite/build"
PAYLOAD = ROOT / "suite/runtime-payload"
UTILITIES = (
    "FILETEST", "RANDTEST", "DIRTEST", "CONSTEST", "BDOSTEST", "ENTRYTST",
    "CCPTEST", "DISKTEST", "BIOSTEST", "ERRTEST", "ECOTEST", "CPUTEST", "SCRATCH",
)


def run(*args: str, check: bool = True) -> None:
    subprocess.run(args, check=check)


def records(count: int, prefix: bytes) -> bytes:
    result = []
    for number in range(count):
        marker = prefix + f"-{number:03d}".encode("ascii") + b" "
        result.append((marker * ((128 + len(marker) - 1) // len(marker)))[:128])
    return b"".join(result)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    # Keep /tmp rather than resolving it to /private/tmp: this cpmtools build
    # cannot open the latter spelling even though macOS maps both paths.
    destination = args.directory.expanduser()
    destination.mkdir(parents=True, exist_ok=True)
    if not BOOT.is_file():
        raise SystemExit(f"missing preserved z80pack boot image: {BOOT}")
    shutil.copy2(BOOT, destination / "drivea.dsk")

    for letter in "bcd":
        disk = destination / f"drive{letter}.dsk"
        shutil.copy2(BOOT, disk)
        for user in range(16):
            run("cpmrm", "-f", "ibm-3740", str(disk), f"{user}:*.*", check=False)

    drive_b = destination / "driveb.dsk"
    drive_c = destination / "drivec.dsk"
    for utility in UTILITIES:
        run("cpmcp", "-f", "ibm-3740", str(drive_b),
            str(BUILD / f"{utility}.COM"), f"0:{utility}.COM")
    run("cpmcp", "-f", "ibm-3740", str(drive_b),
        str(BUILD / "DIRTEST.COM"), "1:DIRTEST.COM")
    run("cpmcp", "-f", "ibm-3740", str(drive_b),
        str(PAYLOAD / "BTUSR.DAT"), "1:BTUSR.DAT")

    # Install the compact primary fixture set. Large/full and cross-drive
    # layouts remain SCRATCH profiles, except C: gets the canonical one-record
    # cross fixture for immediate automated FILETEST/DIRTEST runs.
    for name in ("BTEMPTY.DAT", "BTONE.DAT", "BTMULTI.DAT", "BTPART.DAT",
                 "BTOPEN.DAT", "BTCLOSE.DAT",
                 "BTWILD1.DAT", "BTWILD2.DAT", "BTRO.DAT", "BTDIR01.DAT",
                 "BTDIR02.DAT", "BTUSR.DAT", "CPMTEST.CFG"):
        source = PAYLOAD / name
        run("cpmcp", "-f", "ibm-3740", str(drive_b), str(source), f"0:{name}")
    # BDOSTEST Search Next/restart cards need two matching directory entries;
    # their contents are immaterial, so the empty fixture conserves IBM media.
    for name in ("BDSA.TMP", "BDSB.TMP"):
        run("cpmcp", "-f", "ibm-3740", str(drive_b),
            str(PAYLOAD / "BTEMPTY.DAT"), f"0:{name}")
    run("cpmchmod", "-f", "ibm-3740", str(drive_b), "0444", "0:BTRO.DAT")
    cross = destination / "BTBFILE.DAT"
    cross.write_bytes(records(1, b"BFILE"))
    run("cpmcp", "-f", "ibm-3740", str(drive_c), str(cross), "0:BTBFILE.DAT")
    cross.unlink()
    print(f"prepared disposable z80pack disks in {destination}")


if __name__ == "__main__":
    main()
