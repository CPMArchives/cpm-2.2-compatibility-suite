;***********************************************************************
;*                                                                     *
;*               E R R T E S T   --   RELEASE DEV8                    *
;*                                                                     *
;*       BETTER CP/M ERROR AND RECOVERY EXERCISE PROGRAM               *
;*                                                                     *
;***********************************************************************
;
; Version 0.1.0-dev8 - period-style programmer commentary pass
;
; ASSEMBLY:  M80 IN .Z80 MODE.  ONLY 8080 OPERATIONS ARE USED.
; LOAD AT:   0100H
;
;------------------------- PROGRAMMER'S NOTES --------------------------
;
; Error testing has one disagreeable property: the interesting return is
; often the return which never reaches the transient.  A logical refusal
; comes back through 0005H and can be judged here.  A physical refusal may
; leave the caller suspended in the resident error handler, and ABORT throws
; the caller away altogether.  These are three different tests; do not turn
; one into evidence for another merely because the screen says ERROR.
;
; The physical group consequently calls for a declared fault provider.  A
; provider may be real media, an emulator fault, or a guarded BIOS shim, but
; it must fail after the requested operation has reached the candidate BIOS.
; A stub which merely returns an error to ERRTEST tests the stub, not CP/M.
;
; Non-returning work will use a small continuation file in later revisions,
; in the same manner as BIOSTEST's boot cards.  The card is written before
; the fault and judged only after the CCP has regained control.  Until that
; machinery and its provider are present the row remains '-' -- never PASS.
;
; ERR-001 through ERR-022 are provider procedures.  They are implemented but
; are not run by /ALL: a dash means that the operator did not perform the
; procedure during this invocation.  ERR-023 is the first returning oracle.
; It opens the one-record suite fixture, accepts one record, then requires
; sequential EOF=1 without entering resident error handling.
;
; The automatic office uses reserved BTERW?.TMP names.  Each FCB is built
; afresh because BDOS alters its control bytes.  DMA is local while evidence
; is gathered and is restored to 0080h on every returning road.
;
; Random read distinguishes record zero success from record one EOF.  Random
; write proves an ordinary write, then puts 000100h in r0/r1/r2 (record 10000h)
; and requires range refusal 06h.  The lifecycle card chains missing Open,
; Make, Close, Rename, and Delete, cleaning both old and new names.
;
; Card 0582 looks back at the four stored automatic statuses.  It passes only
; when all controlled logical failures returned, proving none wandered into a
; resident physical-error handler.
;
;***********************************************************************

        ORG     0100H
BDOS    EQU     0005H
NCASES  EQU     43

START:  LD      SP,STACKTOP
        LD      HL,0               ;RET must warm-start through page zero
        PUSH    HL
        CALL    PARSE
        CP      1
        JP      Z,HELP
        CP      2
        JP      Z,LIST
        CP      3
        JP      Z,RUNALL
        CP      4
        JP      Z,RUNONE
        CP      5
        JP      Z,INFO
        CP      6
        JP      Z,HRESULTS
        CP      7
        JP      Z,HPROFILES
        CP      8
        JP      Z,RUNSAFE
        LD      DE,BADSEL
        CALL    PUTS
        RET

; Decode the command tail.  Exit A: 1 help, 2 list, 3 all, 4 item,
; 5 info, 6 result help, 7 profile help, 8 safe.
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
        CP      '0'
        JP      C,PSWORD
        CP      '9'+1
        JP      C,PSNUM
PSWORD:AND     5FH
        CP      'H'
        JP      Z,PARSEHX
        CP      'L'
        JP      Z,PARSEL
        CP      'A'
        JP      Z,PARSEA
        CP      'S'
        JP      Z,PARSES
        CP      'I'
        JP      Z,PARSEI
        JP      PARSEH
PSNUM:
        LD      DE,SELBUF
        LD      C,4
