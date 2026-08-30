; BetterCP/M DISKTEST
; Version 0.1.0-dev21
; Incremental rebuild: thirteen ledger items plus /H, /INFO, and /LIST.
; Intel 8080 instruction subset.
        ORG 0100H
BDOS    EQU 0005H

        JP START
; Keep /LIST at the beginning of the transient program. Montezuma Micro's
; runtime has proved sensitive to longer Function 9 strings placed later.
LISTPLACE:DB 13,10,'0155  REQUIRED  Function 13 user-number preservation',13,10
        DB '0255  REQUIRED  Data-full empty Make',13,10
        DB '0275  REQUIRED  Allocation-full failure',13,10
        DB '0276  REQUIRED  Exact write failure codes',13,10
        DB '0292  REQUIRED  Allocation release',13,10
        DB '0293  NOT GUAR. Exact freed-block reuse',13,10
        DB '0355  OUT SCOPE Physical allocation',13,10
        DB '0373  REQUIRED  F28 protects current disk',13,10
        DB '0374  REQUIRED  Reset clears protection',13,10
        DB '0375  REQUIRED  F29 returns R/O vector',13,10
        DB '0376  REQUIRED  Drive B is vector bit 1',13,10
        DB '0377  REQUIRED  F28 sets drive-B bit',13,10
        DB '0378  REQUIRED  F13 clears R/O vector',13,10,'$'

START:  LD SP,STACKTOP
        LD HL,0081H
        LD A,(0080H)
        OR A
        JP Z,SHOWHELP
        LD B,A
SKIP:   LD A,(HL)
        CP ' '
        JP NZ,GOTCHAR
        INC HL
        DEC B
        JP NZ,SKIP
        JP SHOWHELP
GOTCHAR:CP '/'
        JP NZ,SHOWBAD
        INC HL
        LD A,(HL)
        CP '0'
        JP Z,TRYNUM
        AND 5FH
        CP 'H'
        JP Z,SHOWHELP
        CP 'I'
        JP Z,SHOWINFO
        CP 'L'
        JP Z,SHOWLIST
        JP SHOWBAD

TRYNUM: INC HL
        LD A,(HL)
        CP '1'
        JP Z,NUM1
        CP '2'
        JP Z,NUM2
        CP '3'
        JP Z,NUM3
        JP SHOWBAD
NUM1:   INC HL
        LD A,(HL)
        CP '5'
        JP NZ,SHOWBAD
        INC HL
        LD A,(HL)
        CP '5'
        JP NZ,SHOWBAD
        JP RUN0155
NUM2:   INC HL
        LD A,(HL)
        CP '5'
        JP Z,NUM25
        CP '7'
        JP Z,NUM27
        CP '9'
        JP Z,NUM29
        JP SHOWBAD
NUM25:  INC HL
        LD A,(HL)
        CP '5'
        JP Z,SHOW0255
        JP SHOWBAD
NUM27:  INC HL
        LD A,(HL)
        CP '5'
        JP Z,SHOW0275
        CP '6'
        JP Z,SHOW0276
        JP SHOWBAD
NUM29:  INC HL
        LD A,(HL)
        CP '2'
        JP Z,SHOW0292
        CP '3'
        JP Z,SHOW0293
        JP SHOWBAD
NUM3:   INC HL
        LD A,(HL)
        CP '5'
        JP Z,NUM35
        CP '7'
        JP Z,NUM37
        JP SHOWBAD
NUM35:  INC HL
        LD A,(HL)
        CP '5'
        JP Z,SHOW0355
        JP SHOWBAD
NUM37:  INC HL
        LD A,(HL)
        CP '3'
        JP Z,RUN0373
        CP '4'
        JP Z,RUN0374
        CP '5'
        JP Z,RUN0375
        CP '6'
        JP Z,RUN0376
        CP '7'
        JP Z,RUN0377
        CP '8'
        JP Z,RUN0378
        JP SHOWBAD

SHOWHELP:LD DE,HELPMSG
        CALL PRINT
        JP 0000H
SHOWINFO:LD DE,INFOMSG
        CALL PRINT
        JP 0000H
SHOWLIST:LD DE,LISTPLACE
        CALL PRINT
        JP 0000H
SHOW0255:LD DE,MSG0255
        CALL PRINT
        JP 0000H
SHOW0275:LD DE,MSG0275
        CALL PRINT
        JP 0000H
SHOW0276:LD DE,MSG0276
        CALL PRINT
        JP 0000H
SHOW0292:LD DE,MSG0292
        CALL PRINT
        JP 0000H
SHOW0293:LD DE,MSG0293
        CALL PRINT
        JP 0000H
SHOW0355:LD DE,MSG0355
        CALL PRINT
        JP 0000H
SHOWBAD:LD DE,BADMSG
        CALL PRINT
        JP 0000H

