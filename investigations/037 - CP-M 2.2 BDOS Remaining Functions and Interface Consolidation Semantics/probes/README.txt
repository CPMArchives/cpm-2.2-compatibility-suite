INVESTIGATION 037 PROBES

BDOS37.ASM/COM
  Purpose: close the Function 40 zero-fill gap.
  Procedure: reuse the accepted I013 random-access matrix but dispatch every
  random write through Function 40; test overwrite, append, record 10, record
  128, record 65535, R2 overflow, and disk full. Read record 9 after writing
  record 10.
  Observation: successful writes returned 00; the newly allocated physical
  block's preceding record 9 read as 128 zero bytes (first byte 00); record 10
  retained S; cross-extent and maximum logical size worked; R2 overflow returned
  06 and disk full returned 02.
  Conclusion: Function 40 is random write with zero fill of a newly allocated
  block, not universal sparse-file hole materialization or write protection.

STATE37.ASM/COM
  Purpose: reconfirm consolidated drive/user/login/RO/DMA state.
  Procedure: select B/user 7, set alternate DMA, and search.
  Observation: B/user 7/login 0003; search used the selected DMA.
  Conclusion: function-specific state contracts remain independent.

REGISTER37.ASM/COM (installed on CP/M as REG37.COM)
  Purpose: reconfirm common result/register limits.
  Procedure: seed registers around Functions 12, 25, 26, and selector 41.
  Observation: A=L and B=H results held; DE changed incidentally; IX/IY happened
  to survive.
  Conclusion: only defined results and restored caller SP are guaranteed.

DMA37.ASM/COM
  Purpose: reconfirm parameter normalization and malformed-FCB behavior.
  Procedure: exercise Function 32 values and Open on an unactivated FCB.
  Observation: user values normalized modulo 32; malformed Open returned FF.
  Conclusion: invalid parameters are function-specific, not a common ABI error.

ERROR37.ASM/COM
  Purpose: reconfirm ordinary logical failure consistency.
  Procedure: Open/Close/Delete/Rename missing names and Make a duplicate while
  snapshotting FCB and DMA.
  Observation: missing operations returned FF, duplicate Make returned 01, DMA
  remained AAh; FCB mutation was function-specific.
  Conclusion: logical failures return ordinary function codes and do not imply
  universal rollback or FCB/DMA preservation beyond their contracts.

Build: ./build.sh
Run:   ./run-all037.sh

The run is deterministic and uses fresh preserved A/B images. BDOS37 intentionally
fills the controlled B image and reaches the emulator's terminal boot-failure state
after recording the disk-full result; the harness expects that endpoint. Full
console output and before/after images are preserved.

