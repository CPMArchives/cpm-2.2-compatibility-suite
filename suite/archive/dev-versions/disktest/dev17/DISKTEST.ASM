; BetterCP/M DISKTEST
; Version 0.1.0-dev17
; Incremental rebuild: six ledger items plus /H, /INFO, and /LIST.
; Intel 8080 instruction subset.
        ORG 0100H
BDOS    EQU 0005H

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

PRINT:  LD C,9
        CALL BDOS
        RET

HELPMSG:DB 13,10,'DISKTEST 0.1.0-dev17',13,10,13,10
        DB '  DISKTEST /NNNN   Run or explain one ledger item',13,10
        DB '  DISKTEST /LIST   List implemented ledger items',13,10
        DB '  DISKTEST /H      Show this help',13,10
        DB '  DISKTEST /INFO   Show build information',13,10,13,10
        DB 'Automated: 0155. Other listed items print controlled procedures.',13,10,'$'
LISTPLACE:DB 13,10,'0155  REQUIRED  Function 13 user-number preservation',13,10,'$'
INFOMSG:DB 13,10,'BetterCP/M DISKTEST 0.1.0-dev17',13,10
        DB 'Implemented commands: /NNNN, /LIST, /H, and /INFO',13,10
        DB 'Ledger items represented: 6',13,10
        DB 'Automated: 1; controlled procedures: 5',13,10
        DB 'Required: 5; not guaranteed: 1',13,10
        DB 'Ledger coverage: 0155, 0255, 0275, 0276, 0292, 0293',13,10,'$'
PASSMSG:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0155  PASS      REQUIRED      Function 13 preserved user number',13,10
        DB 'Summary: 1 pass, 0 fail, 0 error, 0 observations',13,10,'$'
FAILMSG:DB 13,10,'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10
        DB '0155  FAIL      REQUIRED      Function 13 changed user number',13,10
        DB 'Summary: 0 pass, 1 fail, 0 error, 0 observations',13,10,'$'

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
BADMSG: DB 13,10,'DISKTEST: unknown selector. Use DISKTEST /H.',13,10,'$'
OLDDRV: DB 0
OLDUSR: DB 0
TESTUSR:DB 0
GOTUSR: DB 0
        DS 64
STACKTOP:
        END