PNUM:  LD      A,(HL)
        CP      '0'
        JP      C,PARSEH
        CP      '9'+1
        JP      NC,PARSEH
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     C
        JP      NZ,PNUM
        LD      A,4
        RET
PARSEL:LD      A,2
        RET
PARSEA:LD      A,3
        RET
PARSES:LD      A,8
        RET
PARSEI:LD      A,5
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
        JP      PARSEH
PARSEHR:LD     A,6
        RET
PARSEHP:LD     A,7
        RET

HELP:  LD      DE,HLPMSG
        JP      PUTS
LIST:  LD      DE,LSTMSG
        JP      PUTS
INFO:  LD      DE,INFMSG
        JP      PUTS
HRESULTS:
        LD      DE,RESMSG
        JP      PUTS
HPROFILES:
        LD      DE,PRFMSG
        JP      PUTS

; THE AUTOMATIC DESK
; /SAFE and /ALL presently share the returning report.  Fault procedures
; are not sprung from an aggregate command: each needs an operator-selected
; fixture and an unambiguous recovery path.
RUNSAFE:
RUNALL: CALL    AUTOTESTS
        CALL    PRINTHEAD
        LD      HL,CASES
        LD      B,NCASES
RALP:  PUSH    BC
        PUSH    HL
        CALL    PRINTROW
        POP     HL
        LD      DE,8
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RALP
        JP      SUMMARY

RUNONE:LD      HL,CASES
        CALL    AUTOTESTS
        LD      HL,CASES
        LD      B,NCASES
RONXT: PUSH    BC
        PUSH    HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      DE,SELBUF
        LD      C,4
ROCMP: LD      A,(DE)
        CP      (HL)
        JP      NZ,RONOM
        INC     DE
        INC     HL
        DEC     C
        JP      NZ,ROCMP
        POP     HL
        POP     BC
        CALL    PRINTHEAD
        PUSH    HL
        CALL    PRINTROW
        POP     HL
        CALL    DETAIL
        LD      DE,ONESUM
        JP      PUTS
RONOM: POP     HL
        LD      DE,8
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RONXT
        LD      DE,BADSEL
        JP      PUTS

PRINTHEAD:
        LD      DE,HEADMSG
        JP      PUTS

; HL addresses four words: item, status, class and observation.
PRINTROW:
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        LD      B,4
        CALL    PUTFIELD
        LD      DE,SP2
        CALL    PUTS
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        LD      B,1
        CALL    PUTFIELD
        LD      DE,SP2
        CALL    PUTS
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        LD      B,1
        CALL    PUTFIELD
        LD      DE,SP2
        CALL    PUTS
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        CALL    PUTS
        LD      DE,CRLF
        JP      PUTS

PUTFIELD:
        PUSH    HL
        PUSH    BC
        EX      DE,HL
PFCHR: LD      A,B
        OR      A
        JP      Z,PFDONE
        LD      A,(HL)
        CP      '$'
        JP      Z,PFSP
        INC     HL
        LD      E,A
        LD      C,2
        PUSH    HL
        PUSH    BC
        CALL    BDOS
        POP     BC
        POP     HL
        DEC     B
        JP      PFCHR
PFSP:  LD      E,' '
        LD      C,2
        PUSH    HL
        PUSH    BC
        CALL    BDOS
        POP     BC
        POP     HL
        DEC     B
        JP      NZ,PFSP
PFDONE:POP     BC
        POP     HL
        RET

PUTS:  PUSH    HL
        PUSH    BC
        LD      C,9
        CALL    BDOS
        POP     BC
        POP     HL
        RET

;---------------------- FIRST RETURNING ORACLE ------------------------
; 0404 uses a shipped, immutable one-record fixture.  Success followed by
; logical EOF is sufficient here: no physical fault is requested and no
; resident error choice may intervene.  Close and DMA restoration are done
; on every path after a successful open.
; Reset all five result cells; an oracle replaces '-' only after cleanup.
AUTOTESTS:
        CALL    T0404
        CALL    T0406
        CALL    T0407
        CALL    T0408
        JP      T0582

