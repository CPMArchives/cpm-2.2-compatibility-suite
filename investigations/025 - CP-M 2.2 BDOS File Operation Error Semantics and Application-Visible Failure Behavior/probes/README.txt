Investigation 025 logical file-error probes
============================================

FILEERR25 tests missing Open/Close/Delete/Rename and duplicate Make. Because
CP/M executable names are limited to eight characters, it is installed as
FERR25.COM while the required source/binary artifact retains FILEERR25.
OPEN25 tests missing, wrong-user, wildcard, unavailable-drive, and invalid-drive
Open. READ25 tests sequential EOF/unactivated use and random failure classes.
SEARCH25 tests no-match/exhaustion and DMA aftermath. WRITE25 distinguishes
directory-full Make from allocation-full Write. FCB25 corrupts an activated FCB
identity before Close. DISK25 attempts Delete after Function 28 write protection.

Build with `./build.sh`. rebuild/ contains an independent build and
rebuild.sha256 verifies byte identity.

run-returning025.exp automates normally returning calls. run-fatal025.exp waits
for the expected DRI diagnostic and supplies Control-C deterministically. The
final emulator I/O diagnostic follows the harness interrupt at the last prompt
and is not guest evidence.

images-fixture is the normal common before-image. images-dirfull-before has all
64 directory entries occupied while retaining 178K free. images-allocfull-before
has 0K free while retaining directory capacity. cases/* preserve accepted
post-run images. Physical-error injection is intentionally excluded; I015
already establishes that operator-error path.

