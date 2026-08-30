; BetterCP/M executable conformance suite - DISKTEST
; Version 0.1.0-dev4 - proven suite startup and BDOS string output path.
; Intel 8080 instruction subset; destructive/terminal rows are selected only.

        ORG     0100H
BDOS    EQU     0005H

START:  LD      SP,STACKTOP
        LD      HL,0
        PUSH    HL
        CALL    PARSE
        CP      1
        JP      Z,HELP
        CP      2
        JP      Z,LIST
        CP      3
        JP      Z,RUNSAFE
        CP      4
        JP      Z,RUNALL
        CP      5
        JP      Z,RUNONE
        CP      6
        JP      Z,HRESULTS
        CP      7
        JP      Z,HPROFILES
        CP      8
        JP      Z,INFO
        JP      BAD

; Result: 1 help, 2 list, 3 safe, 4 all, 5 item, 6 results, 7 profiles, 8 info.
PARSE:  LD      HL,0081H
        LD      A,(0080H)
        OR      A
        JP      Z,PARSEH
        LD      B,A
PSKIP: LD      A,(HL)
        CP      ' '
        JP      NZ,PSLASH
        INC     HL
        DEC     B
        JP      NZ,PSKIP
PARSEH:LD      A,1
        RET
PSLASH:CP      '/'
        JP      NZ,PARSEH
        INC     HL
        LD      A,(HL)
        AND     5FH
        CP      'H'
        JP      Z,PARSEHX
        CP      'I'
        JP      Z,PARSEI
        CP      'L'
        JP      Z,PARSEL
        CP      'S'
        JP      Z,PARSES
        CP      'A'
        JP      Z,PARSEA
        LD      B,4
        PUSH    HL
        LD      HL,0
        LD      (ITEMNO),HL
        POP     HL
PNUM:  LD      A,(HL)
        CP      '0'
        JP      C,PARSEH
        CP      '9'+1
        JP      NC,PARSEH
        SUB     '0'
        LD      C,A
        PUSH    HL
        LD      HL,(ITEMNO)
        ADD     HL,HL
        PUSH    HL
        ADD     HL,HL
        ADD     HL,HL
        POP     DE
        ADD     HL,DE
        LD      E,C
        LD      D,0
        ADD     HL,DE
        LD      (ITEMNO),HL
        POP     HL
        INC     HL
        DEC     B
        JP      NZ,PNUM
        LD      A,5
        RET
PARSEL:LD      A,2
        RET
PARSES:LD      A,3
        RET
PARSEA:LD      A,4
        RET
PARSEI:LD      A,8
        RET
PARSEHX:
        INC     HL
        LD      A,(HL)
        CP      ':'
        JP      NZ,PARSEH
        INC     HL
        LD      A,(HL)
        AND     5FH
        CP      'R'
        JP      Z,PARSEHR
        CP      'P'
        JP      Z,PARSEHP
        JP      BADCODE
PARSEHR:LD     A,6
        RET
PARSEHP:LD     A,7
        RET
BADCODE:LD     A,0
        RET

HELP:   LD      DE,HLPMSG
        CALL    PUTS
        RET
LIST:   LD      DE,LSTMSG
        CALL    PUTS
        RET
INFO:   LD      DE,INFMSG
        CALL    PUTS
        RET
HRESULTS:
        LD      DE,RESMSG
        CALL    PUTS
        RET
HPROFILES:
        LD      DE,PRFMSG
        CALL    PUTS
        RET
BAD:    LD      DE,BADMSG
        CALL    PUTS
        RET

BEGIN:  XOR     A
        LD      (PASSCT),A
        LD      (FAILCT),A
        LD      (OBSCT),A
        LD      DE,HEADER
        JP      PUTS

RUNSAFE:
        LD      A,1
        LD      (RUNMODE),A
        CALL    BEGIN
        CALL    P0155
        CALL    P0373
        CALL    P0374
        CALL    P0375
        CALL    P0376
        CALL    P0377
        CALL    P0378
        JP      SUMMARY

RUNALL: CALL    RUNSAFE0
        LD      DE,ALLMAN
        CALL    PUTS
        JP      SUMMARY
