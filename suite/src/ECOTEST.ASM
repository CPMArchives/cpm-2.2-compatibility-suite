; SPDX-License-Identifier: GPL-2.0-or-later
;
;***********************************************************************
;*                                                                     *
;*               E C O T E S T   --   RELEASE DEV4                    *
;*                                                                     *
;*        BETTER CP/M CCP UTILITY ECOLOGY TEST PROGRAM                 *
;*                                                                     *
;***********************************************************************
;
; Version 0.1.0-dev5 - period-style programmer's commentary
;
; ASSEMBLY: ZSM4, THEN DIGITAL RESEARCH LINK.  ONLY 8080 OPERATIONS ARE USED.
; LOAD AT:  0100H
;
;------------------------- PROGRAMMER'S NOTES --------------------------
;
; Most of this ledger belongs to the command processor which loaded us.
; There is no honest way for a transient to call DIR, ERA, REN, SAVE or TYPE
; as subroutines.  Their cards therefore prescribe work at the prompt and
; stay '-' until the operator has the transcript.  Calling a convenient BDOS
; function here would test BDOS twice and never test the resident command.
;
; Item 0513 is the one returning card.  It purposely asks two unlike
; questions.  OPEN of ECOMISS.DAT must answer FFH; READ of the shipped
; one-record BTONE.DAT must answer 00H and then 01H.  This is a useful trap
; for systems which use one catch-all error answer for every file call.
;
; TESTFCB is cleared and filled afresh for each half, so a byte left by the
; failed OPEN cannot help the good OPEN.  The good file is closed even after
; a bad READ, and DMA is put back at 0080H on every return.  The close result
; is deliberately not part of this card; adding it would make a third oracle.
;
;***********************************************************************

; LINK establishes the CP/M transient load address at 0100h.
BDOS    EQU     0005H
NCASES  EQU     8

START:  LD      SP,STACKTOP
        LD      HL,0000H
        PUSH    HL              ; bottom return enters page-zero warm boot
        LD      A,(0080H)
        OR      A
        JP      Z,HELP
        CALL    GETARG
        JP      NZ,BADCOMMAND
        LD      DE,SH
        CALL    ARGIS
        JP      Z,HELP
        LD      DE,SHELP
        CALL    ARGIS
        JP      Z,HELP
        LD      DE,SLIST
        CALL    ARGIS
        JP      Z,LIST
        LD      DE,SALL
        CALL    ARGIS
        JP      Z,RUNALL
        LD      DE,SSAFE
        CALL    ARGIS
        JP      Z,RUNALL
        LD      DE,SINFO
        CALL    ARGIS
        JP      Z,INFO
        LD      DE,SVER
        CALL    ARGIS
        JP      Z,VERSION
        LD      DE,SVERSION
        CALL    ARGIS
        JP      Z,VERSION
        LD      DE,SGLIST
        CALL    ARGIS
        JP      Z,GROUPLIST
        LD      DE,SGREQ
        CALL    ARGIS
        JP      Z,RUNREQUIRED
        LD      DE,SGAUTO
        CALL    ARGIS
        JP      Z,RUNAUTOMATIC
        LD      DE,SGOBS
        CALL    ARGIS
        JP      Z,RUNOBSERVATION
        LD      DE,SGMAN
        CALL    ARGIS
        JP      Z,MANUALLIST
        CALL    ITEMARG
        JP      Z,RUNONE
BADCOMMAND:
        LD      DE,BADSEL
        JP      PUTS

;------------------------ DECODE COMMAND TAIL -------------------------
GETARG:XOR     A
        LD      (ARGBUF),A
        LD      A,(0080H)
        OR      A
        RET     Z
        LD      B,A
        LD      HL,0081H
GASKIP:LD      A,(HL)
        CP      ' '
        JP      NZ,GACOPY
        INC     HL
        DEC     B
        JP      NZ,GASKIP
        XOR     A
        RET
GACOPY:LD      DE,ARGBUF
GALOOP:LD      A,B
        OR      A
        JP      Z,GADONE
        LD      A,(HL)
        CP      ' '
        JP      Z,GATRAIL
        CP      'a'
        JP      C,GASTORE
        CP      'z'+1
        JP      NC,GASTORE
        SUB     20H
GASTORE:LD     (DE),A
        INC     DE
        INC     HL
        DEC     B
        JP      GALOOP
GATRAIL:INC    HL
        DEC     B
GATRL2:LD      A,B
        OR      A
        JP      Z,GADONE
        LD      A,(HL)
        CP      ' '
        JP      NZ,GABAD
        INC     HL
        DEC     B
        JP      GATRL2
