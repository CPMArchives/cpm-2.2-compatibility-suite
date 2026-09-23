; SPDX-License-Identifier: GPL-2.0-or-later

; ********************************************************************************
; *                   CP/M 2.2 Conformance Suite -- CPUTEST                     *
; *                                                                              *
; * Establishes the portable 8080 processor floor on which the remainder of the *
; * suite depends, then exercises selected flag corners while keeping Z80-only   *
; * extensions, undocumented opcodes, timing, and interrupt wiring outside the  *
; * generic CP/M conformance claim.                                              *
; ********************************************************************************

  ; Version 0.1.0-dev6 - period-style programmer's commentary

  ; ASSEMBLY: ZSM4, THEN DIGITAL RESEARCH LINK.  ONLY 8080 OPERATIONS ARE USED.
  ; LOAD AT:  0100H

  ; PROGRAMMER'S NOTES
  ; ------------------
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

  ; LINK establishes the CP/M transient load address at 0100h.
BDOS    EQU     0005H
NCASES  EQU     5

; ================================================================================
; =                              Command Interface                               =
; =                                                                              =
; = Parses help, list, information, aggregate, safe, group, range, and numeric   =
; = selectors for the compact processor conformance catalog.                     =
; ================================================================================

START:  LD      SP,STACKTOP             ; enter CPUTEST command dispatcher
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
        JP      Z,RUNAUTOMATIC
        LD      DE,SGAUTO
        CALL    ARGIS
        JP      Z,RUNAUTOMATIC
        LD      DE,SGOBS
        CALL    ARGIS
        JP      Z,RUNOBSERVATION
        LD      DE,SGEXCL
        CALL    ARGIS
        JP      Z,RUNEXCLUSIONS
        LD      DE,SGMAN
        CALL    ARGIS
        JP      Z,MANUALLIST
        CALL    ITEMARG
        JP      Z,RUNONE

BADCOMMAND:                             ; report invalid command
        LD      DE,BADSEL
        JP      PUTS

; -------------------------------------------------------------------------------
; Command Argument Parser
; -------------------------------------------------------------------------------

  ; Exit: A=1 HELP, 2 LIST, 3 ALL, 4 NUMBER, 5 INFO, 8 SAFE.

GETARG:XOR     A                        ; parse command argument
        LD      (ARGBUF),A
        LD      A,(0080H)
        OR      A
        RET     Z
        LD      B,A
        LD      HL,0081H

GASKIP:LD      A,(HL)                   ; gaskip
        CP      ' '
        JP      NZ,GACOPY
        INC     HL
        DEC     B
        JP      NZ,GASKIP
        XOR     A
        RET

GACOPY:LD      DE,ARGBUF                ; gacopy

GALOOP:LD      A,B                      ; galoop
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

GASTORE:                                ; gastore
        LD      (DE),A
        INC     DE
        INC     HL
        DEC     B
        JP      GALOOP

GATRAIL:                                ; gatrail
        INC     HL
        DEC     B

GATRL2:LD      A,B                      ; gatrl2
        OR      A
        JP      Z,GADONE
        LD      A,(HL)
        CP      ' '
        JP      NZ,GABAD
        INC     HL
        DEC     B
        JP      GATRL2

GADONE:XOR     A                        ; gadone
        LD      (DE),A
        CP      A
        RET

GABAD: OR      1                        ; gabad
        RET

ARGIS: LD      HL,ARGBUF                ; argis

AICMP: LD      A,(DE)                   ; aicmp
        CP      (HL)
        RET     NZ
        OR      A
        RET     Z
        INC     DE
        INC     HL
        JP      AICMP

; -------------------------------------------------------------------------------
; Numeric Selector
; -------------------------------------------------------------------------------

ITEMARG:                                ; parse numeric item selector
        XOR     A
        LD      (REPORTMODE),A
        LD      HL,ARGBUF
        LD      A,(HL)
        CP      '/'
        RET     NZ
        INC     HL
        LD      DE,SELBUF
        LD      B,4

IACOPY:LD      A,(HL)                   ; iacopy
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

IARPT: LD      A,(DE)                   ; iarpt
        CP      (HL)
        JP      NZ,IABAD
        OR      A
        JP      Z,IAROK
        INC     DE
        INC     HL
        JP      IARPT

IAROK: LD      A,1                      ; iarok
        LD      (REPORTMODE),A
        XOR     A
        RET

IABAD: OR      1                        ; iabad
        RET

; -------------------------------------------------------------------------------
; Help and Information Commands
; -------------------------------------------------------------------------------

HELP:  LD      DE,HLPMSG                ; display command help
        JP      PUTS

