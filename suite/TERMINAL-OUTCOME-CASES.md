# Terminal-outcome RANDTEST cases

Ledgers 0368 and 0369 exercise sequential and random writes against the
controlled `BTRO.DAT` fixture. DRI CP/M 2.2 does not return a normal status to
RANDTEST. It emits `Bdos Err On B: File R/O`, waits for acknowledgement, and
returns through the warm-boot path to the CCP.

The executable therefore emits the ordinary report and case preamble and then
makes the protected call. It does not print an in-process PASS. The external
provider must establish all of the following before assigning PASS:

1. the selected numeric or frozen case-ID command reached the expected
   `File R/O` terminal outcome;
2. acknowledgement recovered to the CCP rather than hanging or corrupting the
   environment;
3. the complete fixture disk is byte-identical before and after the attempt;
4. the protected `BTRO.DAT` fixture remains present and read-only.

Absence of an external provider yields BLOCKED. A normal return, successful
write, altered fixture, missing recovery, or different unaccepted terminal
outcome cannot be reported as PASS. This protocol refines suite execution; it
does not change frozen ledger propositions, case IDs, or oracle versions.