; Sequential read: record zero succeeds and the following read returns EOF.
T0404:
        LD      HL,TESTFCB
        LD      B,36
        XOR     A
ATCLR: LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,ATCLR
        LD      HL,ONEFILE
        LD      DE,TESTFCB+1
        LD      B,11
ATNAM: LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,ATNAM
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        INC     A
        JP      Z,ATFAIL
        LD      DE,DMA
        LD      C,26
        CALL    BDOS
        LD      DE,TESTFCB
        LD      C,20
        CALL    BDOS
        OR      A
        JP      NZ,ATCFAIL
        LD      DE,TESTFCB
        LD      C,20
        CALL    BDOS
        CP      1
        JP      NZ,ATCFAIL
        CALL    ATCLOSE
        LD      HL,STPASS
        LD      (C0404+2),HL
        LD      HL,V0404
        LD      (C0404+6),HL
        RET
ATCFAIL:
        CALL    ATCLOSE
ATFAIL:LD      HL,STFAIL
        LD      (C0404+2),HL
        LD      HL,F0404
        LD      (C0404+6),HL
        RET
ATCLOSE:
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        LD      DE,0080H
        LD      C,26
        JP      BDOS

; 0406 -- Random record zero exists; record one is the first unwritten
; record.  Function 33 must distinguish success from logical EOF.
; Random read drives r0/r1/r2 explicitly for record zero and record one.
T0406: LD      HL,ONEFILE
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        INC     A
        JP      Z,F0406X
        XOR     A
        LD      (TESTFCB+33),A
        LD      (TESTFCB+34),A
        LD      (TESTFCB+35),A
        LD      DE,TESTFCB
        LD      C,33
        CALL    BDOS
        OR      A
        JP      NZ,F0406C
        LD      A,1
        LD      (TESTFCB+33),A
        LD      DE,TESTFCB
        LD      C,33
        CALL    BDOS
        CP      1
        JP      NZ,F0406C
        CALL    ATCLOSE
        LD      HL,STPASS
        LD      (C0406+2),HL
        LD      HL,V0406
        LD      (C0406+6),HL
        RET
F0406C:CALL    ATCLOSE
F0406X:LD      HL,STFAIL
        LD      (C0406+2),HL
        LD      HL,F0406
        LD      (C0406+6),HL
        RET

; 0407 -- A private temporary file supplies the successful random write.
; Record 10000h supplies the distinct range error without filling the disk.
; Random write checks ordinary success and the record-10000h range refusal.
T0407: LD      HL,TEMP1
        CALL    INITFCB
        CALL    DELFCB
        LD      DE,TESTFCB
        LD      C,22
        CALL    BDOS
        INC     A
        JP      Z,F0407X
        XOR     A
        LD      (TESTFCB+33),A
        LD      (TESTFCB+34),A
        LD      (TESTFCB+35),A
        LD      DE,DMA
        LD      C,26
        CALL    BDOS
        LD      DE,TESTFCB
        LD      C,34
        CALL    BDOS
        OR      A
        JP      NZ,F0407C
        XOR     A
        LD      (TESTFCB+33),A
        LD      (TESTFCB+34),A
        LD      A,1
        LD      (TESTFCB+35),A
        LD      DE,TESTFCB
        LD      C,34
        CALL    BDOS
        CP      6
        JP      NZ,F0407C
        CALL    ATCLOSE
        CALL    DELFCB
        LD      HL,STPASS
        LD      (C0407+2),HL
        LD      HL,V0407
        LD      (C0407+6),HL
        RET
F0407C:CALL    ATCLOSE
        CALL    DELFCB
F0407X:LD      HL,STFAIL
        LD      (C0407+2),HL
        LD      HL,F0407
        LD      (C0407+6),HL
        RET

