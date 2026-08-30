INVESTIGATION 026 PROBES

Build with ./build.sh. It uses z80asm and mechanically
inserts COMMON26.INC into sources that share printing routines. The accepted
binaries, generated listings, and byte-identical rebuilds are preserved.

Programs:
  STATE26.COM    drive, user, DMA persistence, login/read-only, version
  DPB26.COM      current-drive ALV/DPB pointers and selectors 39/41
  RESET26.COM    Function 37 vector-reset behavior
  PROTECT26.COM  Functions 28 and 40 distinction (installed as PROTEC26.COM)
  TERMSTATE26.COM state mutation and RET/F0/JMP termination (TERM26.COM)
  CHECK26.COM    post-termination observer

run-main026.exp and run-term026.exp provide deterministic console input. No
manually typed input or timing-sensitive response is required. cases/ contains
fresh per-scenario disk images. images-before/ contains the pre-fixture base.

The Ctrl-\ harness exit produces cpmsim's expected "can't read console" and
"User Interrupt" shutdown text after the final CP/M prompt; it is not a CP/M
probe failure.