LIST:  LD      DE,LSTMSG                ; display catalog list
        JP      PUTS

INFO:  LD      DE,INFMSG                ; display suite information
        JP      PUTS

VERSION:LD     DE,VERMSG                ; display suite version
        JP      PUTS

GROUPLIST:LD   DE,GRPLIST               ; display functional groups
        JP      PUTS

MANUALLIST:LD  DE,MANLIST               ; display manual exclusions
        JP      PUTS

; ================================================================================
; =                       Catalog Execution and Selection                        =
; =                                                                              =
; = Runs automatic, observation, exclusion, range, or single-item views while    =
; = allowing the two live returning cards to update their own catalog result     =
; = pointers.                                                                    =
; ================================================================================
; -------------------------------------------------------------------------------
; Aggregate Run
; -------------------------------------------------------------------------------

  ; Make the signatures before printing.  Their results are pointers planted
  ; in C0623 and C0624, not a second private set of flags.

RUNALL:CALL    T0623                    ; run complete catalog
        CALL    T0624
        CALL    PRINTHEAD
        LD      HL,CASES
        LD      B,NCASES

RALP:  PUSH    BC                       ; ralp
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
        JP      SUMOUT

SUMBAD:LD      DE,SUMFAIL               ; sumbad

SUMOUT:CALL    PUTS                     ; sumout
        JP      PRINTFAILS

RUNAUTOMATIC:                           ; run automatic processor checks
        CALL    T0623
        CALL    T0624
        LD      HL,CASES
        LD      B,2
        LD      DE,SUMAUTO
        PUSH    HL
        LD      HL,(C0623+2)
        PUSH    DE
        LD      DE,STPASS
        CALL    CMPEQ
        POP     DE
        JP      NZ,RAFAIL
        LD      HL,(C0624+2)
        PUSH    DE
        LD      DE,STPASS
        CALL    CMPEQ
        POP     DE
        JP      Z,RAREADY

RAFAIL:LD      DE,SUMAUTOF              ; rafail

RAREADY:POP    HL                       ; raready
        JP      RUNRANGE

RUNOBSERVATION:                         ; run observation rows
        LD      HL,CASES+20
        LD      B,1
        LD      DE,SUMOBS
        JP      RUNRANGE

RUNEXCLUSIONS:                          ; run exclusion rows
        LD      HL,CASES+30
        LD      B,2
        LD      DE,SUMEXCL

; -------------------------------------------------------------------------------
; Range Selection
; -------------------------------------------------------------------------------

RUNRANGE:                               ; run catalog range
        PUSH    DE
        PUSH    BC
        PUSH    HL
        CALL    PRINTHEAD
        POP     HL
        POP     BC

RRLOOP: PUSH    BC                      ; rrloop
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

PRINTFAILS:                             ; printfails
        XOR     A
        LD      (PFANY),A
        LD      HL,CASES
        LD      B,2

PFLP:  PUSH    BC                       ; pflp
        PUSH    HL
        INC     HL
        INC     HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      DE,STFAIL
        CALL    CMPEQ
        POP     HL
        JP      NZ,PFNEXT
        LD      A,(PFANY)
        OR      A
        JP      NZ,PFITEM
        INC     A
        LD      (PFANY),A
        LD      DE,FAILMSG
        CALL    PUTS

PFITEM:LD      E,(HL)                   ; pfitem
        INC     HL
        LD      D,(HL)
        CALL    PUTS
        LD      DE,FSPACE
        CALL    PUTS
        DEC     HL

PFNEXT:LD      DE,10                    ; pfnext
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,PFLP
        LD      A,(PFANY)
        OR      A
        RET     Z
        LD      DE,CRLF
        JP      PUTS

; -------------------------------------------------------------------------------
; Single-Item Selection
; -------------------------------------------------------------------------------

  ; Each card occupies ten bytes.  Compare the four decimal digits in place;
  ; once found, only the two returning cards have code to call.

RUNONE:LD      HL,CASES                 ; run one catalog item
        LD      B,NCASES

RONXT: PUSH    BC                       ; ronxt
        PUSH    HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      DE,SELBUF
        LD      B,4

ROCMP: LD      A,(DE)                   ; rocmp
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
        LD      A,(REPORTMODE)
        OR      A
        JP      Z,ROSHORT
        LD      DE,8
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        CALL    PUTS

ROSHORT:                                ; roshort
        LD      DE,ONESUM
        JP      PUTS

RONOM: POP     HL                       ; ronom
        LD      DE,10
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RONXT
        LD      DE,BADSEL
        JP      PUTS