GADONE:XOR     A
        LD      (DE),A
        CP      A
        RET
GABAD: OR      1
        RET

ARGIS: LD      HL,ARGBUF
AICMP: LD      A,(DE)
        CP      (HL)
        RET     NZ
        OR      A
        RET     Z
        INC     DE
        INC     HL
        JP      AICMP

ITEMARG:XOR    A
        LD      (REPORTMODE),A
        LD      HL,ARGBUF
        LD      A,(HL)
        CP      '/'
        RET     NZ
        INC     HL
        LD      DE,SELBUF
        LD      B,4
IACOPY:LD      A,(HL)
        CP      '0'
        JP      C,IABAD
        CP      '9'+1
        JP      NC,IABAD
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,IACOPY
        LD      A,(HL)
        OR      A
        RET     Z
        LD      DE,SREPORT
IARPT: LD      A,(DE)
        CP      (HL)
        JP      NZ,IABAD
        OR      A
        JP      Z,IAROK
        INC     DE
        INC     HL
        JP      IARPT
IAROK: LD      A,1
        LD      (REPORTMODE),A
        XOR     A
        RET
IABAD: OR      1
        RET

HELP:  LD      DE,HLPMSG
        JP      PUTS
LIST:  LD      DE,LSTMSG
        JP      PUTS
INFO:  LD      DE,INFMSG
        JP      PUTS
VERSION:LD     DE,VERMSG
        JP      PUTS
GROUPLIST:LD   DE,GRPLIST
        JP      PUTS
MANUALLIST:LD  DE,MANLIST
        JP      PUTS

; Run the sole returning oracle before printing the card deck.  The test
; changes its own status and report pointers in C0513.
RUNALL:CALL    T0513
        CALL    PRINTHEAD
        LD      HL,CASES
        LD      B,NCASES
RALP:  PUSH    BC
        PUSH    HL
        CALL    PRINTROW
        POP     HL
        LD      DE,10
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RALP
        LD      HL,(C0513+2)
        LD      DE,STPASS
        CALL    CMPEQ
        LD      DE,SUMOK
        JP      Z,RAOUT
        LD      DE,SUMFAIL
RAOUT:  CALL    PUTS
        JP      PRINTFAILS

RUNAUTOMATIC:
        CALL    T0513
        LD      HL,CASES
        LD      B,1
        LD      DE,SUMAUTO
        PUSH    HL
        PUSH    DE
        LD      HL,(C0513+2)
        LD      DE,STPASS
        CALL    CMPEQ
        POP     DE
        JP      Z,RAREADY
        LD      DE,SUMAUTOF
RAREADY:POP    HL
        JP      RUNRANGE

RUNREQUIRED:
        CALL    T0513
        LD      HL,CASES
        LD      B,5
        LD      DE,SUMREQ
        PUSH    HL
        PUSH    DE
        LD      HL,(C0513+2)
        LD      DE,STPASS
        CALL    CMPEQ
        POP     DE
        JP      Z,RRREADY
        LD      DE,SUMREQF
RRREADY:POP    HL
        JP      RUNRANGE

RUNOBSERVATION:
        LD      HL,CASES+50
        LD      B,3
        LD      DE,SUMOBS
RUNRANGE:
        PUSH    DE
        PUSH    BC
        PUSH    HL
        CALL    PRINTHEAD
        POP     HL
        POP     BC
RRLOOP: PUSH    BC
        PUSH    HL
        CALL    PRINTROW
        POP     HL
        LD      DE,10
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RRLOOP
        POP     DE
        CALL    PUTS
        JP      PRINTFAILS

PRINTFAILS:
        LD      HL,(C0513+2)
        LD      DE,STFAIL
        CALL    CMPEQ
        RET     NZ
        LD      DE,FAILMSG
        CALL    PUTS
        LD      DE,I0513
        CALL    PUTS
        LD      DE,CRLF
        JP      PUTS

; A card is ten bytes: four printable pointers followed by its procedure.
; The decimal selector is compared as text; leading zeroes are significant.
RUNONE:LD      HL,CASES
        LD      B,NCASES
RONXT: PUSH    BC
        PUSH    HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      DE,SELBUF
        LD      B,4
ROCMP: LD      A,(DE)
        CP      (HL)
        JP      NZ,RONOM
        INC     DE
        INC     HL
        DEC     B
        JP      NZ,ROCMP
        POP     HL
        POP     BC
        LD      DE,I0513
        LD      A,(SELBUF+1)
        CP      '5'
        JP      NZ,ROSHOW
        LD      A,(SELBUF+2)
        CP      '1'
        JP      NZ,ROSHOW
        LD      A,(SELBUF+3)
        CP      '3'
        JP      NZ,ROSHOW
        PUSH    HL
        CALL    T0513
        POP     HL