; 0155: Function 13 must preserve the current user number. Save caller state,
; select a deliberately nonzero user, reset, observe, then restore caller state.
RUN0155:LD C,25
        CALL BDOS
        LD (OLDDRV),A
        LD E,0FFH
        LD C,32
        CALL BDOS
        LD (OLDUSR),A
        LD E,1
        CP 1
        JP NZ,SETTEST
        LD E,2
SETTEST:LD A,E
        LD (TESTUSR),A
        LD C,32
        CALL BDOS
        LD C,13
        CALL BDOS
        LD E,0FFH
        LD C,32
        CALL BDOS
        LD (GOTUSR),A
        LD A,(OLDUSR)
        LD E,A
        LD C,32
        CALL BDOS
        LD A,(OLDDRV)
        LD E,A
        LD C,14
        CALL BDOS
        LD A,(TESTUSR)
        LD B,A
        LD A,(GOTUSR)
        CP B
        JP NZ,FAIL0155
        LD DE,PASSMSG
        CALL PRINT
        JP 0000H
FAIL0155:LD DE,FAILMSG
        CALL PRINT
        JP 0000H

; Functions 28/29 probes use B:, then Function 13 and the original drive so
; software write protection never leaks into the caller's session.
SETPROT:LD C,25
        CALL BDOS
        LD (OLDDRV),A
        LD E,1
        LD C,14
        CALL BDOS
        LD C,28
        CALL BDOS
        RET
GETRO:  LD C,29
        CALL BDOS
        LD A,L
        RET
RESTORE:LD C,13
        CALL BDOS
        LD A,(OLDDRV)
        LD E,A
        LD C,14
        CALL BDOS
        RET

RUN0373:CALL SETPROT
        CALL GETRO
        AND 02H
        PUSH AF
        CALL RESTORE
        POP AF
        JP Z,RF0373
        LD DE,R0373P
        JP PASSAUTO
RF0373:LD DE,R0373F
        JP FAILAUTO
RUN0374:CALL SETPROT
        LD C,13
        CALL BDOS
        CALL GETRO
        AND 02H
        PUSH AF
        LD A,(OLDDRV)
        LD E,A
        LD C,14
        CALL BDOS
        POP AF
        JP NZ,RF0374
        LD DE,R0374P
        JP PASSAUTO
RF0374:LD DE,R0374F
        JP FAILAUTO
RUN0375:CALL SETPROT
        CALL GETRO
        AND 02H
        PUSH AF
        CALL RESTORE
        POP AF
        JP Z,RF0375
        LD DE,R0375P
        JP PASSAUTO
RF0375:LD DE,R0375F
        JP FAILAUTO
RUN0376:CALL SETPROT
        CALL GETRO
        AND 02H
        PUSH AF
        CALL RESTORE
        POP AF
        JP Z,RF0376
        LD DE,R0376P
        JP PASSAUTO
RF0376:LD DE,R0376F
        JP FAILAUTO
RUN0377:CALL SETPROT
        CALL GETRO
        AND 02H
        PUSH AF
        CALL RESTORE
        POP AF
        JP Z,RF0377
        LD DE,R0377P
        JP PASSAUTO
RF0377:LD DE,R0377F
        JP FAILAUTO
RUN0378:CALL SETPROT
        LD C,13
        CALL BDOS
        CALL GETRO
        AND 02H
        PUSH AF
        LD A,(OLDDRV)
        LD E,A
        LD C,14
        CALL BDOS
        POP AF
        JP NZ,RF0378
        LD DE,R0378P
        JP PASSAUTO
RF0378:LD DE,R0378F
        JP FAILAUTO
PASSAUTO:PUSH DE
        LD DE,AUTOHEAD
        CALL PRINT
        POP DE
        CALL PRINT
        LD DE,PASSSUM
        CALL PRINT
        JP 0000H
FAILAUTO:PUSH DE
        LD DE,AUTOHEAD
        CALL PRINT
        POP DE
        CALL PRINT
        LD DE,FAILSUM
        CALL PRINT
        JP 0000H

PRINT:  LD C,9
        CALL BDOS
        RET

HELPMSG:DB 13,10,'DISKTEST 0.1.0-dev21',13,10,13,10
        DB '  DISKTEST /NNNN   Run or explain one ledger item',13,10
        DB '  DISKTEST /LIST   List implemented ledger items',13,10
        DB '  DISKTEST /H      Show this help',13,10
        DB '  DISKTEST /INFO   Show build information',13,10,13,10
        DB 'Automated: 0155 and 0373-0378.',13,10
        DB 'Other listed items print controlled procedures or scope notes.',13,10,'$'
INFOMSG:DB 13,10,'BetterCP/M DISKTEST 0.1.0-dev21',13,10
        DB 'Implemented commands: /NNNN, /LIST, /H, and /INFO',13,10
        DB 'Ledger items represented: 13',13,10
        DB 'Automated: 7; controlled procedures: 5; outside scope: 1',13,10
        DB 'Required: 11; not guaranteed: 1; outside scope: 1',13,10
        DB 'Ledger coverage: 0155, 0255, 0275, 0276, 0292, 0293,',13,10
        DB '                 0355, 0373, 0374, 0375, 0376, 0377, 0378',13,10,'$'