; ================================================================================
; =                              Catalog Reporting                               =
; =                                                                              =
; = Prints the fixed-width processor result table and compares live result       =
; = pointers when building aggregate summaries.                                  =
; ================================================================================
; -------------------------------------------------------------------------------
; Result Table
; -------------------------------------------------------------------------------

PRINTHEAD:                              ; print result heading
        LD      DE,HEADMSG
        JP      PUTS

  ; HL -> four words: item, status, class and report.

PRINTROW:                               ; print catalog row
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

PUTFIELD:                               ; print fixed-width field
        PUSH    HL
        EX      DE,HL

PFCHR: LD      A,(HL)                   ; pfchr
        CP      '$'
        JP      Z,PFDONE
        PUSH    HL
        LD      E,A
        LD      C,2
        CALL    BDOS
        POP     HL
        INC     HL
        JP      PFCHR

PFDONE:POP     HL                       ; pfdone
        RET

PUTS:  PUSH    HL                       ; print $-terminated string
        LD      C,9
        CALL    BDOS
        POP     HL
        RET

  ; Compare two pointer words.  The summary wants to know whether each card
  ; still names STPASS; it need not inspect the printed character.

CMPEQ: LD      A,L                      ; compare pointer words
        CP      E
        RET     NZ
        LD      A,H
        CP      D
        RET

; ================================================================================
; =                        Basic 8080 Processor Signature                        =
; =                                                                              =
; = Exercises register transfer, ALU, memory, stack, CALL, and RET with distinct =
; = bit patterns so one stuck value cannot satisfy every part of the signature.  =
; ================================================================================
; -------------------------------------------------------------------------------
; Basic Signature
; -------------------------------------------------------------------------------

  ; Register transfer, ALU, memory, stack and CALL/RET form the suite's floor.
  ; 5AH is carried through B and memory, 1357H through the stack into DE, and
  ; A5H through a real subroutine.  Different patterns keep one stuck bit from
  ; satisfying every part of the card by accident.

T0623: LD      A,05AH                   ; run basic 8080 signature
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

F0623X:LD      HL,STFAIL                ; f0623x
        LD      (C0623+2),HL
        LD      HL,F0623
        LD      (C0623+6),HL
        RET

; -------------------------------------------------------------------------------
; CALL/RET Subtest
; -------------------------------------------------------------------------------

  ; This little routine is intentionally real, rather than folded into T0623.
  ; The CALL must stack the proper return and RET must find it again.

SUBTEST:                                ; exercise CALL and RET
        LD      A,0A5H
        LD      (CELL),A
        RET

; ================================================================================
; =                          8080 Flag-Corner Signature                          =
; =                                                                              =
; = Exercises carry propagation through SUB and ADC, carry preservation across   =
; = INR, and packed-decimal correction by DAA without disturbing the flags       =
; = before judgment.                                                             =
; ================================================================================
; -------------------------------------------------------------------------------
; Flag Corners
; -------------------------------------------------------------------------------

  ; SUB makes FFH and sets carry.  ADC A,0 must consume that carry, producing
  ; 00H while setting carry once more.  The zero test is made before INC, since
  ; INC changes Z; the carry test is made both before and after INC to prove
  ; that INR did not borrow the carry latch for its own work.
  ;
  ; The final 09H+09H is chosen because the binary sum 12H is wrong as packed
  ; decimal.  DAA must turn it into 18H.  No flag-testing instruction is placed
  ; between the operation and the branch which judges that operation.

T0624: XOR     A                        ; run flag-corner signature
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

F0624X:LD      HL,STFAIL                ; f0624x
        LD      (C0624+2),HL
        LD      HL,F0624
        LD      (C0624+6),HL
        RET

; ================================================================================
; =                          Messages and Catalog Text                           =
; =                                                                              =
; = Defines command help, summaries, result markers, requirements, observations, =
; = and catalog display text used by CPUTEST.                                    =
; ================================================================================
; -------------------------------------------------------------------------------
; Text and Result Markers
; -------------------------------------------------------------------------------

HLPMSG:DB 13,10,'CPUTEST 0.1.0-dev6',13,10,13,10 ; hlpmsg
        DB '  CPUTEST /NNNN[:REPORT]      Run, explain, or report one item',13,10
        DB '  CPUTEST /ALL                Run checks and report all items',13,10
        DB '  CPUTEST /SAFE               Run checks requiring no destructive media',13,10
        DB '  CPUTEST /LIST               List ledger items by useful group',13,10
        DB '  CPUTEST /GROUP:LIST         List all available groupings',13,10
        DB '  CPUTEST /GROUP:name         Run a tool-specific group',13,10
        DB '                              (run /GROUP:LIST for available groups)',13,10
        DB '  CPUTEST /H, /HELP           Show concise command help',13,10
        DB '  CPUTEST /INFO               Show build information',13,10
        DB '  CPUTEST /VER, /VERSION      Show name and version',13,10,'$'