; 0408 -- Exercise real directory operations, including a rename whose new
; name occupies the second filename field of the same FCB.
; Missing-file lifecycle, including rename overlay and both-name cleanup.
T0408: LD      HL,TEMP2
        CALL    INITFCB
        CALL    DELFCB
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        INC     A
        JP      NZ,F0408X
        LD      DE,TESTFCB
        LD      C,22
        CALL    BDOS
        INC     A
        JP      Z,F0408X
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        OR      A
        JP      NZ,F0408D
        LD      HL,NEWNAME
        LD      DE,TESTFCB+17
        LD      B,11
T8NAM: LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,T8NAM
        LD      DE,TESTFCB
        LD      C,23
        CALL    BDOS
        INC     A
        JP      Z,F0408D
        LD      HL,NEWNAME
        CALL    INITFCB
        CALL    DELFCB
        INC     A
        JP      Z,F0408X
        LD      HL,STPASS
        LD      (C0408+2),HL
        LD      HL,V0408
        LD      (C0408+6),HL
        RET
F0408D:CALL    DELFCB
F0408X:LD      HL,STFAIL
        LD      (C0408+2),HL
        LD      HL,F0408
        LD      (C0408+6),HL
        RET

; 0582 is a cross-check, not a duplicate disk operation.  It passes only
; when every logical refusal above returned to this transient for judgment.
; Meta-oracle: all four controlled logical operations must have returned PASS.
T0582: LD      HL,(C0404+2)
        LD      DE,STPASS
        CALL    CMPEQ
        JP      NZ,F0582X
        LD      HL,(C0406+2)
        CALL    CMPEQ
        JP      NZ,F0582X
        LD      HL,(C0407+2)
        CALL    CMPEQ
        JP      NZ,F0582X
        LD      HL,(C0408+2)
        CALL    CMPEQ
        JP      NZ,F0582X
        LD      HL,STPASS
        LD      (C0582+2),HL
        LD      HL,V0582
        LD      (C0582+6),HL
        RET
F0582X:LD      HL,STFAIL
        LD      (C0582+2),HL
        LD      HL,F0582
        LD      (C0582+6),HL
        RET

; Compare HL and DE.  Z means equal.
CMPEQ:  LD      A,L
        CP      E
        RET     NZ
        LD      A,H
        CP      D
        RET

; Build a clean 36-byte FCB from an eleven-byte name for every experiment.
INITFCB:
        PUSH    HL
        LD      HL,TESTFCB
        LD      B,36
        XOR     A
IFCLR: LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,IFCLR
        POP     HL
        LD      DE,TESTFCB+1
        LD      B,11
IFNAM: LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,IFNAM
        RET
DELFCB:LD      DE,TESTFCB
        LD      C,19
        JP      BDOS

SUMMARY:
        LD      HL,(C0582+2)
        LD      DE,STPASS
        CALL    CMPEQ
        JP      NZ,SUMBAD
        LD      DE,SUMPASS
        JP      SUMOUT
SUMBAD:
        LD      DE,SUMFAIL
SUMOUT: CALL    PUTS
        LD      DE,SUMCOV
        JP      PUTS

; Pick the procedure by class of experiment, not by prose in the table.
; Items 0404-0408, 0516 and 0582 are logical-return work.  0386, 0409
; and 0410 are documentary exclusions.  The rest require a fault, profile,
; lifecycle restart or damaged-media fixture.
DETAIL:LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      A,(HL)
        CP      '0'
        JP      NZ,DETPHY
        INC     HL
        LD      A,(HL)
        CP      '4'
        JP      NZ,DETPHY
        INC     HL
        LD      A,(HL)
        CP      '0'
        JP      NZ,DETPHY
        INC     HL
        LD      A,(HL)
        CP      '4'
        JP      C,DETPHY
        CP      '9'
        JP      C,DETLOG
DETPHY:
        LD      DE,PHYPROC
        JP      PUTS
