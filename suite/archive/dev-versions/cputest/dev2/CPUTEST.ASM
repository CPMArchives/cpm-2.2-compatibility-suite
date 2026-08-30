;***********************************************************************
;*                                                                     *
;*               C P U T E S T   --   RELEASE DEV2                    *
;*                                                                     *
;*          BETTER CP/M 8080 PROCESSOR EXERCISE PROGRAM                *
;*                                                                     *
;***********************************************************************
;
; Version 0.1.0-dev2 - period-style programmer's commentary
;
; ASSEMBLY: M80 IN .Z80 MODE.  ONLY 8080 OPERATIONS ARE USED.
; LOAD AT:  0100H
;
;------------------------- PROGRAMMER'S NOTES --------------------------
;
; This is not a factory processor diagnostic.  It proves the small machine
; on which the rest of the suite must stand, then tries three flag corners
; which a quick interpreter can miss.  The checks are short on purpose: a
; sick stack or CALL cannot be trusted to run a long diagnostic or print a
; useful complaint.  A clean return to the CCP is therefore part of 0623.
;
; No Z80 instruction is smuggled into the generic claim.  Z80 extensions,
; undocumented opcodes, clock rates and interrupt wiring have their ledger
; rows, but no portable CP/M program may turn them into requirements.
;
; The two live cards alter their own table entries.  Each begins '-' and
; replaces the status and report pointers only after its complete check has
; returned, with either the good or bad signature.  Thus /ALL prints one
; common deck, while /0623 and /0624 use the same test and report machinery.
;
;***********************************************************************

        ORG     0100H
BDOS    EQU     0005H
NCASES  EQU     5

START:  LD      SP,STACKTOP
        LD      HL,0000H
        PUSH    HL              ; bottom return enters page-zero warm boot
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

;------------------------ DECODE COMMAND TAIL -------------------------
; Exit: A=1 HELP, 2 LIST, 3 ALL, 4 NUMBER, 5 INFO, 8 SAFE.
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

; Make the signatures before printing.  Their results are pointers planted
; in C0623 and C0624, not a second private set of flags.
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

; Each card occupies ten bytes.  Compare the four decimal digits in place;
; once found, only the two returning cards have code to call.
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

;--------------------------- PRINT A ROW -------------------------------
; HL -> four words: item, status, class and report.
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

; Compare two pointer words.  The summary wants to know whether each card
; still names STPASS; it need not inspect the printed character.
CMPEQ: LD      A,L
        CP      E
        RET     NZ
        LD      A,H
        CP      D
        RET

;------------------------- BASIC SIGNATURE -----------------------------
; Register transfer, ALU, memory, stack and CALL/RET form the suite's floor.
; 5AH is carried through B and memory, 1357H through the stack into DE, and
; A5H through a real subroutine.  Different patterns keep one stuck bit from
; satisfying every part of the card by accident.
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
; This little routine is intentionally real, rather than folded into T0623.
; The CALL must stack the proper return and RET must find it again.
SUBTEST:
        LD      A,0A5H
        LD      (CELL),A
        RET

;--------------------------- FLAG CORNERS ------------------------------
; SUB makes FFH and sets carry.  ADC A,0 must consume that carry, producing
; 00H while setting carry once more.  The zero test is made before INC, since
; INC changes Z; the carry test is made both before and after INC to prove
; that INR did not borrow the carry latch for its own work.
;
; The final 09H+09H is chosen because the binary sum 12H is wrong as packed
; decimal.  DAA must turn it into 18H.  No flag-testing instruction is placed
; between the operation and the branch which judges that operation.
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
HLPMSG:DB 13,10,'CPUTEST 0.1.0-dev2',13,10,13,10
        DB '  CPUTEST /NNNN  Run or explain one ledger item',13,10
        DB '  CPUTEST /ALL   Run checks and report all items',13,10
        DB '  CPUTEST /SAFE  Run checks requiring no destructive media',13,10
        DB '  CPUTEST /LIST  List ledger items by useful group',13,10
        DB '  CPUTEST /H     Show this help',13,10
        DB '  CPUTEST /INFO  Show build information',13,10,'$'
INFMSG:DB 13,10,'BetterCP/M CPUTEST 0.1.0-dev2',13,10
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

; Four display pointers and one procedure pointer make each ten-byte card.
; The two labelled cards are self-modified by their returning checks.
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