RUNSAFE0:
        LD      A,1
        LD      (RUNMODE),A
        CALL    BEGIN
        CALL    P0155
        CALL    P0373
        CALL    P0374
        CALL    P0375
        CALL    P0376
        CALL    P0377
        CALL    P0378
        RET

; Numeric dispatch. Automated rows execute; selected/manual rows explain the
; exact setup, action, success/failure evidence, and restoration requirement.
RUNONE: CALL    BEGIN
        XOR     A
        LD      (RUNMODE),A
        LD      HL,(ITEMNO)
        LD      DE,155
        CALL    EQHLDE
        JP      Z,P0155
        LD      DE,255
        CALL    EQHLDE
        JP      Z,M0255
        LD      DE,275
        CALL    EQHLDE
        JP      Z,M0275
        LD      DE,276
        CALL    EQHLDE
        JP      Z,M0276
        LD      DE,292
        CALL    EQHLDE
        JP      Z,M0292
        LD      DE,293
        CALL    EQHLDE
        JP      Z,M0293
        LD      DE,355
        CALL    EQHLDE
        JP      Z,M0355
        LD      DE,373
        CALL    EQHLDE
        JP      Z,P0373
        LD      DE,374
        CALL    EQHLDE
        JP      Z,P0374
        LD      DE,375
        CALL    EQHLDE
        JP      Z,P0375
        LD      DE,376
        CALL    EQHLDE
        JP      Z,P0376
        LD      DE,377
        CALL    EQHLDE
        JP      Z,P0377
        LD      DE,378
        CALL    EQHLDE
        JP      Z,P0378
        LD      DE,379
        CALL    EQHLDE
        JP      Z,M0379
        LD      DE,380
        CALL    EQHLDE
        JP      Z,M0380
        LD      DE,381
        CALL    EQHLDE
        JP      Z,M0381
        LD      DE,382
        CALL    EQHLDE
        JP      Z,M0382
        LD      DE,383
        CALL    EQHLDE
        JP      Z,M0383
        LD      DE,384
        CALL    EQHLDE
        JP      Z,M0384
        LD      DE,558
        CALL    EQHLDE
        JP      Z,M0558
        JP      BAD

EQHLDE:LD      A,L
        XOR     E
        LD      B,A
        LD      A,H
        XOR     D
        OR      B
        RET

; Function 13 must preserve the current user number. It may reset disk state,
; so this probe records and restores the selected drive around the call.
P0155: LD      C,25
        CALL    BDOS
        LD      (OLDDRV),A
        LD      E,0FFH
        LD      C,32
        CALL    BDOS
        LD      (OLDUSR),A
        LD      C,13
        CALL    BDOS
        LD      E,0FFH
        LD      C,32
        CALL    BDOS
        LD      B,A
        LD      A,(OLDUSR)
        CP      B
        JP      NZ,F0155
        LD      A,(OLDDRV)
        LD      E,A
        LD      C,14
        CALL    BDOS
        LD      DE,R0155P
        JP      PASSROW
F0155: LD      DE,R0155F
        JP      FAILROW

; Helpers for Function 28/29. Each probe uses B:, then Function 13 and the
; original drive selection to avoid leaking software write protection.
SETPROT:
        LD      C,25
        CALL    BDOS
        LD      (OLDDRV),A
        LD      E,1
        LD      C,14
        CALL    BDOS
        LD      C,28
        CALL    BDOS
        RET
GETRO: LD      C,29
        CALL    BDOS
        LD      A,L
        RET
RESETD:LD      C,13
        CALL    BDOS
        LD      A,(OLDDRV)
        LD      E,A
        LD      C,14
        CALL    BDOS
        RET

P0373: CALL    SETPROT
        CALL    GETRO
        AND     02H
        PUSH    AF
        CALL    RESETD
        POP     AF
        JP      Z,F0373
        LD      DE,R0373P
        JP      PASSROW
F0373: LD      DE,R0373F
        JP      FAILROW

P0374: CALL    SETPROT
        LD      C,13
        CALL    BDOS
        CALL    GETRO
        AND     02H
        PUSH    AF
        LD      A,(OLDDRV)
        LD      E,A
        LD      C,14
        CALL    BDOS
        POP     AF
        JP      NZ,F0374
        LD      DE,R0374P
        JP      PASSROW