ROSHOW:CALL    PRINTHEAD
        PUSH    HL
        CALL    PRINTROW
        POP     HL
        LD      A,(REPORTMODE)
        OR      A
        JP      Z,ROSHORT
        LD      DE,8
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        CALL    PUTS
ROSHORT:
        LD      DE,ONESUM
        JP      PUTS
RONOM: POP     HL
        LD      DE,10
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RONXT
        LD      DE,BADSEL
        JP      PUTS

PRINTHEAD:
        LD      DE,HEADMSG
        JP      PUTS

;--------------------------- PRINT A ROW -------------------------------
; HL -> four words: item, status, class and report.  PUTFIELD preserves the
; table cursor while BDOS character output is allowed to use its registers.
PRINTROW:
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        CALL    PUTFIELD
        LD      DE,SP2
        CALL    PUTS
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        CALL    PUTFIELD
        LD      DE,SP2
        CALL    PUTS
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
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
        EX      DE,HL
PFCHR: LD      A,(HL)
        CP      '$'
        JP      Z,PFDONE
        PUSH    HL
        LD      E,A
        LD      C,2
        CALL    BDOS
        POP     HL
        INC     HL
        JP      PFCHR
PFDONE:POP     HL
        RET

PUTS:  PUSH    HL              ; BDOS owns working registers, table does not
        LD      C,9
        CALL    BDOS
        POP     HL
        RET

CMPEQ: LD      A,L
        CP      E
        RET     NZ
        LD      A,H
        CP      D
        RET

;-------------------- FUNCTION-SPECIFIC ORACLE ------------------------
; Missing OPEN and a genuine one-record stream deliberately exercise two
; different file functions.  No universal "disk error" value is assumed.
T0513: LD      HL,MISSNAM
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        CP      0FFH
        JP      NZ,T13FAIL
        LD      HL,ONENAME
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,15
        CALL    BDOS
        CP      0FFH
        JP      Z,T13FAIL
        LD      DE,DMA
        LD      C,26
        CALL    BDOS
        LD      DE,TESTFCB
        LD      C,20
        CALL    BDOS
        CP      0
        JP      NZ,T13CLOSE
        LD      DE,TESTFCB
        LD      C,20
        CALL    BDOS
        CP      1
        JP      NZ,T13CLOSE
        LD      HL,STPASS
        LD      (C0513+2),HL
        LD      HL,V0513
        LD      (C0513+6),HL
        JP      T13CLOSE
T13FAIL:
        LD      HL,STFAIL
        LD      (C0513+2),HL
        LD      HL,F0513
        LD      (C0513+6),HL
T13CLOSE:
        ; CLOSE may be asked to tidy a failed OPEN.  Its answer is immaterial;
        ; the point is to leave no live file behind before restoring DMA.
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        LD      DE,0080H
        LD      C,26
        CALL    BDOS
        RET

; Entry HL -> eleven blank-padded name bytes.  Clear all 36 bytes so extent,
; record and allocation state cannot leak from the preceding half of 0513.
INITFCB:
        PUSH    HL
        LD      DE,TESTFCB
        XOR     A
        LD      B,36
IFCLR: LD      (DE),A
        INC     DE
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

;------------------------------ TEXT ----------------------------------
HLPMSG:DB 13,10,'ECOTEST 0.1.0-dev5',13,10,13,10
        DB '  ECOTEST /NNNN[:REPORT]      Run, explain, or report one item',13,10
        DB '  ECOTEST /ALL                Run checks and report all items',13,10
        DB '  ECOTEST /SAFE               Run checks requiring no destructive media',13,10
        DB '  ECOTEST /LIST               List ledger items by useful group',13,10
        DB '  ECOTEST /GROUP:LIST         List all available groupings',13,10
        DB '  ECOTEST /GROUP:name         Run a tool-specific group',13,10
        DB '                              (run /GROUP:LIST for available groups)',13,10
        DB '  ECOTEST /H, /HELP           Show concise command help',13,10
        DB '  ECOTEST /INFO               Show build information',13,10
        DB '  ECOTEST /VER, /VERSION      Show name and version',13,10,'$'
VERMSG:DB 13,10,'ECOTEST 0.1.0-dev5',13,10,'$'
INFMSG:DB 13,10,'ECOTEST 0.1.0-dev5',13,10
        DB 'Catalog: ECO-001 through ECO-008 (8 rows)',13,10
        DB 'Implemented: ECO-001 through ECO-008; no rows remain',13,10
        DB 'Processor required: Intel 8080',13,10
        DB 'Resident-command rows require a CCP transcript.',13,10,'$'