VERMSG:DB 13,10,'CPUTEST 0.1.0-dev6',13,10,'$' ; vermsg
INFMSG:DB 13,10,'CPUTEST 0.1.0-dev6',13,10 ; infmsg
        DB 'Catalog: CPU-001 through CPU-005 (5 rows)',13,10
        DB 'Implemented: CPU-001 through CPU-005; no rows remain',13,10
        DB 'Declared baseline: Intel 8080 instruction set',13,10
        DB 'No Z80 or undocumented opcode is required.',13,10,'$'

HEADMSG:DB 13,10,'STATUS: P=Pass F=Fail -=Not-run O=Observed',13,10 ; headmsg
        DB 'CLASS:  R=Required N=Not-guaranteed S=Out-of-scope',13,10
        DB 'ITEM  S  C  OBSERVED',13,10
        DB '----  -  -  -------------------------------------------------------------------',13,10,'$'

LSTMSG:DB 13,10,'CLASS: R=Required N=Not-guaranteed S=Out-of-scope',13,10 ; lstmsg
        DB 13,10,'AUTOMATIC (2)',13,10
        DB '  0623 R Intel 8080-compatible binary baseline',13,10
        DB '  0624 R Declared processor-profile semantics',13,10
        DB 13,10,'OBSERVATION (1)',13,10
        DB '  0626 N Undocumented processor behavior',13,10
        DB 13,10,'EXCLUSIONS (2)',13,10
        DB '  0625 S Z80 extensions outside generic CP/M claim',13,10
        DB '  0627 S Processor timing and interrupt topology',13,10
        DB 13,10,'TOTAL: 5 ITEMS',13,10,'$'

GRPLIST:DB 13,10,'CPUTEST GROUPS',13,10,13,10 ; grplist
        DB 'FUNCTIONAL',13,10
        DB '  AUTOMATIC    2  Returning Intel 8080 semantic checks',13,10
        DB '  OBSERVATION  1  Undocumented processor characterization',13,10
        DB '  EXCLUSIONS   2  Processor behavior outside generic CP/M',13,10
        DB 13,10,'UNIVERSAL',13,10
        DB '  REQUIRED     2  REQUIRED catalog items',13,10
        DB '  OBSERVATION  1  NOT GUARANTEED observations',13,10
        DB '  MANUAL       0  Manual procedures (lists only)',13,10,'$'

MANLIST:DB 13,10,'MANUAL PROCEDURES (0)',13,10 ; manlist
        DB 'None.',13,10,'$'

SUMAUTO:DB 'Summary: 2 pass, 0 fail, 0 error, 0 observed, 0 not-run',13,10,'$' ; sumauto
SUMAUTOF:DB 'Summary: processor oracle failed; see rows above',13,10,'$'
SUMOBS:DB 'Summary: 0 pass, 0 fail, 0 error, 1 observed, 0 not-run',13,10,'$' ; sumobs
SUMEXCL:DB 'Summary: 0 pass, 0 fail, 0 error, 0 observed, 2 not-run',13,10,'$' ; sumexcl
SUMOK: DB 'Summary: 2 pass, 0 fail, 0 error, 1 observed, 2 not-run',13,10 ; sumok
        DB '5 catalog items implemented; 0 remain to implement.',13,10,'$'

SUMFAIL:DB 'Summary: processor oracle failed; see rows above',13,10,'$'
FAILMSG:DB 'Failed items: $'            ; failmsg
FSPACE:DB ' $'                          ; fspace
ONESUM:DB 'Summary: selected row reported above.',13,10,'$' ; onesum
BADSEL:DB 13,10,'CPUTEST: unknown selector. Use CPUTEST /HELP.',13,10 ; badsel
        DB 'Use CPUTEST /GROUP:LIST for available groups.',13,10,'$'

SP2:   DB '  $'                         ; sp2
CRLF:  DB 13,10,'$'                     ; crlf

P0623:DB 13,10,'ACTION: run the register, ALU, memory, stack and CALL/RET card.',13,10 ; catalog data for item 623
        DB 'SUCCESS: every 8080 baseline signature agrees and control returns.',13,10
        DB 'FAILURE: a signature differs, the program traps, or the CCP is lost.',13,10,'$'

