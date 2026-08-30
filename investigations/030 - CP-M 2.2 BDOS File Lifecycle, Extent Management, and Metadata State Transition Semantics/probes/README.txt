Investigation 030 lifecycle probes

The seven named ASM programs are reproducible lifecycle views over two
previously validated comprehensive bodies. CREATE30, GROW30, EXTENT30,
CLOSE30, OPEN30, and FAIL30 include WRITE011.INC. FCB30 includes
RAND013.INC. This intentional reuse avoids changing the already-audited
operation-level probes while rerunning their controlled fixtures for I030.

Purpose, procedure, observation, and compatibility conclusion for each named
view appear in observed-output.txt and the report. Full fresh transcripts are
in transcripts/. Disk images before and after the accepted runs are preserved.

Build with ./build.sh. z80asm treats undecorated numeric literals as decimal.
The wrappers build byte-identically to their included comprehensive body.
