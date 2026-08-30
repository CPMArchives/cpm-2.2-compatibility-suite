;***********************************************************************
;*                                                                     *
;*               C P U T E S T   --   RELEASE DEV1                    *
;*                                                                     *
;*          BETTER CP/M 8080 PROCESSOR EXERCISE PROGRAM                *
;*                                                                     *
;***********************************************************************
;
; Version 0.1.0-dev1 - complete CPU-001 through CPU-005
;
; ASSEMBLY: M80 IN .Z80 MODE.  ONLY 8080 OPERATIONS ARE USED.
; LOAD AT:  0100H
;
; This is not a processor diagnostic in the factory sense.  It proves the
; small instruction foundation on which the suite itself stands, then tests
; several flag rules which a merely runnable binary might still get wrong.
; A broken CALL cannot report its own failure, of course; the clean return to
; the CCP is part of the card just as it was in the old memory exercisers.
;
; No Z80 instruction is smuggled into the generic claim.  Z80 extensions,
; undocumented opcodes, clock rates and interrupt wiring have their ledger
; rows, but no portable CP/M program may turn them into requirements.
;
;***********************************************************************

        ORG     0100H
BDOS    EQU     0005H
NCASES  EQU     5

START:  LD      SP,STACKTOP
        LD      HL,0000H
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
        CP      8
        JP      Z,RUNALL
        JP      HELP

; A=1 help, 2 list, 3 all, 4 number, 5 info, 8 safe.
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

RUNALL:CALL    T0623
        CALL    T0624
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
        LD      HL,(C0623+2)
        LD      DE,STPASS
        CALL    CMPEQ
        JP      NZ,SUMBAD
        LD      HL,(C0624+2)
        LD      DE,STPASS
        CALL    CMPEQ
        JP      NZ,SUMBAD
        LD      DE,SUMOK
        JP      PUTS
SUMBAD:LD      DE,SUMFAIL
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
        PUSH    HL
        LD      A,(SELBUF+3)
        CP      '3'
        CALL    Z,T0623
        LD      A,(SELBUF+3)
        CP      '4'
        CALL    Z,T0624
        POP     HL
        CALL    PRINTHEAD
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

PUTS:  PUSH    HL
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

; Register transfer, ALU, memory, stack and CALL/RET form the suite's floor.
T0623: LD      A,05AH
        LD      B,A
        XOR     00FH
        CP      055H
        JP      NZ,F0623X
        LD      A,B
        LD      (CELL),A
        XOR     A
        LD      A,(CELL)
        CP      05AH
        JP      NZ,F0623X
        LD      HL,1357H
        PUSH    HL
        LD      HL,0000H
        POP     DE
        LD      A,D
        CP      013H
        JP      NZ,F0623X
        LD      A,E
        CP      057H
        JP      NZ,F0623X
        XOR     A
        LD      (CELL),A
        CALL    SUBTEST
        LD      A,(CELL)
        CP      0A5H
        JP      NZ,F0623X
        LD      HL,STPASS
        LD      (C0623+2),HL
        LD      HL,V0623
        LD      (C0623+6),HL
        RET
F0623X:LD      HL,STFAIL
        LD      (C0623+2),HL
        LD      HL,F0623
        LD      (C0623+6),HL
        RET
SUBTEST:
        LD      A,0A5H
        LD      (CELL),A
        RET

; Flag corners catch many incomplete interpreters: carry into ADC, carry
; preservation across INR, and decimal adjust after packed-decimal addition.
T0624: XOR     A
        SUB     1
        JP      NC,F0624X
        ADC     A,0
        JP      NZ,F0624X
        JP      NC,F0624X
        INC     A
        JP      NC,F0624X
        CP      1
        JP      NZ,F0624X
        LD      A,09H
        ADD     A,09H
        DAA
        CP      018H
        JP      NZ,F0624X
        LD      HL,STPASS
        LD      (C0624+2),HL
        LD      HL,V0624
        LD      (C0624+6),HL
        RET
F0624X:LD      HL,STFAIL
        LD      (C0624+2),HL
        LD      HL,F0624
        LD      (C0624+6),HL
        RET

;------------------------------ TEXT ----------------------------------
HLPMSG:DB 13,10,'CPUTEST 0.1.0-dev1',13,10,13,10
        DB '  CPUTEST /NNNN  Run or explain one ledger item',13,10
        DB '  CPUTEST /ALL   Run checks and report all items',13,10
        DB '  CPUTEST /SAFE  Run checks requiring no destructive media',13,10
        DB '  CPUTEST /LIST  List ledger items by useful group',13,10
        DB '  CPUTEST /H     Show this help',13,10
        DB '  CPUTEST /INFO  Show build information',13,10,'$'