F0374: LD      DE,R0374F
        JP      FAILROW

P0375: CALL    SETPROT
        CALL    GETRO
        LD      (LASTV),A
        CALL    RESETD
        LD      A,(LASTV)
        AND     02H
        JP      Z,F0375
        LD      DE,R0375P
        JP      PASSROW
F0375: LD      DE,R0375F
        JP      FAILROW

P0376: CALL    SETPROT
        CALL    GETRO
        AND     02H
        PUSH    AF
        CALL    RESETD
        POP     AF
        JP      Z,F0376
        LD      DE,R0376P
        JP      PASSROW
F0376: LD      DE,R0376F
        JP      FAILROW

P0377: CALL    SETPROT
        CALL    GETRO
        AND     02H
        PUSH    AF
        CALL    RESETD
        POP     AF
        JP      Z,F0377
        LD      DE,R0377P
        JP      PASSROW
F0377: LD      DE,R0377F
        JP      FAILROW

P0378: CALL    SETPROT
        LD      C,13
        CALL    BDOS
        CALL    GETRO
        AND     02H
        PUSH    AF
        LD      A,(OLDDRV)
        LD      E,A
        LD      C,14
        CALL    BDOS
        POP     AF
        JP      NZ,F0378
        LD      DE,R0378P
        JP      PASSROW
F0378: LD      DE,R0378F
        JP      FAILROW

PASSROW:
        PUSH    DE
        LD      A,(PASSCT)
        INC     A
        LD      (PASSCT),A
        POP     DE
        CALL    PUTS
        LD      A,(RUNMODE)
        OR      A
        RET     NZ
        JP      SUMMARY
FAILROW:
        PUSH    DE
        LD      A,(FAILCT)
        INC     A
        LD      (FAILCT),A
        POP     DE
        CALL    PUTS
        LD      A,(RUNMODE)
        OR      A
        RET     NZ
        JP      SUMMARY

; Manual and metadata selections print their full procedure and return with an
; UNTESTED summary. The terminal protection cases can return directly to CCP.
M0255: LD      DE,P0255
        JP      MANOUT
M0275: LD      DE,P0275
        JP      MANOUT
M0276: LD      DE,P0276
        JP      MANOUT
M0292: LD      DE,P0292
        JP      MANOUT
M0293: LD      DE,P0293
        JP      MANOUT
M0355: LD      DE,P0355
        JP      MANOUT
M0379: LD      DE,P0379
        JP      MANOUT
M0380: LD      DE,P0380
        JP      MANOUT
M0381: LD      DE,P0381
        JP      MANOUT
M0382: LD      DE,P0382
        JP      MANOUT
M0383: LD      DE,P0383
        JP      MANOUT
M0384: LD      DE,P0384
        JP      MANOUT
M0558: LD      DE,P0558
MANOUT:CALL    PUTS
        JP      SUMMARY

SUMMARY:
        LD      DE,SUM1
        CALL    PUTS
        LD      A,(PASSCT)
        CALL    PUTNUM
        LD      DE,SUM2
        CALL    PUTS
        LD      A,(FAILCT)
        CALL    PUTNUM
        LD      DE,SUM3
        CALL    PUTS
        LD      A,(OBSCT)
        CALL    PUTNUM
        LD      DE,SUM4
        CALL    PUTS
        RET

PUTNUM:CP      10
        JP      C,PUTDIG
        LD      B,0
PN1:   SUB     10
        INC     B
        CP      10
        JP      NC,PN1
        PUSH    AF
        LD      A,B
        CALL    PUTDIG
        POP     AF
PUTDIG:ADD     A,'0'
        LD      E,A
        LD      C,2
        JP      BDOS
; This is the same proven Function 9 string path used by the completed tools.
PUTS:  LD      C,9
        JP      BDOS

HEADER:DB 13,10,'DISKTEST',13,10
        DB 'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10,'$'

