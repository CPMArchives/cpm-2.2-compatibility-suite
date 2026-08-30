Investigation 063 probe reproduction

Requirements:
- z80asm 2.1
- cpmsim 1.39
- cpmtools with ibm-3740 disk definition
- expect

Run ./build.sh to rebuild CPU8080.COM, CPUZ80.COM, UNDOC63.COM and
TIMING63.COM. CPU8080 is assembled in 8080 mode. Run ./run-tests.sh to copy
fresh z80pack CP/M disks, insert the four probes, and execute the controlled
matrix. No keyboard input is required.

CPU8080 tests the common documented 8080 subset and selected defined flags.
CPUZ80 tests documented Z80 extensions. UNDOC63 isolates CB 30h; it is run
with undocumented execution enabled and with the trap option. TIMING63 is a
semantic control at two configured clock rates.

The console-termination lines after each successful command are emulator
shutdown diagnostics caused by the scripted Control-\ character, not CP/M
behavior. The 8080 CPUZ80 stop and undocumented-opcode trap occur before that
scripted shutdown and are the relevant boundary observations.