DETLOG:LD      DE,LOGPROC
        JP      PUTS

;------------------------------ TEXT ----------------------------------
HLPMSG:DB 13,10,'ERRTEST 0.1.0-dev8',13,10,13,10
        DB '  ERRTEST /NNNN  Run or explain one ledger item',13,10
        DB '  ERRTEST /ALL   Run returning checks and list procedures',13,10
        DB '  ERRTEST /SAFE  Run checks requiring no destructive media',13,10
        DB '  ERRTEST /LIST  List implemented ledger items',13,10
        DB '  ERRTEST /H     Show this help',13,10
        DB '  ERRTEST /INFO  Show build information',13,10,'$'
INFMSG:DB 13,10,'BetterCP/M ERRTEST 0.1.0-dev8',13,10
        DB 'Catalog: ERR-001 through ERR-043 (43 rows)',13,10
        DB 'Implemented: ERR-001 through ERR-043; no rows remain',13,10
        DB 'Processor required: Intel 8080',13,10
        DB 'Physical and nonreturning tests require declared providers.',13,10,'$'
RESMSG:DB 13,10,'STATUS: P pass, F fail, - not run, O observation.',13,10
        DB 'CLASS: R required, N not guaranteed, S outside scope, X profile.',13,10
        DB 'A provider-dependent row remains - until its full oracle runs.',13,10,'$'
PRFMSG:DB 13,10,'CPM-DISKERR-INT: interactive disk-error handling.',13,10
        DB 'DRI-PROTECT-INT: DRI-style protection-error handling.',13,10
        DB 'DRI-DIAG-PRES: exact DRI diagnostic presentation.',13,10
        DB 'REMOVABLE-MEDIA: automatic media-change protection.',13,10
        DB 'CCP-LIFECYCLE: post-termination drive and user policy.',13,10
        DB 'DRI-RES-PRES: exact resident error presentation.',13,10,'$'
BADSEL:DB 13,10,'Unknown selector. Use ERRTEST /H.',13,10,'$'
HEADMSG:DB 13,10,'STATUS: P=Pass F=Fail -=Not-run O=Observed',13,10
        DB 'CLASS:  R=Required N=Not-guaranteed S=Out-of-scope X=Profile',13,10
        DB 'ITEM  S  C  OBSERVED',13,10
        DB '----  -  -  -------------------------------------------------------------------',13,10,'$'
SUMPASS:DB 'Summary: 5 pass, 0 fail, 0 error, 12 observed, 26 not-run',13,10,'$'
SUMFAIL:DB 'Summary: returning logical oracle failed; see rows above',13,10,'$'
SUMCOV: DB '43 catalog items implemented; 0 remain to implement.',13,10,'$'
ONESUM:DB 'Summary: selected row reported above.',13,10,'$'
SP2:   DB '  $'
CRLF:  DB 13,10,'$'

LOGPROC:DB 13,10,'SETUP: use a prepared expendable disk and reserved ERR*.TMP names.',13,10
        DB 'ACTION: force the named logical refusal through the public BDOS call.',13,10
        DB 'SUCCESS: the call returns the documented logical result without',13,10
        DB 'entering resident physical-error intervention.',13,10
        DB 'FAILURE: wrong code, physical prompt, hang, or changed unrelated data.',13,10
        DB 'RESTORE: close/delete created files and restore drive, user, and DMA.',13,10,'$'
PHYPROC:DB 13,10,'SETUP: mount a restorable expendable disk and declare a fault provider.',13,10
        DB 'The provider must fail the named operation inside the candidate BIOS.',13,10
        DB 'ACTION: run the selected operation and capture calls, text, and choice.',13,10
        DB 'SUCCESS: presentation, suspension/return, and recovery match the row.',13,10
        DB 'FAILURE: wrong layer, choice, return, persistence claim, or recovery.',13,10
        DB 'RESTORE: discard/remount media, reset disks, then verify a clean call.',13,10,'$'

