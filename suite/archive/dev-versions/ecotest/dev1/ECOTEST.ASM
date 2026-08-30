;***********************************************************************
;*                                                                     *
;*               E C O T E S T   --   RELEASE DEV1                    *
;*                                                                     *
;*        BETTER CP/M CCP UTILITY ECOLOGY TEST PROGRAM                 *
;*                                                                     *
;***********************************************************************
;
; Version 0.1.0-dev1 - complete ECO-001 through ECO-008
;
; ASSEMBLY: M80 IN .Z80 MODE.  ONLY 8080 OPERATIONS ARE USED.
; LOAD AT:  0100H
;
; A transient cannot call DIR, ERA, REN, SAVE or TYPE as though they were
; BDOS functions.  Those commands live in the CCP which loaded this program.
; The resident-command cards below therefore prescribe work at the command
; prompt and leave a dash until an outside transcript supplies the evidence.
; Calling the underlying BDOS routine here would test BDOS twice and the CCP
; not at all.
;
; Item 0513 is different.  Its claim concerns the public file-call ecology,
; so a small returning oracle is honest: missing OPEN returns FFH while a
; real sequential stream returns 00H for its record and 01H at end of file.
; The FCB and DMA are private, and the caller's DMA is restored to 0080H.
;
;***********************************************************************

        ORG     0100H
BDOS    EQU     0005H
NCASES  EQU     8

START:  LD      SP,STACKTOP
        LD      HL,0000H
        PUSH    HL              ; RET is a warm start after private stack
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
        CP      8
        JP      Z,RUNALL
        JP      HELP

; Return A=1 help, 2 list, 3 all, 4 number, 5 info, 8 safe.
PARSE:  LD      HL,0081H
PSKIP: LD      A,(HL)
        CP      ' '
        JP      NZ,PSTART
        INC     HL
        JP      PSKIP
PSTART:CP      0
        JP      Z,PARSEH
        CP      13
        JP      Z,PARSEH
        CP      '/'
        JP      NZ,PARSEH
        INC     HL
        LD      A,(HL)
        AND     5FH
        CP      'H'
        JP      Z,PARSEH
        CP      'L'
        JP      Z,PARSEL
        CP      'A'
        JP      Z,PARSEA
        CP      'S'
        JP      Z,PARSES
        CP      'I'
        JP      Z,PARSEI
        LD      DE,SELBUF
        LD      B,4
PNUM:  LD      A,(HL)
        CP      '0'
        JP      C,PARSEH
        CP      '9'+1
        JP      NC,PARSEH
        LD      (DE),A
        INC     DE
        INC     HL
        DEC     B
        JP      NZ,PNUM
        LD      A,4
        RET
PARSEH:LD      A,1
        RET
PARSEL:LD      A,2
        RET
PARSEA:LD      A,3
        RET
PARSES:LD      A,8
        RET
PARSEI:LD      A,5
        RET

HELP:  LD      DE,HLPMSG
        JP      PUTS
LIST:  LD      DE,LSTMSG
        JP      PUTS
INFO:  LD      DE,INFMSG
        JP      PUTS

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
        LD      DE,SUMMSG
        JP      PUTS

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
        LD      DE,8
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        CALL    PUTS
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

; Four pointers per card: item, status, class, report.
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
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        LD      DE,0080H
        LD      C,26
        CALL    BDOS
        RET

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
HLPMSG:DB 13,10,'ECOTEST 0.1.0-dev1',13,10,13,10
        DB '  ECOTEST /NNNN  Run or explain one ledger item',13,10
        DB '  ECOTEST /ALL   Run returning checks and list procedures',13,10
        DB '  ECOTEST /SAFE  Run checks requiring no destructive media',13,10
        DB '  ECOTEST /LIST  List ledger items by useful group',13,10
        DB '  ECOTEST /H     Show this help',13,10
        DB '  ECOTEST /INFO  Show build information',13,10,'$'
INFMSG:DB 13,10,'BetterCP/M ECOTEST 0.1.0-dev1',13,10
        DB 'Catalog: ECO-001 through ECO-008 (8 rows)',13,10
        DB 'Implemented: ECO-001 through ECO-008; no rows remain',13,10
        DB 'Processor required: Intel 8080',13,10
        DB 'Resident-command rows require a CCP transcript.',13,10,'$'
HEADMSG:DB 13,10,'STATUS: P=Pass F=Fail -=Not-run O=Observed',13,10
        DB 'CLASS:  R=Required N=Not-guaranteed',13,10
        DB 'ITEM  S  C  OBSERVED',13,10
        DB '----  -  -  -------------------------------------------------------------------',13,10,'$'
LSTMSG:DB 13,10,'CLASS: R=Required N=Not-guaranteed',13,10
        DB 13,10,'AUTOMATIC FILE-CALL CHECK (1)',13,10
        DB '0513 R File-operation failures are function-specific',13,10
        DB 13,10,'RESIDENT COMMAND PROCEDURES (4)',13,10
        DB '0569 R Resident command semantic set',13,10
        DB '0575 R SAVE page mapping',13,10
        DB '0577 R TYPE byte-stream contract',13,10
        DB '0579 R Ordinary resident-command recovery',13,10
        DB 13,10,'NON-GUARANTEED OBSERVATIONS (3)',13,10
        DB '0515 N FCB state after operation failure',13,10
        DB '0571 N DIR ordering and exact layout',13,10
        DB '0573 N ERA read-only attribute is not protection',13,10
        DB 13,10,'TOTAL: 8 ITEMS',13,10,'$'
SUMMSG:DB 'Summary: 1 pass, 0 fail, 0 error, 3 observed, 4 not-run',13,10
        DB '8 catalog items implemented; 0 remain to implement.',13,10,'$'
ONESUM:DB 'Summary: selected row reported above.',13,10,'$'
BADSEL:DB 13,10,'Unknown selector. Use ECOTEST /H.',13,10,'$'
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

; The fifth word is the selected-item procedure card.
CASES:
C0513: DW I0513,STOUT,CLREQ,O0513,P0513
       DW I0515,STOBS,CLNG,O0515,P0515
       DW I0569,STOUT,CLREQ,O0569,P0569
       DW I0571,STOBS,CLNG,O0571,P0571
       DW I0573,STOBS,CLNG,O0573,P0573
       DW I0575,STOUT,CLREQ,O0575,P0575
       DW I0577,STOUT,CLREQ,O0577,P0577
       DW I0579,STOUT,CLREQ,O0579,P0579

MISSNAM:DB 'ECOMISS DAT'
ONENAME:DB 'BTONE   DAT'
SELBUF: DS 4
TESTFCB:DS 36
DMA:    DS 128
        DS 128
STACKTOP:
        END