HEADMSG:DB 13,10,'STATUS: P=Pass F=Fail -=Not-run O=Observed',13,10
        DB 'CLASS:  R=Required N=Not-guaranteed',13,10
        DB 'ITEM  S  C  OBSERVED',13,10
        DB '----  -  -  -------------------------------------------------------------------',13,10,'$'
LSTMSG:DB 13,10,'CLASS: R=Required N=Not-guaranteed',13,10
        DB 13,10,'AUTOMATIC (1)',13,10
        DB '  0513 R File-operation failures are function-specific',13,10
        DB 13,10,'MANUAL (4)',13,10
        DB '  0569 R Resident command semantic set',13,10
        DB '  0575 R SAVE page mapping',13,10
        DB '  0577 R TYPE byte-stream contract',13,10
        DB '  0579 R Ordinary resident-command recovery',13,10
        DB 13,10,'OBSERVATION (3)',13,10
        DB '  0515 N FCB state after operation failure',13,10
        DB '  0571 N DIR ordering and exact layout',13,10
        DB '  0573 N ERA read-only attribute is not protection',13,10
        DB 13,10,'TOTAL: 8 ITEMS',13,10,'$'
GRPLIST:DB 13,10,'ECOTEST GROUPS',13,10,13,10
        DB 'FUNCTIONAL',13,10
        DB '  AUTOMATIC    1  Returning file-operation check',13,10
        DB '  MANUAL       4  Resident-command procedures (lists only)',13,10
        DB '  OBSERVATION  3  Non-guaranteed CCP observations',13,10
        DB 13,10,'UNIVERSAL',13,10
        DB '  REQUIRED     5  REQUIRED catalog items',13,10
        DB '  OBSERVATION  3  NOT GUARANTEED observations',13,10
        DB '  MANUAL       4  Manual procedures (lists only)',13,10,'$'
MANLIST:DB 13,10,'MANUAL PROCEDURES (4)',13,10
        DB '  0569 R DIR, ERA, REN, SAVE, TYPE and USER semantic set',13,10
        DB '  0575 R SAVE one-page mapping',13,10
        DB '  0577 R TYPE byte-stream contract',13,10
        DB '  0579 R Resident-command error recovery',13,10
        DB 'Use ECOTEST /NNNN:REPORT for instructions.',13,10,'$'
SUMAUTO:DB 'Summary: 1 pass, 0 fail, 0 error, 0 observed, 0 not-run',13,10,'$'
SUMAUTOF:DB 'Summary: file-operation oracle failed; see row above',13,10,'$'
SUMREQ:DB 'Summary: 1 pass, 0 fail, 0 error, 0 observed, 4 not-run',13,10,'$'
SUMREQF:DB 'Summary: required oracle failed; 4 manual items not run',13,10,'$'
SUMOBS:DB 'Summary: 0 pass, 0 fail, 0 error, 3 observed, 0 not-run',13,10,'$'
SUMOK: DB 'Summary: 1 pass, 0 fail, 0 error, 3 observed, 4 not-run',13,10
        DB '8 catalog items implemented; 0 remain to implement.',13,10,'$'
SUMFAIL:DB 'Summary: file-operation oracle failed; see rows above',13,10,'$'
FAILMSG:DB 'Failed items: $'
ONESUM:DB 'Summary: selected row reported above.',13,10,'$'
BADSEL:DB 13,10,'ECOTEST: unknown selector. Use ECOTEST /HELP.',13,10
        DB 'Use ECOTEST /GROUP:LIST for available groups.',13,10,'$'
SP2:   DB '  $'
CRLF:  DB 13,10,'$'

P0513:DB 13,10,'SETUP: BTONE.DAT must be the shipped one-record fixture.',13,10
        DB 'ACTION: ECOTEST compares missing OPEN with record success and EOF.',13,10
        DB 'SUCCESS: OPEN=FFH and sequential READ returns 00H then 01H.',13,10
        DB 'RESTORE: the private FCB is closed and DMA is reset to 0080H.',13,10,'$'
P0515:DB 13,10,'OBSERVATION: after a failed precondition or operation, only the',13,10
        DB 'documented return value is evidence; do not infer preserved FCB fields.',13,10,'$'
P0569:DB 13,10,'SETUP: use a restorable disk with named files and free directory space.',13,10
        DB 'ACTION: exercise DIR, ERA, REN, SAVE, TYPE and USER at the CCP.',13,10
        DB 'SUCCESS: each command performs its documented semantic operation.',13,10
        DB 'FAILURE: a command is absent, mis-parsed, or performs another action.',13,10
        DB 'RESTORE: erase test files and restore the original drive and user.',13,10,'$'