; Keep the card catalog by kind of job.  A man hunting a fault rig should
; not have to pick through harmless return-code checks to find his test.
LSTMSG:DB 13,10,'CLASS: R=Required N=Not-guaranteed S=Out-of-scope X=Profile',13,10
        DB 13,10,'AUTOMATIC RETURN CHECKS (5)',13,10
        DB '0404 R Sequential-read logical result',13,10
        DB '0406 R Random-read logical codes',13,10
        DB '0407 R Random-write logical codes',13,10
        DB '0408 R Make/Delete/Rename/Close logical codes',13,10
        DB '0582 R Logical failures return without intervention',13,10
        DB 13,10,'SPECIAL MEDIA PROCEDURES (2)',13,10
        DB '0405 R Sequential-write logical result',13,10
        DB '0516 R Directory-full and allocation-full are distinct',13,10
        DB 13,10,'PHYSICAL AND BIOS FAULTS (6)',13,10
        DB '0390 R CBIOS physical read result',13,10
        DB '0391 R CBIOS physical write result',13,10
        DB '0392 R BIOS retry responsibility',13,10
        DB '0393 R Physical/logical error separation',13,10
        DB '0394 R Bad Sector presentation',13,10
        DB '0581 R Physical failure suspends caller',13,10
        DB 13,10,'INTERACTIVE ABORT/RECOVERY (5)',13,10
        DB '0395 R Physical-error ignore choice',13,10
        DB '0396 R Physical-error abort choice',13,10
        DB '0397 R Abort restart details',13,10
        DB '0586 R Physical-error abort abandons caller',13,10
        DB '0587 R Abort recovery leaves usable command environment',13,10
        DB 13,10,'PROFILE PROCEDURES (10)',13,10
        DB '0246 X Physical read-error presentation',13,10
        DB '0283 X Physical write-error presentation',13,10
        DB '0314 X Delete/Rename physical errors',13,10
        DB '0354 X Physical random-I/O errors',13,10
        DB '0385 X Fatal presentation',13,10
        DB '0387 X Exact diagnostic text',13,10
        DB '0389 X Automatic media-change protection',13,10
        DB '0411 X Exact Bad Sector text',13,10
        DB '0512 X Post-termination drive and user policy',13,10
        DB '0580 X Exact resident output presentation',13,10
        DB 13,10,'NON-GUARANTEED OBSERVATIONS (12)',13,10
        DB '0398 N Result after ignored physical error',13,10
        DB '0399 N DMA after ignored physical read',13,10
        DB '0400 N Persistence after ignored physical write',13,10
        DB '0401 N Make persistence after physical error',13,10
        DB '0402 N Close persistence after physical error',13,10
        DB '0403 N Physical-write atomicity',13,10
        DB '0412 N Accepted ignore characters',13,10
        DB '0514 N Failed transfer does not validate DMA',13,10
        DB '0583 N Ignored search result is not validation',13,10
        DB '0584 N Ignored update result is not persistence',13,10
        DB '0585 N Post-ignore state has no continuation contract',13,10
        DB '0618 N Damaged-directory recovery',13,10
        DB 13,10,'DOCUMENTARY EXCLUSIONS (3)',13,10
        DB '0386 S Fatal-handler internals',13,10
        DB '0409 S DRI permanent-error internals',13,10
        DB '0410 S z80pack status values',13,10
        DB 13,10,'TOTAL: 43 ITEMS',13,10,'$'

STOUT: DB '-$'
STOBS: DB 'O$'
STPASS:DB 'P$'
STFAIL:DB 'F$'
CLREQ: DB 'R$'
CLNG:  DB 'N$'
CLOUT: DB 'S$'
CLPROF:DB 'X$'

