INVESTIGATION 028 PROBES

Build source COM files with ./build.sh. Generate the 454-record rejected image
with ./make-bigerr28.sh. Both use deterministic local tools.

Named roles:
  LOAD28    immediate BDOS readiness, entry SP, memory marker
  MEM28     unloaded-memory residue observation
  ENTRY28   page-zero/default-FCB/tail/SP entry capture
  RETURN28  DMA/drive/user/TPA mutation followed by RET
  ERROR28   successful entry marker and source for oversized BIGERR28

Additional MIN28 is the one-byte RET control; CHECK28 observes post-RET state.
run-main028.exp and run-return028.exp supply all input automatically. The final
Ctrl-\ shutdown diagnostic occurs after the last CP/M prompt and is expected.