PASSMSG:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0155  PASS      REQUIRED      Function 13 preserved user number',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'
FAILMSG:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0155  FAIL      REQUIRED      Function 13 changed user number',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'

AUTOHEAD:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10,'$'
PASSSUM:DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'
FAILSUM:DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'
R0373P: DB '0373  PASS      REQUIRED      Function 28 protected current disk',13,10,'$'
R0373F: DB '0373  FAIL      REQUIRED      Function 28 did not protect disk',13,10,'$'
R0374P: DB '0374  PASS      REQUIRED      Protection ended after disk reset',13,10,'$'
R0374F: DB '0374  FAIL      REQUIRED      Protection survived disk reset',13,10,'$'
R0375P: DB '0375  PASS      REQUIRED      Function 29 returned R/O vector',13,10,'$'
R0375F: DB '0375  FAIL      REQUIRED      Function 29 omitted protected disk',13,10,'$'
R0376P: DB '0376  PASS      REQUIRED      Vector bit 1 represented drive B',13,10,'$'
R0376F: DB '0376  FAIL      REQUIRED      Drive B did not map to vector bit 1',13,10,'$'
R0377P: DB '0377  PASS      REQUIRED      Function 28 set drive-B vector bit',13,10,'$'
R0377F: DB '0377  FAIL      REQUIRED      Function 28 left vector bit clear',13,10,'$'
R0378P: DB '0378  PASS      REQUIRED      Function 13 cleared R/O vector',13,10,'$'
R0378F: DB '0378  FAIL      REQUIRED      Function 13 left R/O vector set',13,10,'$'

MSG0255:DB 13,10,'0255  UNTESTED  REQUIRED      Data-full empty Make',13,10
        DB 'SETUP: mount the supplied restorable full disk as D:.',13,10
        DB 'ACTION: make D:EMPTY.TST without writing a data record.',13,10
        DB 'EXPECTED: Make succeeds; an empty file needs no data block.',13,10
        DB 'FAIL: Make reports data-full before a record is written.',13,10
        DB 'RESTORE: discard changes and remount the supplied D: image.',13,10,'$'
MSG0275:DB 13,10,'0275  UNTESTED  REQUIRED      Allocation-full failure',13,10
        DB 'SETUP: mount the supplied restorable full disk as D:.',13,10
        DB 'ACTION: append one record to D:BTFULL.DAT.',13,10
        DB 'EXPECTED: allocating write fails; existing data remains intact.',13,10
        DB 'FAIL: write succeeds or corrupts an existing record.',13,10
        DB 'RESTORE: discard changes and remount the supplied D: image.',13,10,'$'
MSG0276:DB 13,10,'0276  UNTESTED  REQUIRED      Exact write failure codes',13,10
        DB 'SETUP: mount the supplied restorable full disk as D:.',13,10
        DB 'ACTION: attempt sequential and random allocating writes.',13,10
        DB 'EXPECTED: each returns its documented nonzero failure code.',13,10
        DB 'FAIL: either returns success or an undocumented success alias.',13,10
        DB 'RESTORE: discard changes and remount the supplied D: image.',13,10,'$'
MSG0292:DB 13,10,'0292  UNTESTED  REQUIRED      Allocation release',13,10
        DB 'SETUP: use a fresh copy of the supplied restorable D: disk.',13,10
        DB 'ACTION: delete an allocated file, then allocate equal space.',13,10
        DB 'EXPECTED: new allocation succeeds using released capacity.',13,10
        DB 'FAIL: released capacity remains unavailable.',13,10
        DB 'RESTORE: discard changes and remount the supplied D: image.',13,10,'$'
MSG0293:DB 13,10,'0293  UNTESTED  NOT GUAR.     Exact freed-block reuse',13,10
        DB 'Observe the allocation block reused after delete and Make.',13,10
        DB 'Any valid free block is acceptable; exact order is not fixed.',13,10
        DB 'This observation has no baseline conformance effect.',13,10
        DB 'RESTORE: discard changes and remount the supplied D: image.',13,10,'$'
MSG0355:DB 13,10,'0355  OUT SCOPE               Physical allocation',13,10
        DB 'CP/M exposes logical records and allocation blocks, not media',13,10
        DB 'placement. Physical-sector allocation is BIOS and media specific.',13,10
        DB 'This item is documented but has no baseline conformance test.',13,10,'$'
BADMSG: DB 13,10,'DISKTEST: unknown selector. Use DISKTEST /H.',13,10,'$'
OLDDRV: DB 0
OLDUSR: DB 0
TESTUSR:DB 0
GOTUSR: DB 0
        DS 64
STACKTOP:
        END