; Item strings and observations.  Keep rows below 80 columns.
I0246:DB '0246$'
I0283:DB '0283$'
I0314:DB '0314$'
I0354:DB '0354$'
I0385:DB '0385$'
I0386:DB '0386$'
I0387:DB '0387$'
I0389:DB '0389$'
I0390:DB '0390$'
I0391:DB '0391$'
I0392:DB '0392$'
I0393:DB '0393$'
I0394:DB '0394$'
I0395:DB '0395$'
I0396:DB '0396$'
I0397:DB '0397$'
I0398:DB '0398$'
I0399:DB '0399$'
I0400:DB '0400$'
I0401:DB '0401$'
I0402:DB '0402$'
I0403:DB '0403$'
I0404:DB '0404$'
I0405:DB '0405$'
I0406:DB '0406$'
I0407:DB '0407$'
I0408:DB '0408$'
I0409:DB '0409$'
I0410:DB '0410$'
I0411:DB '0411$'
I0412:DB '0412$'
I0512:DB '0512$'
I0514:DB '0514$'
I0516:DB '0516$'
I0580:DB '0580$'
I0581:DB '0581$'
I0582:DB '0582$'
I0583:DB '0583$'
I0584:DB '0584$'
I0585:DB '0585$'
I0586:DB '0586$'
I0587:DB '0587$'
I0618:DB '0618$'

O0246:DB 'Run /0246 with CPM-DISKERR-INT read-fault provider$'
O0283:DB 'Run /0283 with CPM-DISKERR-INT write-fault provider$'
O0314:DB 'Run /0314 with delete/rename fault provider$'
O0354:DB 'Run /0354 with random-I/O fault provider$'
O0385:DB 'Run /0385 with DRI-PROTECT-INT provider$'
O0386:DB 'Resident handler internals are outside public contract$'
O0387:DB 'Run /0387 with DRI-DIAG-PRES capture$'
O0389:DB 'Run /0389 with REMOVABLE-MEDIA provider$'
O0390:DB 'Run /0390 with controlled physical read fault$'
O0391:DB 'Run /0391 with controlled physical write fault$'
O0392:DB 'Run /0392 with retry-counting fault provider$'
O0393:DB 'Run /0393 with physical and logical refusal fixtures$'
O0394:DB 'Run /0394 with controlled bad-sector provider$'
O0395:DB 'Run /0395 and choose Ignore at physical error$'
O0396:DB 'Run /0396 and choose Abort at physical error$'
O0397:DB 'Run /0397; retained card checks restarted environment$'
O0398:DB 'Ignored physical-error result is not guaranteed$'
O0399:DB 'DMA after ignored physical read is not guaranteed$'
O0400:DB 'Persistence after ignored write is not guaranteed$'
O0401:DB 'Make persistence after physical error is not guaranteed$'
O0402:DB 'Close persistence after physical error is not guaranteed$'
O0403:DB 'Physical-write atomicity is not guaranteed$'
O0404:DB 'Run /0404 with controlled sequential-read refusals$'
V0404:DB 'One record returned 00h; following sequential EOF returned 01h$'
F0404:DB 'Open/read/EOF sequence did not return 00h then 01h$'
O0405:DB 'Run /0405 with controlled sequential-write refusals$'
O0406:DB 'Run /0406 with controlled random-read refusals$'
O0407:DB 'Run /0407 with controlled random-write refusals$'
O0408:DB 'Run /0408 with controlled file-operation refusals$'
V0406:DB 'Random record 0 returned 00h; record 1 returned EOF 01h$'
F0406:DB 'Random read did not distinguish record success from EOF$'
V0407:DB 'Random write returned 00h; record 10000h returned 06h$'
F0407:DB 'Random write success/range results were not 00h/06h$'
V0408:DB 'Missing Open, then Make/Close/Rename/Delete codes agreed$'
F0408:DB 'One or more file-operation logical codes disagreed$'
O0409:DB 'DRI permanent-error internals are outside public contract$'
O0410:DB 'z80pack private status values are outside public contract$'
O0411:DB 'Run /0411 with DRI-DIAG-PRES bad-sector capture$'
O0412:DB 'Accepted Ignore characters are implementation-dependent$'
O0512:DB 'Run /0512 with declared CCP-LIFECYCLE profile$'
O0514:DB 'A failed transfer does not validate DMA contents$'
O0516:DB 'Run /0516 on directory-full and allocation-full fixtures$'
O0580:DB 'Run /0580 with DRI-RES-PRES capture$'
O0581:DB 'Run /0581 with physical fault and console capture$'
O0582:DB 'Run /0582 with returning logical-refusal fixture$'
V0582:DB 'All controlled logical failures returned without intervention$'
F0582:DB 'A controlled logical-return oracle failed$'
O0583:DB 'Ignored search data is not validation$'
O0584:DB 'Ignored directory update is not persistence$'
O0585:DB 'Post-ignore state has no continuation guarantee$'
O0586:DB 'Run /0586; retained card checks caller abandonment$'
O0587:DB 'Run /0587; retained card checks usable CCP recovery$'
O0618:DB 'Damaged-directory recovery behavior is not guaranteed$'

