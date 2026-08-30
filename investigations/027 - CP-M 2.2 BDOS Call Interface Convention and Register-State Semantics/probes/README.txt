INVESTIGATION 027 PROBES

Build with ./build.sh using z80asm. The script
mechanically expands COMMON27.INC for sources using shared output routines.

CALL27  - full main/alternate register records for representative calls
REG27   - main register sentinel diagnostics
FUNC27  - value, reserved, and out-of-range selectors
STACK27 - 64 calls on a guarded controlled stack
PARAM27 - user normalization and malformed-FCB case

run027.exp provides every command deterministically. cases/accepted contains a
fresh fixture copy; images-before contains the base images. The harness's final
Ctrl-\ causes the expected cpmsim console-read shutdown diagnostic after the
last A> prompt.