R0155P:DB '0155  PASS      REQUIRED      Function 13 preserved user number',13,10,'$'
R0155F:DB '0155  FAIL      REQUIRED      Function 13 changed user number',13,10,'$'
R0373P:DB '0373  PASS      REQUIRED      Function 28 protected current disk',13,10,'$'
R0373F:DB '0373  FAIL      REQUIRED      Function 28 did not protect disk',13,10,'$'
R0374P:DB '0374  PASS      REQUIRED      Protection ended after disk reset',13,10,'$'
R0374F:DB '0374  FAIL      REQUIRED      Protection survived disk reset',13,10,'$'
R0375P:DB '0375  PASS      REQUIRED      Function 29 returned R/O vector',13,10,'$'
R0375F:DB '0375  FAIL      REQUIRED      Function 29 omitted protected disk',13,10,'$'
R0376P:DB '0376  PASS      REQUIRED      Vector bit 1 represented drive B',13,10,'$'
R0376F:DB '0376  FAIL      REQUIRED      Drive B did not map to vector bit 1',13,10,'$'
R0377P:DB '0377  PASS      REQUIRED      Function 28 set drive-B vector bit',13,10,'$'
R0377F:DB '0377  FAIL      REQUIRED      Function 28 left vector bit clear',13,10,'$'
R0378P:DB '0378  PASS      REQUIRED      Function 13 cleared R/O vector',13,10,'$'
R0378F:DB '0378  FAIL      REQUIRED      Function 13 left R/O vector set',13,10,'$'

ALLMAN:DB '0255  UNTESTED  REQUIRED      Run: DISKTEST /0255 with full D:',13,10
        DB '0275  UNTESTED  REQUIRED      Run: DISKTEST /0275 with full D:',13,10
        DB '0276  UNTESTED  REQUIRED      Run: DISKTEST /0276 with full D:',13,10
        DB '0292  UNTESTED  REQUIRED      Run: DISKTEST /0292 on scratch D:',13,10
        DB '0293  UNTESTED  NOT GUAR.     Run: DISKTEST /0293 on scratch D:',13,10
        DB '0355  UNTESTED  OUT SCOPE     Physical allocation is not portable',13,10
        DB '0379  UNTESTED  REQUIRED      Run: DISKTEST /0379 separately',13,10
        DB '0380  UNTESTED  REQUIRED      Run: DISKTEST /0380 separately',13,10
        DB '0381  UNTESTED  REQUIRED      Run: DISKTEST /0381 separately',13,10
        DB '0382  UNTESTED  REQUIRED      Run: DISKTEST /0382 separately',13,10
        DB '0383  UNTESTED  REQUIRED      Run: DISKTEST /0383 separately',13,10
        DB '0384  UNTESTED  REQUIRED      Run: DISKTEST /0384 separately',13,10
        DB '0558  UNTESTED  OUT SCOPE     Allocation order is not portable',13,10,'$'

P0255: DB 13,10,'0255  UNTESTED  REQUIRED      Data-full empty Make procedure',13,10
        DB 'SETUP: mount the supplied restorable full disk as D:.',13,10
        DB 'ACTION: make D:EMPTY.TST without writing a data record.',13,10
        DB 'EXPECTED: Make succeeds because an empty file needs no data block.',13,10
        DB 'FAIL: Make reports data-full before any record is written.',13,10
        DB 'RESTORE: discard changes and remount the supplied D: image.',13,10,'$'
P0275: DB 13,10,'0275  UNTESTED  REQUIRED      Allocation-full failure procedure',13,10
        DB 'SETUP: mount the supplied restorable full disk as D:.',13,10
        DB 'ACTION: append one record to D:BTFULL.DAT.',13,10
        DB 'EXPECTED: the allocating write fails; existing data remains intact.',13,10
        DB 'FAIL: the write succeeds or corrupts an existing record.',13,10
        DB 'RESTORE: discard changes and remount the supplied D: image.',13,10,'$'
P0276: DB 13,10,'0276  UNTESTED  REQUIRED      Exact write failure-code procedure',13,10
        DB 'SETUP: mount the supplied restorable full disk as D:.',13,10
        DB 'ACTION: attempt sequential and random allocating writes.',13,10
        DB 'EXPECTED: each returns its documented nonzero failure code.',13,10
        DB 'FAIL: either call returns success or an undocumented success alias.',13,10
        DB 'RESTORE: discard changes and remount the supplied D: image.',13,10,'$'