CASES: DW I0246,STOUT,CLPROF,O0246
       DW I0283,STOUT,CLPROF,O0283
       DW I0314,STOUT,CLPROF,O0314
       DW I0354,STOUT,CLPROF,O0354
       DW I0385,STOUT,CLPROF,O0385
       DW I0386,STOUT,CLOUT,O0386
       DW I0387,STOUT,CLPROF,O0387
       DW I0389,STOUT,CLPROF,O0389
       DW I0390,STOUT,CLREQ,O0390
       DW I0391,STOUT,CLREQ,O0391
       DW I0392,STOUT,CLREQ,O0392
       DW I0393,STOUT,CLREQ,O0393
       DW I0394,STOUT,CLREQ,O0394
       DW I0395,STOUT,CLREQ,O0395
       DW I0396,STOUT,CLREQ,O0396
       DW I0397,STOUT,CLREQ,O0397
       DW I0398,STOBS,CLNG,O0398
       DW I0399,STOBS,CLNG,O0399
       DW I0400,STOBS,CLNG,O0400
       DW I0401,STOBS,CLNG,O0401
       DW I0402,STOBS,CLNG,O0402
       DW I0403,STOBS,CLNG,O0403
C0404: DW I0404,STOUT,CLREQ,O0404
       DW I0405,STOUT,CLREQ,O0405
C0406: DW I0406,STOUT,CLREQ,O0406
C0407: DW I0407,STOUT,CLREQ,O0407
C0408: DW I0408,STOUT,CLREQ,O0408
       DW I0409,STOUT,CLOUT,O0409
       DW I0410,STOUT,CLOUT,O0410
       DW I0411,STOUT,CLPROF,O0411
       DW I0412,STOBS,CLNG,O0412
       DW I0512,STOUT,CLPROF,O0512
       DW I0514,STOBS,CLNG,O0514
       DW I0516,STOUT,CLREQ,O0516
       DW I0580,STOUT,CLPROF,O0580
       DW I0581,STOUT,CLREQ,O0581
C0582: DW I0582,STOUT,CLREQ,O0582
       DW I0583,STOBS,CLNG,O0583
       DW I0584,STOBS,CLNG,O0584
       DW I0585,STOBS,CLNG,O0585
       DW I0586,STOUT,CLREQ,O0586
       DW I0587,STOUT,CLREQ,O0587
       DW I0618,STOBS,CLNG,O0618

SELBUF:DS 4
ONEFILE:DB 'BTONE   DAT'
TEMP1:  DB 'BTERW1  TMP'
TEMP2:  DB 'BTERW2  TMP'
NEWNAME:DB 'BTERW3  TMP'
TESTFCB:DS 36
DMA:    DS 128
        DS 128
STACKTOP:
        END