P0571:DB 13,10,'OBSERVATION: DIR visibility is testable; ordering, columns, spacing,',13,10
        DB 'pagination and exact layout are not portable requirements.',13,10,'$'
P0573:DB 13,10,'OBSERVATION: the FCB read-only attribute does not establish access',13,10
        DB 'control. ERA behavior must not be promoted to a protection contract.',13,10,'$'
P0575:DB 13,10,'SETUP: reserve ECOSAVE.COM on an expendable disk.',13,10
        DB 'ACTION: enter SAVE 1 ECOSAVE.COM, then inspect the saved file.',13,10
        DB 'SUCCESS: it contains exactly one 256-byte page beginning at 0100H.',13,10
        DB 'RESTORE: erase ECOSAVE.COM.',13,10,'$'
P0577:DB 13,10,'SETUP: make a file containing known graphic, CR/LF and control bytes.',13,10
        DB 'ACTION: TYPE the file while capturing the console byte stream.',13,10
        DB 'SUCCESS: TYPE consumes and emits the file as a byte stream; presentation',13,10
        DB 'effects belong to the console and are not substituted file bytes.',13,10
        DB 'RESTORE: erase the fixture.',13,10,'$'
P0579:DB 13,10,'SETUP: reserve missing source/target names on a restorable disk.',13,10
        DB 'ACTION: give DIR, ERA, REN, SAVE and TYPE ordinary bad operands.',13,10
        DB 'SUCCESS: each command reports failure and returns a usable CCP prompt.',13,10
        DB 'FAILURE: hang, warm-boot loop, lost command environment, or disk damage.',13,10
        DB 'RESTORE: remove any test files and reset the disk system.',13,10,'$'

I0513:DB '0513$'
I0515:DB '0515$'
I0569:DB '0569$'
I0571:DB '0571$'
I0573:DB '0573$'
I0575:DB '0575$'
I0577:DB '0577$'
I0579:DB '0579$'
STOUT: DB '-$'
STOBS: DB 'O$'
STPASS:DB 'P$'
STFAIL:DB 'F$'
CLREQ: DB 'R$'
CLNG:  DB 'N$'

O0513:DB 'Run safe function-specific failure oracle$'
V0513:DB 'Missing OPEN=FFh; sequential READ returned 00h then EOF 01h$'
F0513:DB 'Function-specific OPEN/READ results disagreed$'
O0515:DB 'Failed-operation FCB state has no general guarantee$'
O0569:DB 'Run resident command semantic-set transcript$'
O0571:DB 'DIR ordering and exact layout are not guaranteed$'
O0573:DB 'Read-only attribute is not a protection contract$'
O0575:DB 'Run SAVE one-page mapping transcript$'
O0577:DB 'Run TYPE byte-stream transcript$'
O0579:DB 'Run ordinary resident-command recovery transcript$'

; Four display words and one procedure word make each ten-byte card.  C0513
; is labelled because the returning oracle replaces two of its pointers.
CASES:
C0513: DW I0513,STOUT,CLREQ,O0513,P0513
       DW I0569,STOUT,CLREQ,O0569,P0569
       DW I0575,STOUT,CLREQ,O0575,P0575
       DW I0577,STOUT,CLREQ,O0577,P0577
       DW I0579,STOUT,CLREQ,O0579,P0579
       DW I0515,STOBS,CLNG,O0515,P0515
       DW I0571,STOBS,CLNG,O0571,P0571
       DW I0573,STOBS,CLNG,O0573,P0573

MISSNAM:DB 'ECOMISS DAT'
ONENAME:DB 'BTONE   DAT'
SELBUF: DS 4
REPORTMODE:DB 0
ARGBUF:DS 32
SH:     DB '/H',0
SHELP:  DB '/HELP',0
SLIST:  DB '/LIST',0
SALL:   DB '/ALL',0
SSAFE:  DB '/SAFE',0
SINFO:  DB '/INFO',0
SVER:   DB '/VER',0
SVERSION:DB '/VERSION',0
SGLIST: DB '/GROUP:LIST',0
SGREQ:  DB '/GROUP:REQUIRED',0
SGAUTO: DB '/GROUP:AUTOMATIC',0
SGOBS:  DB '/GROUP:OBSERVATION',0
SGMAN:  DB '/GROUP:MANUAL',0
SREPORT:DB ':REPORT',0
TESTFCB:DS 36
DMA:    DS 128
        DS 128
STACKTOP:
        END
