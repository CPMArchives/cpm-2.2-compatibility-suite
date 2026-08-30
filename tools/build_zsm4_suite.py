#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Build every suite utility under CP/M with ZSM4 and DRI LINK."""
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
TOOLS = ROOT / "suite/build-tools"
BOOT = ROOT / "suite/disk-images/z80pack/ibm-3740/drivea.dsk"
DEFAULT_OUT = ROOT / "suite/build"
UTILITY_NAMES = (
    "FILETEST", "RANDTEST", "DIRTEST", "CONSTEST", "BDOSTEST", "ENTRYTST",
    "CCPTEST", "DISKTEST", "BIOSTEST", "ERRTEST", "ECOTEST",
    "CPUTEST", "SCRATCH",
)


def run(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, check=check, text=True, capture_output=True)


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


def locate_system_disk(explicit: Path | None, cpmsim: Path) -> Path:
    candidates = (
        explicit,
        Path(os.environ["Z80PACK_SYSTEM_DISK"])
        if "Z80PACK_SYSTEM_DISK" in os.environ else None,
        cpmsim.parent / "disks/library/cpm22-62khd.dsk",
    )
    for candidate in candidates:
        if candidate and candidate.is_file():
            return candidate
    raise SystemExit(
        "z80pack CP/M 2.2 system disk not found; use --system-disk or "
        "set Z80PACK_SYSTEM_DISK"
    )


def cpm_source(path: Path) -> bytes:
    text = path.read_text(encoding="ascii")
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    return text.replace("\n", "\r\n").encode("ascii") + b"\x1a"


def blank_disk(path: Path) -> None:
    shutil.copy2(BOOT, path)
    run("mkfs.cpm", "-f", "ibm-3740", str(path))


def build_one(name: str, cpmsim: Path, system_disk: Path,
              destination: Path) -> tuple[int, str]:
    with tempfile.TemporaryDirectory(prefix=f"zsm4-{name.lower()}-") as temporary:
        work = Path(temporary)
        disks = work / "disks"
        disks.mkdir()
        shutil.copy2(system_disk, disks / "drivea.dsk")
        for drive in "bcd":
            blank_disk(disks / f"drive{drive}.dsk")

        source = work / f"{name}.MAC"
        source.write_bytes(cpm_source(SOURCES / f"{name}.ASM"))
        run("cpmcp", "-f", "ibm-3740", str(disks / "drivec.dsk"),
            str(source), f"0:{name}.MAC")
        for tool in ("ZSM4.COM", "LINK.COM"):
            run("cpmcp", "-f", "ibm-3740", str(disks / "drived.dsk"),
                str(TOOLS / tool), f"0:{tool}")

        # LINK's [A] option supplies the additional memory FILETEST needs and
        # is harmless for the smaller programs, allowing one uniform recipe.
        expect_program = f'''set timeout 900
spawn {cpmsim} -z -d {disks}
expect "A>"
send -- "B:\\r"
expect "B>"
send -- "D:ZSM4 B:{name}=C:{name}\\r"
expect {{
    -re {{Errors: +0}} {{}}
    -re {{Errors: +[1-9][0-9]*}} {{exit 20}}
    timeout {{exit 21}}
}}
expect "B>"
send -- "D:LINK {name}\\[A\\]\\r"
expect {{
    "CODE SIZE" {{}}
    timeout {{exit 22}}
}}
expect "B>"
send "\\034"
expect eof
'''
        result = run("expect", "-c", expect_program, check=False)
        transcript = result.stdout + result.stderr
        if result.returncode or "Errors: 0" not in transcript or "CODE SIZE" not in transcript:
            raise SystemExit(
                f"CP/M build failed for {name} (expect status {result.returncode})\n"
                f"{transcript}"
            )
        run("cpmcp", "-f", "ibm-3740", str(disks / "driveb.dsk"),
            f"0:{name}.COM", str(destination))
        return destination.stat().st_size, hashlib.sha256(destination.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cpmsim", type=Path)
    parser.add_argument("--system-disk", type=Path)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()
    cpmsim = locate_cpmsim(args.cpmsim)
    system_disk = locate_system_disk(args.system_disk, cpmsim)
    for required in (BOOT, TOOLS / "ZSM4.COM", TOOLS / "LINK.COM"):
        if not required.is_file():
            raise SystemExit(f"missing build input: {required}")

    output = args.output.expanduser().resolve()
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="zsm4-suite-") as temporary:
        staged = Path(temporary)
        rows: list[tuple[str, int, str]] = []
        for name in UTILITY_NAMES:
            size, digest = build_one(name, cpmsim, system_disk,
                                     staged / f"{name}.COM")
            rows.append((name, size, digest))
            print(f"{name}: {size} bytes, zero assembly errors")
        for name, _, _ in rows:
            shutil.copy2(staged / f"{name}.COM", output / f"{name}.COM")

    checksums: list[str] = []
    sizes: list[str] = []
    for name, size, digest in rows:
        binary_name = name + ".COM"
        checksums.append(f"{digest}  {binary_name}")
        source = SOURCES / f"{name}.ASM"
        checksums.append(
            f"{hashlib.sha256(source.read_bytes()).hexdigest()}  ../src/{name}.ASM"
        )
        sizes.append(f"{size:8d} {binary_name}")
    (output / "SHA256SUMS.txt").write_text("\n".join(checksums) + "\n",
                                             encoding="ascii")
    (output / "SIZES.txt").write_text("\n".join(sizes) + "\n",
                                       encoding="ascii")


if __name__ == "__main__":
    main()