P0292: DB 13,10,'0292  UNTESTED  REQUIRED      Allocation release procedure',13,10
        DB 'SETUP: use a fresh copy of the supplied restorable D: disk.',13,10
        DB 'ACTION: delete a known allocated file, then allocate equal space.',13,10
        DB 'EXPECTED: the new allocation succeeds using released capacity.',13,10
        DB 'FAIL: released capacity remains unavailable.',13,10
        DB 'RESTORE: discard changes and remount the supplied D: image.',13,10,'$'
P0293: DB 13,10,'0293  UNTESTED  NOT GUAR.     Freed-block reuse observation',13,10
        DB 'Observe which allocation block is reused after delete and Make.',13,10
        DB 'Any valid free block is acceptable; exact reuse order is not fixed.',13,10
        DB 'This observation has no baseline conformance effect.',13,10
        DB 'RESTORE: discard changes and remount the supplied D: image.',13,10,'$'
P0355: DB 13,10,'0355  UNTESTED  OUT SCOPE',13,10
        DB 'Physical allocation need not equal a file logical or virtual size.',13,10
        DB 'DISKTEST cannot assign a portable PASS or FAIL to this item.',13,10,'$'

P0379: DB 13,10,'0379  UNTESTED  REQUIRED      Protected-disk Make procedure',13,10
        DB 'ACTION: protect scratch D: with Function 28, then Make a new file.',13,10
        DB 'EXPECTED: BDOS rejects mutation and returns a usable CCP prompt.',13,10
        DB 'FAIL: a file is created, the system hangs, or the disk is changed.',13,10
        DB 'RESTORE: remount D: and run Function 13 before further testing.',13,10,'$'
P0380: DB 13,10,'0380  UNTESTED  REQUIRED      Protected sequential-write procedure',13,10
        DB 'ACTION: protect scratch D:, then sequentially write an open file.',13,10
        DB 'EXPECTED: BDOS rejects mutation and returns a usable CCP prompt.',13,10
        DB 'FAIL: data changes, the system hangs, or protection is bypassed.',13,10
        DB 'RESTORE: remount D: and run Function 13 before further testing.',13,10,'$'
P0381: DB 13,10,'0381  UNTESTED  REQUIRED      Protected random-write procedure',13,10
        DB 'ACTION: protect scratch D:, then randomly write an open file.',13,10
        DB 'EXPECTED: BDOS rejects mutation and returns a usable CCP prompt.',13,10
        DB 'FAIL: data changes, the system hangs, or protection is bypassed.',13,10
        DB 'RESTORE: remount D: and run Function 13 before further testing.',13,10,'$'
P0382: DB 13,10,'0382  UNTESTED  REQUIRED      Protected-disk Delete procedure',13,10
        DB 'ACTION: protect scratch D:, then delete a known test file.',13,10
        DB 'EXPECTED: BDOS rejects deletion and returns a usable CCP prompt.',13,10
        DB 'FAIL: the file disappears, the system hangs, or disk data changes.',13,10
        DB 'RESTORE: remount D: and run Function 13 before further testing.',13,10,'$'
P0383: DB 13,10,'0383  UNTESTED  REQUIRED      Protected-disk Rename procedure',13,10
        DB 'ACTION: protect scratch D:, then rename a known test file.',13,10
        DB 'EXPECTED: BDOS rejects rename and returns a usable CCP prompt.',13,10
        DB 'FAIL: the name changes, the system hangs, or disk data changes.',13,10
        DB 'RESTORE: remount D: and run Function 13 before further testing.',13,10,'$'
P0384: DB 13,10,'0384  UNTESTED  REQUIRED      Protection-before-mutation procedure',13,10
        DB 'Capture the D: image, protect D:, and request one mutation.',13,10
        DB 'EXPECTED: rejection occurs before any directory or data change.',13,10
        DB 'FAIL: image comparison finds any mutation after the rejected call.',13,10
        DB 'RESTORE: remount D: and run Function 13 before further testing.',13,10,'$'
