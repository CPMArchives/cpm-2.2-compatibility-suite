Investigation 046 probes
========================

GAP46.ASM/COM validates selected unresolved boundaries: two default FCB
prefixes, the counted command tail, undocumented Function 37 state effects,
reserved Functions 38/39, and unsupported selector 41. It restores disk state
and DMA before returning.

CROSS45.ASM/COM is the preserved Investigation 045 cross-layer validation
probe. Running it immediately after GAP46 verifies that the closure probe left
a coherent public environment.

audit-ledger046.sh mechanically counts entries/dispositions, lists duplicate
numbers, checks the 0001-0622 sequence, and enumerates POLICY PENDING entries.
Its accepted output is ledger-audit-output.txt.

build.sh rebuilds GAP46. run046.exp supplies the two operands and all commands
without manually typed input. The terminal warning after the final harness
interrupt is host emulator shutdown noise, not CP/M behavior.

The ready disk images were captured after probe installation. Before/after
images, transcript, listing, hashes, and rebuild verification are preserved.