INFMSG:DB 13,10,'BetterCP/M CPUTEST 0.1.0-dev1',13,10
        DB 'Catalog: CPU-001 through CPU-005 (5 rows)',13,10
        DB 'Implemented: CPU-001 through CPU-005; no rows remain',13,10
        DB 'Declared baseline: Intel 8080 instruction set',13,10
        DB 'No Z80 or undocumented opcode is required.',13,10,'$'
HEADMSG:DB 13,10,'STATUS: P=Pass F=Fail -=Not-run O=Observed',13,10
        DB 'CLASS:  R=Required N=Not-guaranteed S=Out-of-scope',13,10
        DB 'ITEM  S  C  OBSERVED',13,10
        DB '----  -  -  -------------------------------------------------------------------',13,10,'$'
LSTMSG:DB 13,10,'CLASS: R=Required N=Not-guaranteed S=Out-of-scope',13,10
        DB 13,10,'AUTOMATIC 8080 CHECKS (2)',13,10
        DB '0623 R Intel 8080-compatible binary baseline',13,10
        DB '0624 R Declared processor-profile semantics',13,10
        DB 13,10,'NON-GUARANTEED OBSERVATION (1)',13,10
        DB '0626 N Undocumented processor behavior',13,10
        DB 13,10,'DOCUMENTARY EXCLUSIONS (2)',13,10
        DB '0625 S Z80 extensions outside generic CP/M claim',13,10
        DB '0627 S Processor timing and interrupt topology',13,10
        DB 13,10,'TOTAL: 5 ITEMS',13,10,'$'
SUMOK: DB 'Summary: 2 pass, 0 fail, 0 error, 1 observed, 2 not-run',13,10
        DB '5 catalog items implemented; 0 remain to implement.',13,10,'$'
SUMFAIL:DB 'Summary: processor oracle failed; see rows above',13,10,'$'
ONESUM:DB 'Summary: selected row reported above.',13,10,'$'
BADSEL:DB 13,10,'Unknown selector. Use CPUTEST /H.',13,10,'$'
SP2:   DB '  $'
CRLF:  DB 13,10,'$'

P0623:DB 13,10,'ACTION: run the register, ALU, memory, stack and CALL/RET card.',13,10
        DB 'SUCCESS: every 8080 baseline signature agrees and control returns.',13,10
        DB 'FAILURE: a signature differs, the program traps, or the CCP is lost.',13,10,'$'
P0624:DB 13,10,'ACTION: test carry into ADC, INR carry preservation and DAA.',13,10
        DB 'SUCCESS: FFH+carry wraps to 00H with carry; INR preserves carry;',13,10
        DB 'packed-decimal 09H+09H adjusts to 18H.',13,10,'$'
P0625:DB 13,10,'EXCLUSION: Z80 extensions may be offered by a declared profile, but',13,10
        DB 'generic CP/M 2.2 compatibility neither requires nor forbids them.',13,10,'$'
P0626:DB 13,10,'OBSERVATION: undocumented opcodes, flags and aliases are processor-',13,10
        DB 'specific and must not be used as portable conformance evidence.',13,10,'$'
P0627:DB 13,10,'EXCLUSION: clock rate, wait states, interrupt modes and daisy-chain',13,10
        DB 'topology belong to a selected hardware profile, not generic CP/M.',13,10,'$'

I0623:DB '0623$'
I0624:DB '0624$'
I0625:DB '0625$'
I0626:DB '0626$'
I0627:DB '0627$'
STOUT: DB '-$'
STOBS: DB 'O$'
STPASS:DB 'P$'
STFAIL:DB 'F$'
CLREQ: DB 'R$'
CLNG:  DB 'N$'
CLOUT: DB 'S$'
O0623:DB 'Run 8080 binary-execution baseline$'
V0623:DB 'Register, ALU, memory, stack and CALL/RET signatures agreed$'
F0623:DB 'An 8080 binary-execution signature disagreed$'
O0624:DB 'Run declared 8080 instruction-semantics checks$'
V0624:DB 'ADC, INR carry preservation and DAA semantics agreed$'
F0624:DB 'An 8080 flag or decimal-adjust semantic disagreed$'
O0625:DB 'Z80 extensions are outside the generic CP/M claim$'
O0626:DB 'Undocumented processor behavior is not guaranteed$'
O0627:DB 'Timing and interrupt topology require a hardware profile$'

CASES:
C0623: DW I0623,STOUT,CLREQ,O0623,P0623
C0624: DW I0624,STOUT,CLREQ,O0624,P0624
       DW I0625,STOUT,CLOUT,O0625,P0625
       DW I0626,STOBS,CLNG,O0626,P0626
       DW I0627,STOUT,CLOUT,O0627,P0627

SELBUF:DS 4
CELL:   DS 1
        DS 255
STACKTOP:
        END