P0558: DB 13,10,'0558  UNTESTED  OUT SCOPE',13,10
        DB 'CP/M does not promise an allocation order across file lifecycles.',13,10
        DB 'DISKTEST cannot assign a portable PASS or FAIL to this item.',13,10,'$'

BADMSG:DB 'DISKTEST: unknown selector. Use DISKTEST /H.',13,10,'$'
HLPMSG:DB 13,10,'DISKTEST 0.1.0-dev4 - CP/M disk-state tests',13,10,13,10
        DB '  DISKTEST /NNNN   Run or explain one ledger item',13,10
        DB '  DISKTEST /SAFE   Run returning automated REQUIRED items',13,10
        DB '  DISKTEST /ALL    Include manual, diagnostic, and metadata rows',13,10
        DB '  DISKTEST /LIST   List ledger entries',13,10
        DB '  DISKTEST /INFO   Show version and coverage totals',13,10
        DB '  DISKTEST /H      Show this command summary',13,10
        DB '  DISKTEST /H:RESULTS   Explain results and classes',13,10
        DB '  DISKTEST /H:PROFILES  Explain fixtures and equipment',13,10,'$'
RESMSG:DB 13,10,'DISKTEST result terminology',13,10,13,10
        DB 'STATUS is the outcome: PASS, FAIL, or UNTESTED.',13,10
        DB 'PASS=completed and matched; FAIL=completed and mismatched.',13,10
        DB 'UNTESTED=not executed, unavailable, or not yet judged.',13,10
        DB 'CLASS: REQUIRED=baseline; NOT GUAR.=informational.',13,10
        DB 'OUT SCOPE=DISKTEST cannot execute or judge the item.',13,10
        DB 'OBSERVED gives evidence or the command still required.',13,10,'$'
PRFMSG:DB 13,10,'DISKTEST fixtures and equipment',13,10,13,10
        DB 'No named compatibility profiles are defined.',13,10
        DB 'B: holds DISKTEST; destructive/full tests use restorable D:.',13,10
        DB 'Never run a destructive selector on a disk that contains unique data.',13,10
        DB 'Terminal protection checks may return directly to the CCP.',13,10,'$'
INFMSG:DB 'BetterCP/M DISKTEST 0.1.0-dev4',13,10
        DB 'Catalog rows represented: 20 of 20; remaining 0',13,10
        DB 'Required: 17 (10 selected); diagnostics: 1',13,10
        DB 'Outside scope: 2; automated safe checks: 7',13,10,'$'
LSTMSG:DB 13,10,'BetterCP/M DISKTEST ledger entries',13,10
        DB '0155  Function 13 user-number preservation',13,10
        DB '0255  Data-full empty Make',13,10
        DB '0275  Allocation-full failure',13,10
        DB '0276  Exact write failure codes',13,10
        DB '0292  Allocation release',13,10
        DB '0293  Exact freed-block reuse',13,10
        DB '0355  Physical allocation equals virtual size',13,10
        DB '0373  Function 28 convention',13,10
        DB '0374  Function 28 transience',13,10
        DB '0375  Function 29 convention',13,10
        DB '0376  Read-only vector mapping',13,10
        DB '0377  Function 28 vector effect',13,10
        DB '0378  Reset clears software protection',13,10
        DB '0379  Protected-disk Make',13,10
        DB '0380  Protected-disk sequential write',13,10
        DB '0381  Protected-disk random write',13,10
        DB '0382  Protected-disk Delete',13,10
        DB '0383  Protected-disk Rename',13,10
        DB '0384  Protection before mutation',13,10
        DB '0558  Allocation order is outside lifecycle compatibility',13,10,'$'

SUM1:  DB 13,10,'Summary: ','$'
SUM2:  DB ' pass, ','$'
SUM3:  DB ' fail, 0 error, ','$'
SUM4:  DB ' observations',13,10,'$'

RUNMODE:DB 0
PASSCT: DB 0
FAILCT: DB 0
OBSCT:  DB 0
OLDDRV: DB 0
OLDUSR: DB 0
LASTV:  DB 0
ITEMNO: DW 0
        DS 128
STACKTOP:
        END     START