P0624:DB 13,10,'ACTION: test carry into ADC, INR carry preservation and DAA.',13,10 ; catalog data for item 624
        DB 'SUCCESS: FFH+carry wraps to 00H with carry; INR preserves carry;',13,10
        DB 'packed-decimal 09H+09H adjusts to 18H.',13,10,'$'

P0625:DB 13,10,'EXCLUSION: Z80 extensions may be offered by a declared profile, but',13,10 ; catalog data for item 625
        DB 'generic CP/M 2.2 compatibility neither requires nor forbids them.',13,10,'$'

P0626:DB 13,10,'OBSERVATION: undocumented opcodes, flags and aliases are processor-',13,10 ; catalog data for item 626
        DB 'specific and must not be used as portable conformance evidence.',13,10,'$'

P0627:DB 13,10,'EXCLUSION: clock rate, wait states, interrupt modes and daisy-chain',13,10 ; catalog data for item 627
        DB 'topology belong to a selected hardware profile, not generic CP/M.',13,10,'$'

I0623:DB '0623$'                        ; catalog data for item 623
I0624:DB '0624$'                        ; catalog data for item 624
I0625:DB '0625$'                        ; catalog data for item 625
I0626:DB '0626$'                        ; catalog data for item 626
I0627:DB '0627$'                        ; catalog data for item 627
STOUT: DB '-$'                          ; stout
STOBS: DB 'O$'                          ; stobs
STPASS:DB 'P$'                          ; stpass
STFAIL:DB 'F$'                          ; stfail
CLREQ: DB 'R$'                          ; clreq
CLNG:  DB 'N$'                          ; clng
CLOUT: DB 'S$'                          ; clout
O0623:DB 'Run 8080 binary-execution baseline$' ; catalog data for item 623
V0623:DB 'Register, ALU, memory, stack and CALL/RET signatures agreed$' ; catalog data for item 623
F0623:DB 'An 8080 binary-execution signature disagreed$' ; catalog data for item 623
O0624:DB 'Run declared 8080 instruction-semantics checks$' ; catalog data for item 624
V0624:DB 'ADC, INR carry preservation and DAA semantics agreed$' ; catalog data for item 624
F0624:DB 'An 8080 flag or decimal-adjust semantic disagreed$' ; catalog data for item 624
O0625:DB 'Z80 extensions are outside the generic CP/M claim$' ; catalog data for item 625
O0626:DB 'Undocumented processor behavior is not guaranteed$' ; catalog data for item 626
O0627:DB 'Timing and interrupt topology require a hardware profile$' ; catalog data for item 627

; ================================================================================
; =                     Processor Catalog and Working State                      =
; =                                                                              =
; = Defines the ten-byte case records, live procedure pointers, selector buffer, =
; = command strings, and the private transient stack.                            =
; ================================================================================
; -------------------------------------------------------------------------------
; Case Deck
; -------------------------------------------------------------------------------

  ; Four display pointers and one procedure pointer make each ten-byte card.
  ; The two labelled cards are self-modified by their returning checks.

CASES:                                  ; processor case catalog

C0623: DW I0623,STOUT,CLREQ,O0623,P0623 ; catalog data for item 623
C0624: DW I0624,STOUT,CLREQ,O0624,P0624 ; catalog data for item 624
       DW I0626,STOBS,CLNG,O0626,P0626
       DW I0625,STOUT,CLOUT,O0625,P0625
       DW I0627,STOUT,CLOUT,O0627,P0627

PFANY: DB 0                             ; pfany

SELBUF:DS 4                             ; selbuf
REPORTMODE:DB 0                         ; reportmode
ARGBUF:DS 32                            ; argbuf
SH:     DB '/H',0                       ; sh
SHELP:  DB '/HELP',0                    ; shelp
SLIST:  DB '/LIST',0                    ; slist
SALL:   DB '/ALL',0                     ; sall
SSAFE:  DB '/SAFE',0                    ; ssafe
SINFO:  DB '/INFO',0                    ; sinfo
SVER:   DB '/VER',0                     ; sver
SVERSION:DB '/VERSION',0                ; sversion
SGLIST: DB '/GROUP:LIST',0              ; sglist
SGREQ:  DB '/GROUP:REQUIRED',0          ; sgreq
SGAUTO: DB '/GROUP:AUTOMATIC',0         ; sgauto
SGOBS:  DB '/GROUP:OBSERVATION',0       ; sgobs
SGEXCL: DB '/GROUP:EXCLUSIONS',0        ; sgexcl
SGMAN:  DB '/GROUP:MANUAL',0            ; sgman
SREPORT:DB ':REPORT',0                  ; sreport
CELL:   DS 1                            ; cell
        DS 255

STACKTOP:                               ; top of private test stack
        END
