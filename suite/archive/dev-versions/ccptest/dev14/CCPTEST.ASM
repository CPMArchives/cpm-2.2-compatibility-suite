; BetterCP/M executable conformance suite - CCPTEST
; Version 0.1.0-dev14 - name SCRATCH profile for manual disk procedures
; Intel 8080 instruction subset; accepted by z80asm and CP/M M80 in .Z80 mode.

        ORG     0100H
BDOS    EQU     0005H
NCASES  EQU     59

START:  LD      HL,0
        ADD     HL,SP
        LD      (ENTRYSP),HL
        LD      SP,STACKTOP
        LD      HL,0
        PUSH    HL
        CALL    PARSE
        CP      1
        JP      Z,HELP
        CP      2
        JP      Z,LIST
        CP      3
        JP      Z,RUNSET
        CP      4
        JP      Z,RUNSET
        CP      5
        JP      Z,RUNONE
        CP      6
        JP      Z,HRESULTS
        CP      7
        JP      Z,HPROFILES
        CP      8
        JP      Z,INFO
        LD      DE,BADSEL
        CALL    PUTS
        RET

; A=1 help, 2 list, 3 safe, 4 all, 5 numeric selector.
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
        LD      DE,0
        EX      DE,HL
        LD      (ITEMNO),HL
        EX      DE,HL
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
PARSEHX:INC    HL
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
        CALL    PUTS
        RET
LIST:  LD      DE,LSTMSG
        CALL    PUTS
        RET
INFO:  LD      DE,INFMSG
        CALL    PUTS
        RET
HRESULTS:LD    DE,RESMSG
        CALL    PUTS
        RET
HPROFILES:LD   DE,PRFMSG
        CALL    PUTS
        RET

RUNSET:LD      (RUNMODE),A
        CALL    BEGIN
        LD      HL,CASES
        LD      B,NCASES
RSLOOP:PUSH    BC
        PUSH    HL
        CALL    RUNENT
        POP     HL
        LD      DE,9
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RSLOOP
        JP      SUMMARY

RUNONE:XOR     A
        LD      (RUNMODE),A
        LD      HL,CASES
        LD      B,NCASES
ROLOOP:LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        PUSH    HL
        LD      HL,(ITEMNO)
        LD      A,H
        CP      D
        JP      NZ,RONEXT
        LD      A,L
        CP      E
        POP     HL
        JP      Z,ROFOUND
        JP      ROADV
RONEXT:POP     HL
ROADV: LD      DE,7
        ADD     HL,DE
        DEC     B
        JP      NZ,ROLOOP
        LD      DE,BADSEL
        CALL    PUTS
        RET
ROFOUND:DEC    HL
        DEC     HL
        PUSH    HL
        CALL    BEGIN
        POP     HL
        CALL    RUNENT
        JP      SUMMARY

BEGIN: XOR     A
        LD      (PASSCT),A
        LD      (FAILCT),A
        LD      (OBSCT),A
        LD      DE,HEADER
        JP      PUTS

; Entry: item, probe, observation, record, class.
; Class 0 REQUIRED, 1 NOT GUARANTEED, 2 MANUAL REQUIRED,
; 3 PROFILE REQUIRED, 4 selected REQUIRED, 5 selected PROFILE, 6 OUTSIDE,
; 7 manual NOT GUARANTEED.
RUNENT:LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        EX      DE,HL
        LD      (CURITEM),HL
        EX      DE,HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        EX      DE,HL
        LD      (PROCPTR),HL
        EX      DE,HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        EX      DE,HL
        LD      (OBSPTR),HL
        EX      DE,HL
        INC     HL
        INC     HL
        LD      A,(HL)
        CP      7
        JP      Z,MANGROW
        CP      6
        JP      Z,OOSROW
        CP      5
        JP      Z,SELPROF
        CP      4
        JP      Z,SELREQ
        CP      3
        JP      Z,PRFROW
        CP      2
        JP      Z,MANROW
        CP      1
        JP      NZ,RUNREQ
        LD      A,(RUNMODE)
        CP      3
        RET     Z
        LD      HL,(PROCPTR)
        CALL    CALLHL
        OR      A
        JP      NZ,OBSFAIL
        LD      A,(PASSCT)
        INC     A
        LD      (PASSCT),A
        LD      A,(OBSCT)
        INC     A
        LD      (OBSCT),A
        LD      DE,SOBS
        JP      ROWOUT
OBSFAIL:LD     A,(FAILCT)
        INC     A
        LD      (FAILCT),A
        LD      DE,SOBFAIL
        JP      ROWOUT
RUNREQ:LD      HL,(PROCPTR)
        CALL    CALLHL
        OR      A
        JP      NZ,ROWFAIL
        LD      A,(PASSCT)
        INC     A
        LD      (PASSCT),A
        LD      DE,SPASS
        JP      ROWOUT
ROWFAIL:LD     A,(FAILCT)
        INC     A
        LD      (FAILCT),A
        LD      DE,SFAIL
        JP      ROWOUT
OOSROW:LD      HL,OOSOBS
        LD      (OBSPTR),HL
        LD      DE,SOOS
        JP      ROWOUT
MANROW:LD      DE,SMAN
        CALL    ROWOUT
        LD      A,(RUNMODE)
        OR      A
        RET     NZ
        JP      MANDETAIL
MANGROW:LD     DE,SMANG
        CALL    ROWOUT
        LD      A,(RUNMODE)
        OR      A
        RET     NZ
        JP      MANDETAIL
PRFROW:LD      DE,SPROF
        CALL    ROWOUT
        LD      A,(RUNMODE)
        OR      A
        RET     NZ
        JP      MANDETAIL
SELREQ:LD      A,(RUNMODE)
        OR      A
        JP      Z,RUNREQ
        LD      DE,SSEL
        JP      ROWOUT
SELPROF:LD     A,(RUNMODE)
        OR      A
        JP      NZ,SELPROW
        LD      HL,(PROCPTR)
        CALL    CALLHL
        OR      A
        JP      NZ,SELPRF
        LD      A,(PASSCT)
        INC     A
        LD      (PASSCT),A
        LD      DE,SPPASS
        JP      ROWOUT
SELPRF:LD      A,(FAILCT)
        INC     A
        LD      (FAILCT),A
        LD      DE,SPFAIL
        JP      ROWOUT
SELPROW:LD     DE,SPROF
        JP      ROWOUT
ROWOUT:PUSH    DE
        CALL    PUTITEM
        LD      DE,TWO
        CALL    PUTS
        POP     DE
        CALL    PUTS
        LD      HL,(OBSPTR)
        EX      DE,HL
        CALL    PUTS
        LD      DE,CRLF
        JP      PUTS
CALLHL:JP      (HL)

; Numeric selection of a manual row prints the complete operator procedure.
; Aggregate runs retain one compact row per item.
MANDETAIL:LD   HL,MANTAB
        LD      B,33
MDLOOP:LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        PUSH    HL
        LD      HL,(CURITEM)
        LD      A,H
        CP      D
        JP      NZ,MDNEXT
        LD      A,L
        CP      E
        POP     HL
        JP      Z,MDFOUND
        INC     HL
        INC     HL
        DEC     B
        JP      NZ,MDLOOP
        RET
MDNEXT:POP     HL
        INC     HL
        INC     HL
        DEC     B
        JP      NZ,MDLOOP
        RET
MDFOUND:LD     E,(HL)
        INC     HL
        LD      D,(HL)
        CALL    PUTS
        LD      HL,(CURITEM)
        LD      DE,25
        CALL    CMPEQ
        OR      A
        JP      Z,MDTERM26
        LD      HL,(CURITEM)
        LD      DE,28
        CALL    CMPEQ
        OR      A
        JP      Z,MDTERM27
        LD      HL,(CURITEM)
        RET
MDTERM26:LD    DE,MDGO26
        CALL    MDPAUSE
        JP      0000H
MDTERM27:LD    DE,MDGO27
        CALL    MDPAUSE
        LD      HL,(ENTRYSP)
        LD      SP,HL
        RET
MDTERM95:JP    0000H
MDPAUSE:CALL   PUTS
        LD      C,1
        CALL    BDOS
        LD      DE,CRLF
        JP      PUTS
PUTCHARS:LD    E,(HL)
        INC     HL
        PUSH    HL
        PUSH    BC
        LD      C,2
        CALL    BDOS
        POP     BC
        POP     HL
        DEC     B
        JP      NZ,PUTCHARS
        RET

; --- Entry and page-zero probes -----------------------------------------
P0002: JP      P0001
P0004: LD      HL,(0006H)
        LD      DE,STACKTOP
        LD      A,H
        CP      D
        JP      C,FAILRET
        JP      NZ,PASS0
        LD      A,L
        CP      E
        JP      C,FAILRET
        XOR     A
        RET
P0007: LD      A,(0004H)
        CP      16
        JP      NC,FAILRET
        XOR     A
        RET
P0019: LD      A,(0080H)
        OR      A
        JP      Z,FAILRET
        LD      A,(0081H)
        CP      ' '
        JP      NZ,FAILRET
        XOR     A
        RET
P0010: LD      A,(0005H)
        CP      0C3H
        JP      NZ,FAILRET
        LD      A,(005CH)
        CP      17
        JP      NC,FAILRET
        LD      A,(0080H)
        OR      A
        JP      Z,FAILRET
        XOR     A
        RET
P0013: LD      HL,CO13FAIL
        LD      (OBSPTR),HL
        LD      HL,006CH
        LD      A,(HL)
        CP      2
        JP      NZ,FAILRET
        INC     HL
        LD      DE,FCB13
        LD      B,11
        CALL    CMPMEM
        OR      A
        RET     NZ
        LD      HL,CO13PASS
        LD      (OBSPTR),HL
        XOR     A
        RET
POBS:  XOR     A
        RET
P0001: LD      HL,START
        LD      DE,0100H
        JP      CMPEQ
P0003: JP      P0001
P0005: LD      A,(0000H)
        CP      0C3H
        JP      RETCMP
P0006: LD      HL,0003H
        LD      DE,0003H
        JP      CMPEQ
P0008: LD      A,(0005H)
        CP      0C3H
        JP      RETCMP
P0009: CALL    P0005
        OR      A
        RET     NZ
        JP      P0008
P0011: LD      HL,005CH
        LD      DE,005CH
        JP      CMPEQ
P0012: LD      HL,006CH
        LD      DE,FCB12
        LD      B,12
        JP      CMPMEM
P0014: LD      HL,006CH
        LD      DE,FCB14
        LD      B,12
        JP      CMPMEM
P0015: LD      HL,006CH
        LD      DE,FCB15
        LD      B,12
        JP      CMPMEM
P0017: LD      A,(0080H)
        CP      128
        JP      NC,FAILRET
        XOR     A
        RET
P0018: LD      A,(0080H)
        OR      A
        JP      Z,FAILRET
        LD      A,(0081H)
        CP      ' '
        JP      RETCMP
P0020: LD      A,(0080H)
        LD      B,A
        LD      HL,0081H
P20LP: LD      A,(HL)
        CP      'a'
        JP      C,P20NEXT
        CP      'z'+1
        JP      C,FAILRET
P20NEXT:INC    HL
        DEC     B
        JP      NZ,P20LP
        XOR     A
        RET
P0021: LD      A,(0080H)
        LD      L,A
        LD      H,0
        LD      DE,0081H
        ADD     HL,DE
        LD      A,(HL)
        LD      HL,DIAGTAIL
        LD      (OBSPTR),HL
        LD      DE,9
        ADD     HL,DE
        CALL    HEXMEM
        XOR     A
        RET

; Search First observes that the entry DMA remains 0080h.
P0023: LD      HL,0080H
        LD      B,128
        LD      A,0A5H
        CALL    FILL
        LD      DE,WILDFCB
        LD      C,17
        CALL    BDOS
        CP      0FFH
        JP      Z,FAILRET
        LD      L,A
        LD      H,0
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        LD      DE,0080H
        ADD     HL,DE
        LD      A,(HL)
        CP      0A5H
        JP      Z,FAILRET
        XOR     A
        RET
P0024: JP      P0023
P0537: LD      C,12
        CALL    BDOS
        CP      22H
        JP      RETCMP
P0589: LD      HL,(0006H)
        LD      DE,ENDPROG
        LD      A,H
        CP      D
        JP      C,FAILRET
        JP      NZ,PASSRET
        LD      A,L
        CP      E
        JP      C,FAILRET
PASSRET:XOR    A
        RET

; The final byte of this COM image must have been loaded below the BDOS base.
PLOAD: LD      A,(LOADMARK)
        CP      0A5H
        JP      NZ,FAILRET
        LD      HL,(0006H)
        LD      DE,IMAGEEND
        LD      A,H
        CP      D
        JP      C,FAILRET
        JP      NZ,PASSRET
        LD      A,L
        CP      E
        JP      C,FAILRET
        XOR     A
        RET

; Public vector and disk-parameter probes are read-only.
P0598: JP      P0005
P0599: LD      C,31
        CALL    BDOS
        LD      A,H
        OR      L
        JP      Z,FAILRET
        XOR     A
        RET

; IOBYTE probes restore the entry value. Toggling only bit zero also proves
; that the other assignment fields can be preserved.
P0608: LD      A,(0003H)
        LD      B,A
        XOR     1
        LD      (0003H),A
        LD      C,A
        LD      A,(0003H)
        CP      C
        PUSH    AF
        LD      A,B
        LD      (0003H),A
        POP     AF
        JP      RETCMP
P0609: JP      P0608
P0610: LD      A,(0003H)
        LD      B,A
        XOR     1
        LD      (0003H),A
        XOR     B
        LD      C,A
        LD      A,B
        LD      (0003H),A
        LD      A,C
        CP      1
        JP      RETCMP
P0613: JP      P0599

; Function 40 uses a reserved scratch file. Cleanup restores DMA 0080h and
; deletes the file on every returning path.
P0602: JP      P40COMMON
P0603: JP      P40COMMON
P0605: JP      P40COMMON
P40COMMON:LD   HL,F40INIT
        LD      DE,F40FCB
        LD      B,36
        CALL    COPYMEM
        LD      DE,F40FCB
        LD      C,19
        CALL    BDOS
        LD      DE,F40FCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        JP      Z,P40FAIL
        LD      HL,F40DMA
        LD      B,128
        LD      A,0A5H
        CALL    FILL
        LD      DE,F40DMA
        LD      C,26
        CALL    BDOS
        LD      A,2
        LD      (F40FCB+33),A
        XOR     A
        LD      (F40FCB+34),A
        LD      (F40FCB+35),A
        LD      DE,F40FCB
        LD      C,40
        CALL    BDOS
        OR      A
        JP      NZ,P40FAIL
        XOR     A
        LD      (F40FCB+33),A
        LD      DE,F40FCB
        LD      C,33
        CALL    BDOS
        OR      A
        JP      NZ,P40FAIL
        LD      HL,F40DMA
        LD      B,128
P40ZERO:LD     A,(HL)
        OR      A
        JP      NZ,P40FAIL
        INC     HL
        DEC     B
        JP      NZ,P40ZERO
        LD      A,1
        LD      (F40FCB+33),A
        LD      DE,F40FCB
        LD      C,33
        CALL    BDOS
        OR      A
        JP      NZ,P40FAIL
        LD      HL,F40DMA
        LD      B,128
P40ZER2:LD     A,(HL)
        OR      A
        JP      NZ,P40FAIL
        INC     HL
        DEC     B
        JP      NZ,P40ZER2
        CALL    P40CLEAN
        XOR     A
        RET
P40FAIL:CALL   P40CLEAN
        JP      FAILRET
P40CLEAN:LD    DE,0080H
        LD      C,26
        CALL    BDOS
        LD      DE,F40FCB
        LD      C,19
        JP      BDOS

P0614: LD      C,31
        CALL    BDOS
        LD      DE,2
        ADD     HL,DE
        LD      C,(HL)
        INC     HL
        LD      A,1
P14SH: DEC     C
        JP      M,P14MASK
        ADD     A,A
        JP      P14SH
P14MASK:DEC    A
        CP      (HL)
        JP      NZ,FAILRET
        INC     HL
        INC     HL
        LD      A,(HL)
        INC     HL
        OR      (HL)
        JP      Z,FAILRET
        INC     HL
        LD      A,(HL)
        INC     HL
        OR      (HL)
        JP      Z,FAILRET
        XOR     A
        RET
P0615: JP      P0617

; Act as a conforming direct-structure caller. Locate SELDSK and SECTRAN from
; the public BIOS jump table, select the already-current disk, follow the DPH
; to its DPB, compare that pointer with BDOS Function 31, validate core DPB
; fields, and exercise the active translation pointer. No disk data is changed.
P0617: LD      C,25
        CALL    BDOS
        LD      C,A
        LD      HL,(0001H)
        LD      DE,24
        ADD     HL,DE
        LD      E,0
        CALL    CALLHL
        LD      A,H
        OR      L
        JP      Z,FAILRET
        LD      (DPHPTR),HL
        LD      DE,10
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      (DPBPTR),HL
        LD      C,31
        CALL    BDOS
        EX      DE,HL
        LD      HL,(DPBPTR)
        CALL    CMPEQ
        OR      A
        RET     NZ
        LD      HL,(DPBPTR)
        LD      A,(HL)
        INC     HL
        OR      (HL)
        JP      Z,FAILRET
        INC     HL
        LD      A,(HL)
        CP      8
        JP      NC,FAILRET
        INC     HL
        LD      A,(HL)
        OR      A
        JP      Z,FAILRET
        INC     HL
        INC     HL
        LD      A,(HL)
        INC     HL
        OR      (HL)
        JP      Z,FAILRET
        INC     HL
        LD      A,(HL)
        INC     HL
        OR      (HL)
        JP      Z,FAILRET
        LD      HL,(0001H)
        LD      DE,45
        ADD     HL,DE
        LD      (BIOPTR),HL
        LD      HL,(DPHPTR)
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        LD      BC,0
        LD      HL,(BIOPTR)
        CALL    CALLHL
        XOR     A
        RET

; --- Diagnostic observations -------------------------------------------
P0032: LD      HL,O0032
        LD      (OBSPTR),HL
        XOR     A
        RET
P0033: LD      HL,O0033
        LD      (OBSPTR),HL
        XOR     A
        RET
P0511: LD      HL,O0511
        LD      (OBSPTR),HL
        XOR     A
        RET
P0533: LD      HL,O0533
        LD      (OBSPTR),HL
        XOR     A
        RET
P0539: LD      HL,DIAGSP
        LD      (OBSPTR),HL
        LD      DE,3
        ADD     HL,DE
        LD      A,(ENTRYSP+1)
        CALL    HEXMEM
        LD      A,(ENTRYSP)
        CALL    HEXMEM
        XOR     A
        RET

CMPEQ: LD      A,H
        CP      D
        JP      NZ,FAILRET
        LD      A,L
        CP      E
RETCMP:JP      NZ,FAILRET
PASS0: XOR     A
        RET
CMPMEM:LD     A,(DE)
        CP      (HL)
        JP      NZ,FAILRET
        INC     DE
        INC     HL
        DEC     B
        JP      NZ,CMPMEM
        XOR     A
        RET
COPYMEM:LD    A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,COPYMEM
        RET
FAILRET:LD     A,1
        RET

FILL:  LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,FILL
        RET
HEXMEM:PUSH    AF
        RRCA
        RRCA
        RRCA
        RRCA
        AND     0FH
        CALL    NIBMEM
        POP     AF
        AND     0FH
NIBMEM:CP      10
        JP      C,NMDIG
        ADD     A,'A'-10
        JP      NMHAVE
NMDIG: ADD     A,'0'
NMHAVE:LD      (HL),A
        INC     HL
        RET

SUMMARY:LD     DE,SUM1
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
        JP      PUTS

PUTITEM:LD     HL,(CURITEM)
        LD      DE,1000
        LD      B,0
PI1:   OR      A
        CALL    SUBHLDE
        JP      C,PI1D
        INC     B
        JP      PI1
PI1D:  ADD     HL,DE
        LD      A,B
        PUSH    HL
        CALL    PUTDIG
        POP     HL
        LD      DE,100
        LD      B,0
PI2:   OR      A
        CALL    SUBHLDE
        JP      C,PI2D
        INC     B
        JP      PI2
PI2D:  ADD     HL,DE
        LD      A,B
        PUSH    HL
        CALL    PUTDIG
        POP     HL
        LD      DE,10
        LD      B,0
PI3:   OR      A
        CALL    SUBHLDE
        JP      C,PI3D
        INC     B
        JP      PI3
PI3D:  ADD     HL,DE
        LD      A,B
        PUSH    HL
        CALL    PUTDIG
        POP     HL
        LD      A,L
        JP      PUTDIG
SUBHLDE:LD     A,L
        SUB     E
        LD      L,A
        LD      A,H
        SBC     A,D
        LD      H,A
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
PUTS:  LD      C,9
        JP      BDOS

CASES:
        DW 2,P0002,CO0002,CR0002
        DB 0
        DW 4,P0004,CO0004,CR0004
        DB 0
        DW 7,P0007,CO0007,CR0007
        DB 0
        DW 10,P0010,CO0010,CR0010
        DB 0
        DW 13,P0013,CO0013,CR0013
        DB 4
        DW 16,POBS,CO0016,CR0016
        DB 1
        DW 19,P0019,CO0019,CR0019
        DB 0
        DW 22,POBS,OOSOBS,CR0022
        DB 6
        DW 25,POBS,CO0025,CR0025
        DB 2
        DW 28,POBS,CO0028,CR0028
        DB 2
        DW 31,POBS,CO0031,CR0031
        DB 1
        DW 474,POBS,CO0474,CR0474
        DB 1
        DW 475,POBS,CO0475,CR0475
        DB 2
        DW 476,POBS,CO0476,CR0476
        DB 1
        DW 477,POBS,CO0477,CR0477
        DB 2
        DW 478,POBS,CO0478,CR0478
        DB 3
        DW 479,POBS,CO0479,CR0479
        DB 2
        DW 480,POBS,CO0480,CR0480
        DB 2
        DW 481,POBS,CO0481,CR0481
        DB 2
        DW 482,POBS,CO0482,CR0482
        DB 2
        DW 483,POBS,CO0483,CR0483
        DB 2
        DW 484,POBS,CO0484,CR0484
        DB 2
        DW 485,POBS,CO0485,CR0485
        DB 2
        DW 486,POBS,CO0486,CR0486
        DB 2
        DW 487,POBS,CO0487,CR0487
        DB 2
        DW 488,POBS,CO0488,CR0488
        DB 2
        DW 489,POBS,CO0489,CR0489
        DB 2
        DW 490,POBS,CO0490,CR0490
        DB 3
        DW 491,POBS,OOSOBS,CR0491
        DB 6
        DW 492,P0002,CO0492,CR0492
        DB 0
        DW 493,POBS,CO0493,CR0493
        DB 2
        DW 494,POBS,CO0494,CR0494
        DB 2
        DW 495,POBS,CO0495,CR0495
        DB 2
        DW 496,PLOAD,CO0496,CR0496
        DB 0
        DW 497,PLOAD,CO0497,CR0497
        DB 0
        DW 498,POBS,CO0498,CR0498
        DB 1
        DW 499,PLOAD,CO0499,CR0499
        DB 0
        DW 500,POBS,CO0500,CR0500
        DB 1
        DW 501,POBS,CO0501,CR0501
        DB 2
        DW 502,P0017,CO0502,CR0502
        DB 0
        DW 503,POBS,CO0503,CR0503
        DB 2
        DW 504,POBS,CO0504,CR0504
        DB 2
        DW 505,POBS,OOSOBS,CR0505
        DB 6
        DW 506,POBS,CO0506,CR0506
        DB 3
        DW 507,POBS,CO0507,CR0507
        DB 1
        DW 508,POBS,CO0508,CR0508
        DB 3
        DW 510,POBS,CO0510,CR0510
        DB 1
        DW 534,PLOAD,CO0534,CR0534
        DB 0
        DW 536,POBS,CO0536,CR0536
        DB 1
        DW 538,P0017,CO0538,CR0538
        DB 0
        DW 540,POBS,CO0540,CR0540
        DB 2
        DW 568,POBS,OOSOBS,CR0568
        DB 6
        DW 570,POBS,CO0570,CR0570
        DB 2
        DW 572,POBS,CO0572,CR0572
        DB 2
        DW 574,POBS,CO0574,CR0574
        DB 2
        DW 576,POBS,CO0576,CR0576
        DB 7
        DW 578,POBS,CO0578,CR0578
        DB 2
        DW 620,POBS,CO0620,CR0620
        DB 2
        DW 621,POBS,CO0621,CR0621
        DB 2

MANTAB:DW 25,CMD0025
        DW 28,CMD0028
        DW 475,CMD0475
        DW 477,CMD0477
        DW 478,CMD0478
        DW 479,CMD0479
        DW 480,CMD0480
        DW 481,CMD0481
        DW 482,CMD0482
        DW 483,CMD0483
        DW 484,CMD0484
        DW 485,CMD0485
        DW 486,CMD0486
        DW 487,CMD0487
        DW 488,CMD0488
        DW 489,CMD0489
        DW 490,CMD0490
        DW 493,CMD0493
        DW 494,CMD0494
        DW 495,CMD0495
        DW 501,CMD0501
        DW 503,CMD0503
        DW 504,CMD0504
        DW 506,CMD0506
        DW 508,CMD0508
        DW 540,CMD0540
        DW 570,CMD0570
        DW 572,CMD0572
        DW 574,CMD0574
        DW 576,CMD0576
        DW 578,CMD0578
        DW 620,CMD0620
        DW 621,CMD0621

BADSEL:DB 'CCPTEST: unknown selector. Use CCPTEST /LIST.',13,10,'$'
HLPMSG:DB 13,10,'CCPTEST 0.1.0-dev14 - CP/M command tests',13,10,13,10
        DB '  CCPTEST /NNNN   Run one ledger item',13,10
        DB '  CCPTEST /SAFE   Run automated REQUIRED items',13,10
        DB '  CCPTEST /ALL    Include observations and metadata',13,10
        DB '  CCPTEST /LIST   List ledger entries',13,10
        DB '  CCPTEST /INFO   Show version and coverage totals',13,10
        DB '  CCPTEST /H      Show this command summary',13,10
        DB '  CCPTEST /H:RESULTS   Explain results and classes',13,10
        DB '  CCPTEST /H:PROFILES  Explain named compatibility profiles',13,10
        DB '$'
RESMSG:DB 13,10,'CCPTEST result terminology',13,10,13,10
        DB 'STATUS is the outcome: PASS, FAIL, or UNTESTED.',13,10
        DB 'PASS=completed and matched; FAIL=completed and mismatched.',13,10
        DB 'UNTESTED=not executed, not available, or not yet judged.',13,10
        DB 'CLASS describes applicability, not the outcome:',13,10
        DB 'REQUIRED=baseline CP/M requirement.',13,10
        DB 'NOT GUAR.=informational; no conformance effect.',13,10
        DB 'PROFILE=required only when the named profile is claimed.',13,10
        DB 'OUT SCOPE=CCPTEST cannot execute or judge the catalog item.',13,10
        DB 'OBSERVED gives evidence or the command still required.',13,10,'$'
PRFMSG:DB 13,10,'CCPTEST named profiles',13,10,13,10
        DB 'DRI-CCP: strict DRI command-capacity behavior (0478).',13,10
        DB 'DRI-DIAG-PRES: exact DRI command-error display (0490).',13,10
        DB 'DRI-CCP-ECO: DRI default-FCB operand assignment (0506).',13,10
        DB 'DECLARED-CCP: declared command-tail capacity (0508).',13,10
        DB 'A PROFILE row applies only when that named behavior is claimed.',13,10
        DB 'Run the numbered item for prerequisites and expected behavior.',13,10
        DB 'For expendable-media procedures, first run SCRATCH /BLANK.',13,10,'$'
INFMSG:DB 'BetterCP/M CCPTEST 0.1.0-dev14',13,10
        DB 'Implemented: all 59 assigned rows',13,10
        DB 'Required: 41; diagnostics: 10',13,10
        DB 'Profile: 4; outside scope: 4',13,10
        DB 'Catalog rows represented: 59 of 59; remaining 0',13,10,'$'
LSTMSG:DB 'BetterCP/M CCPTEST 0.1.0-dev14',13,10
        DB '0002  Transient entry point',13,10
        DB '0004  TPA upper-bound discovery',13,10
        DB '0007  Command-entry default-drive byte',13,10
        DB '0010  CBIOS scratch-area role',13,10
        DB '0013  Default FCB drive-prefix parsing',13,10
        DB '0016  Default FCB unopened control fields',13,10
        DB '0019  Leading blank in command tail',13,10
        DB '0022  Bytes following command-tail terminator',13,10
        DB '0025  Program termination through JMP 0000h',13,10
        DB '0028  Valid entry return word',13,10
        DB '0031  General-register entry state',13,10
        DB '0474  BIOS residual registers and reentrancy',13,10
        DB '0475  CCP semantic prompt',13,10
        DB '0476  CCP prompt presentation freedom',13,10
        DB '0477  CCP buffered command acquisition',13,10
        DB '0478  DRI CCP command capacity',13,10
        DB '0479  CCP empty and SPACE-only commands',13,10
        DB '0480  TAB is not CCP SPACE',13,10
        DB '0481  CCP ASCII case normalization',13,10
        DB '0482  CCP built-in command set',13,10
        DB '0483  Exact built-in-name matching',13,10
        DB '0484  Built-in precedence',13,10
        DB '0485  Drive-only CCP selection',13,10
        DB '0486  Drive-prefixed transient dispatch',13,10
        DB '0487  Primary-name transient command syntax',13,10
        DB '0488  CCP resident/transient preparation boundary',13,10
        DB '0489  Generic command-error recovery',13,10
        DB '0490  Exact DRI command-error presentation',13,10
        DB '0491  CCP parser implementation freedom',13,10
        DB '0492  CCP executable identity',13,10
        DB '0493  Single-drive transient lookup',13,10
        DB '0494  Current-user transient lookup',13,10
        DB '0495  Explicit-drive lookup context',13,10
        DB '0496  CCP sequential COM loading',13,10
        DB '0497  CCP load completion',13,10
        DB '0498  Final COM record granularity',13,10
        DB '0499  Resident-system load protection',13,10
        DB '0500  Transient maximum is configuration-dependent',13,10
        DB '0501  CCP load-failure nonexecution',13,10
        DB '0502  Pre-execution DMA restoration',13,10
        DB '0503  CCP CALL/RET cleanup path',13,10
        DB '0504  Termination-state convergence',13,10
        DB '0505  CCP loader implementation freedom',13,10
        DB '0506  Default FCB operand assignment',13,10
        DB '0507  Default FCB residual fields',13,10
        DB '0508  Tail capacity bounded by CCP input acquisition',13,10
        DB '0510  RET does not generally reconstruct page zero',13,10
        DB '0534  Complete transient handoff',13,10
        DB '0536  Unloaded transient memory',13,10
        DB '0538  Loader DMA isolation',13,10
        DB '0540  Load rejection suppresses execution',13,10
        DB '0568  User areas are not a security contract',13,10
        DB '0570  DIR search and visibility',13,10
        DB '0572  ERA wildcard confirmation boundary',13,10
        DB '0574  REN resident syntax and validation',13,10
        DB '0576  SAVE destructive replacement',13,10
        DB '0578  CCP USER accepted range',13,10
        DB '0620  DRI submitted-command stream',13,10
        DB '0621  XSUB buffered-input compatibility',13,10
        DB 'Coverage: 59 implemented of 59 CCPTEST catalog cases',13,10
        DB 'Required: 41  Diagnostics: 10  Profile: 4  Outside scope: 4',13,10,'$'
HEADER: DB 13,10,'CCPTEST',13,10
        DB 'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------',13,10,'$'
SPASS: DB 'PASS      REQUIRED      $'
SFAIL: DB 'FAIL      REQUIRED      $'
SOBS:  DB 'PASS      NOT GUAR.     $'
SOBFAIL:DB 'FAIL      NOT GUAR.     $'
SOOS:  DB 'UNTESTED  OUT SCOPE     $'
SMAN:  DB 'UNTESTED  REQUIRED      $'
SMANG: DB 'UNTESTED  NOT GUAR.     $'
SPROF: DB 'UNTESTED  PROFILE       $'
SSEL:  DB 'UNTESTED  REQUIRED      $'
SPPASS:DB 'PASS      PROFILE       $'
SPFAIL:DB 'FAIL      PROFILE       $'
OOSOBS:DB 'Outside executable scope$'
TWO:   DB '  $'
CRLF:  DB 13,10,'$'
SUM1:  DB 13,10,'Summary: $'
SUM2:  DB ' pass, $'
SUM3:  DB ' fail, 0 error, $'
SUM4:  DB ' observations',13,10,'$'
DIAGTAIL:DB 'Tail-end=00; not guaranteed$'
DIAGSP:DB 'SP=0000; not guaranteed$'

MD0012:DB 13,10,'PROCEDURE: run CCPTEST /0012 SECOND.BIN',13,10
        DB 'EXPECTED: FCB2 at 006Ch has drive 0 and SECOND.BIN.',13,10
        DB 'Compare the actual 8.3 field printed below.',13,10,'$'
MDACT12:DB 'ACTUAL FCB2 name.type: $'
MD0014:DB 13,10,'PROCEDURE: copy program as WILD.COM, then run:',13,10
        DB 'WILD A:AB???.*',13,10
        DB 'EXPECTED: FCB1 drive=1, name AB???   , type ???.',13,10
        DB 'Inspect bytes 005Ch-0067h with a debugger.',13,10,'$'
MD0015:DB 13,10,'PROCEDURE: copy program as LOWER.COM, then run:',13,10
        DB 'LOWER mixed.txt',13,10
        DB 'EXPECTED: FCB1 name MIXED   , type TXT, space padded.',13,10,'$'
MD0020:DB 13,10,'PROCEDURE: copy program as TAIL.COM, then run:',13,10
        DB 'TAIL mixed Case',13,10
        DB 'EXPECTED (DRI CCP): tail at 0081h is uppercase.',13,10
        DB 'Record clones that preserve lowercase as incompatible.',13,10,'$'
MD0026:DB 13,10,'This calls BDOS C=0.',13,10
        DB 'SUCCESS: control returns to the CCP with a usable prompt.',13,10
        DB 'CCPTEST cannot print a result after it terminates.',13,10,'$'
MDGO26:DB 'Press Enter to run the test: $'
MDFAIL26:DB 'FAIL: BDOS C=0 returned to CCPTEST.',13,10,'$'
MD0027:DB 13,10,'This restores the original entry stack and executes RET.',13,10
        DB 'SUCCESS: control returns to the CCP with a usable prompt.',13,10
        DB 'CCPTEST cannot print a result after it terminates.',13,10,'$'
MDGO27:DB 'Press Enter to run the test: $'
MD0509:DB 13,10,'Run these three commands and follow each prompt:',13,10
        DB '  CCPTEST /0026   (BDOS Function 0)',13,10
        DB '  CCPTEST /0027   (entry RET)',13,10
        DB '  CCPTEST /0595   (JMP 0000h / WBOOT)',13,10
        DB 'SUCCESS: every command returns a usable CCP prompt.',13,10
        DB 'FAIL: any command hangs, crashes, or leaves no usable prompt.',13,10,'$'
MD0590:DB 13,10,'This destructive test needs a restorable emulator snapshot',13,10
        DB 'and an overlay helper that overwrites the resident CCP.',13,10
        DB 'After overwrite, execute entry RET.',13,10
        DB 'SUCCESS: RET is not treated as a safe return to erased CCP.',13,10
        DB 'UNAVAILABLE: no snapshot or overlay helper is installed.',13,10,'$'
MD0593:DB 13,10,'1. Reset or power-cycle the CP/M machine.',13,10
        DB '2. Wait for CP/M to finish a true cold boot.',13,10
        DB 'SUCCESS: drive A is current, an A> prompt appears, and DIR works.',13,10
        DB 'FAIL: boot hangs, another drive is current, or commands fail.',13,10
        DB 'CCPTEST cannot continue across the reset.',13,10,'$'
MD0595:DB 13,10,'This jumps through 0000h to invoke WBOOT.',13,10
        DB 'SUCCESS: CP/M reconstructs a usable CCP prompt.',13,10
        DB 'CCPTEST cannot print a result after WBOOT.',13,10,'$'
MDGO95:DB 'Press Enter to run the test: $'
MD0600:DB 13,10,'PREREQUISITE: documented BIOS disk profile and scratch disk.',13,10
        DB 'Prepare the expendable disk first with SCRATCH /BLANK.',13,10
        DB '1. Record sector size, numbering, translation, and error codes.',13,10
        DB '2. Run CCPTEST /0617 to validate public DPH/DPB access.',13,10
        DB '3. Use the profile monitor to read one known scratch sector.',13,10
        DB 'SUCCESS: raw bytes and status match the documented BIOS profile.',13,10
        DB 'Restore the original scratch image after the test.',13,10,'$'
MD0602:DB 13,10,'SETUP: use a disposable file on a restorable scratch disk.',13,10
        DB 'Prepare the expendable disk first with SCRATCH /BLANK.',13,10
        DB 'ACTION: call BDOS C=40 with DE pointing to its random FCB.',13,10
        DB 'EXPECTED: selector 40 consumes the FCB address in DE.',13,10,'$'
MD0603:DB 13,10,'SETUP: make a short file on a restorable scratch disk.',13,10
        DB 'Prepare the expendable disk first with SCRATCH /BLANK.',13,10
        DB 'ACTION: random-write with zero fill beyond current EOF.',13,10
        DB 'EXPECTED: newly allocated intervening records read as zero.',13,10,'$'
MD0605:DB 13,10,'ACTION: run Function 40 on valid and exhausted media.',13,10
        DB 'EXPECTED: result is in the documented success/error family;',13,10
        DB 'record the exact code for the selected disk profile.',13,10,'$'
MD0606:DB 13,10,'PREREQUISITE: observable console, reader, punch, and list.',13,10
        DB 'Send byte 41h through each documented BIOS output entry.',13,10
        DB 'Supply byte 42h to each documented BIOS input entry.',13,10
        DB 'SUCCESS: exactly A is output and exactly B is returned;',13,10
        DB 'no TAB expansion, echo, or BDOS formatting is added.',13,10
        DB 'UNAVAILABLE: required character devices cannot be observed.',13,10,'$'
MD0607:DB 13,10,'PREREQUISITE: separately observable device routes.',13,10
        DB 'Route console, reader, punch, and list to distinct endpoints.',13,10
        DB 'Send a different identifying byte through each BIOS path.',13,10
        DB 'SUCCESS: every byte appears only at its assigned endpoint.',13,10
        DB 'Restore all original routes after the test.',13,10
        DB 'UNAVAILABLE: the profile exposes no distinct endpoints.',13,10,'$'
MD0612:DB 13,10,'This test requires STAT.COM and an alternate device.',13,10
        DB '1. Run: STAT DEV:',13,10
        DB '2. Record the current assignment and IOBYTE value.',13,10
        DB '3. Use STAT to select a documented alternate assignment.',13,10
        DB '4. Run: STAT DEV:',13,10
        DB 'SUCCESS: STAT shows the new route; only its IOBYTE field changed.',13,10
        DB 'Restore the original assignment. UNAVAILABLE if STAT is absent.',13,10,'$'
MD0614:DB 13,10,'SETUP: obtain the selected disk DPB and a scratch directory.',13,10
        DB 'Prepare the expendable disk first with SCRATCH /BLANK.',13,10
        DB 'ACTION: compare DSM with directory allocation entry width.',13,10
        DB 'EXPECTED: DSM below 256 uses 8-bit entries; otherwise 16-bit.',13,10,'$'
MD0615:DB 13,10,'ACTION: use BIOS SELDSK/SETTRK/SETSEC/SETDMA/READ on a',13,10
        DB 'restorable disk, translating logical sectors with SECTRAN.',13,10
        DB 'Prepare the expendable disk first with SCRATCH /BLANK.',13,10
        DB 'EXPECTED: computed directory sectors contain valid entries.',13,10,'$'

; CCPTEST dev1 selected-manual procedures. Each procedure says exactly what
; to enter at the CCP and what constitutes success.
CMD0025:DB 13,10,'This jumps through address 0000h.',13,10
        DB 'SUCCESS: CP/M returns with a usable CCP prompt.',13,10
        DB 'CCPTEST cannot print a result after the jump.',13,10,'$'
CMD0028:DB 13,10,'This restores the entry stack and executes RET.',13,10
        DB 'SUCCESS: CP/M returns with a usable CCP prompt.',13,10
        DB 'CCPTEST cannot print a result after the return.',13,10,'$'
CMD0475:DB 13,10,'At the CCP prompt run: DIR',13,10
        DB 'SUCCESS: DIR executes, then the current-drive prompt returns.',13,10
        DB 'FAIL: no usable prompt returns.',13,10,'$'
CMD0477:DB 13,10,'At the CCP prompt type DIR, use normal line editing,',13,10
        DB 'then press Enter.',13,10
        DB 'SUCCESS: the edited command, not the original text, executes.',13,10,'$'
CMD0478:DB 13,10,'Strict DRI profile only. Enter a 127-character command.',13,10
        DB 'SUCCESS: input remains bounded and CCP returns a prompt.',13,10
        DB 'UNAVAILABLE: the selected profile is not strict DRI CCP.',13,10,'$'
CMD0479:DB 13,10,'At the CCP press Enter on an empty line; repeat with spaces.',13,10
        DB 'SUCCESS: each input is ignored and a usable prompt returns.',13,10,'$'
CMD0480:DB 13,10,'At the CCP enter a TAB followed by DIR.',13,10
        DB 'EXPECTED: TAB is not treated as a command-separating SPACE.',13,10
        DB 'Record the diagnostic; the prompt must remain usable.',13,10,'$'
CMD0481:DB 13,10,'At the CCP run: dir',13,10
        DB 'SUCCESS: lowercase input invokes the DIR built-in.',13,10,'$'
CMD0482:DB 13,10,'Run each command: DIR, ERA, REN, SAVE, TYPE, USER.',13,10
        DB 'Use harmless operands and a disposable file for file commands.',13,10
        DB 'SUCCESS: every built-in is recognized; restore changed state.',13,10,'$'
CMD0483:DB 13,10,'At the CCP run: DIRECTORY',13,10
        DB 'SUCCESS: it is not accepted as the DIR built-in.',13,10
        DB 'A normal command-error response and usable prompt must follow.',13,10,'$'
CMD0484:DB 13,10,'Place a disposable DIR.COM on the current drive; run DIR.',13,10
        DB 'SUCCESS: the resident DIR command runs, not DIR.COM.',13,10
        DB 'Erase the disposable DIR.COM after the test.',13,10,'$'
CMD0485:DB 13,10,'At the CCP enter B: and then A:.',13,10
        DB 'SUCCESS: each valid drive becomes current and its prompt appears.',13,10
        DB 'Restore the original current drive.',13,10,'$'
CMD0486:DB 13,10,'Put CCPTEST.COM on B:, remain on A:, then run:',13,10
        DB '  B:CCPTEST /0002',13,10
        DB 'SUCCESS: CCPTEST runs and reports item 0002 PASS.',13,10,'$'
CMD0487:DB 13,10,'At the CCP run: CCPTEST /0002',13,10
        DB 'SUCCESS: the .COM suffix is optional and item 0002 passes.',13,10,'$'
CMD0488:DB 13,10,'With CCPTEST only on the current drive, run it by name.',13,10
        DB 'SUCCESS: the CCP prepares the TPA and transfers control to 0100h.',13,10
        DB 'Item 0002 must report PASS and the prompt must return.',13,10,'$'
CMD0489:DB 13,10,'From a restorable snapshot run a nonexistent command.',13,10
        DB 'SUCCESS: CCP reports an error and returns a usable prompt.',13,10
        DB 'FAIL: the CCP hangs, crashes, or corrupts the current drive.',13,10,'$'
CMD0490:DB 13,10,'Strict DRI diagnostic profile only.',13,10
        DB 'At the CCP prompt type: NOEXIST',13,10
        DB 'EXPECTED: the next displayed command line is exactly NOEXIST?',13,10
        DB 'Then the current-drive prompt must return and accept DIR.',13,10
        DB 'FAIL: missing/different text, no ?, or no usable prompt.',13,10
        DB 'UNAVAILABLE: strict DRI diagnostics are not claimed.',13,10,'$'
CMD0493:DB 13,10,'Put CCPTEST.COM only on the current drive; run CCPTEST /0002.',13,10
        DB 'SUCCESS: item 0002 passes and a usable prompt returns.',13,10,'$'
CMD0494:DB 13,10,'Put CCPTEST.COM in the current user area; run CCPTEST /0002.',13,10
        DB 'SUCCESS: item 0002 passes. Restore the original user area.',13,10,'$'
CMD0495:DB 13,10,'Put CCPTEST.COM on B:, remain on A:, then run:',13,10
        DB '  B:CCPTEST /0002',13,10
        DB 'SUCCESS: item 0002 passes; the original current drive remains.',13,10,'$'
CMD0501:DB 13,10,'From a restorable snapshot run a truncated COM file.',13,10
        DB 'SUCCESS: its entry code is not executed and a usable prompt returns.',13,10,'$'
CMD0503:DB 13,10,'Run CCPTEST /0028.',13,10
        DB 'SUCCESS: RET returns to a usable CCP prompt without a crash.',13,10,'$'
CMD0504:DB 13,10,'Run CCPTEST /0025, then repeat with /0028.',13,10
        DB 'SUCCESS: both termination paths return the same usable prompt.',13,10,'$'
CMD0506:DB 13,10,'DRI-CCP-ECO profile. Run: CCPTEST /0506 ALPHA.TXT',13,10
        DB 'SUCCESS: both default FCBs match documented DRI operand parsing.',13,10
        DB 'UNAVAILABLE: this profile is not claimed.',13,10,'$'
CMD0508:DB 13,10,'DECLARED-CCP profile. Enter the profile maximum command line.',13,10
        DB 'SUCCESS: input is bounded, executes or errors, and prompt returns.',13,10,'$'
CMD0540:DB 13,10,'From a restorable snapshot run a deliberately invalid COM image.',13,10
        DB 'SUCCESS: its entry marker is not executed and prompt remains usable.',13,10,'$'
CMD0570:DB 13,10,'Create ONE.TMP in the current user area; run DIR ONE.TMP.',13,10
        DB 'SUCCESS: ONE.TMP is listed. Erase it after the test.',13,10,'$'
CMD0572:DB 13,10,'Create A.ONE and B.ONE; run ERA ?.ONE.',13,10
        DB 'SUCCESS: CCP asks for confirmation before wildcard deletion.',13,10
        DB 'Answer N and verify both files remain.',13,10,'$'
CMD0574:DB 13,10,'Create OLD.TMP; run REN NEW.TMP=OLD.TMP.',13,10
        DB 'SUCCESS: NEW.TMP exists and OLD.TMP does not. Then erase NEW.TMP.',13,10,'$'
CMD0576:DB 13,10,'On a disposable disk create OLD.COM; run SAVE 1 OLD.COM.',13,10
        DB 'Prepare the expendable disk first with SCRATCH /BLANK.',13,10
        DB 'Record whether replacement is allowed or rejected; either is valid.',13,10,'$'
CMD0578:DB 13,10,'Run USER 15, then USER 0.',13,10
        DB 'SUCCESS: each valid user is selected and the prompt returns.',13,10,'$'
CMD0620:DB 13,10,'With SUBMIT.COM available, make T.SUB containing DIR and run:',13,10
        DB '  SUBMIT T',13,10
        DB 'SUCCESS: DIR executes from the submitted command stream.',13,10,'$'
CMD0621:DB 13,10,'With XSUB available, submit a script that invokes XSUB then DIR.',13,10
        DB 'SUCCESS: buffered input is accepted and DIR executes.',13,10
        DB 'UNAVAILABLE: XSUB is not supplied by the selected system.',13,10,'$'

CO0002:DB 'Transient program entered at 0100h$'
CO0004:DB 'BDOS/TPA ceiling lies above program$'
CO0007:DB 'Entry default-drive byte is in range$'
CO0010:DB 'BIOS scratch ends before FCB at 005Ch$'
CO0013:DB 'Run: CCPTEST /0013 B:ALPHA.TXT$'
CO13PASS:DB 'FCB2 drive=2 and ALPHA.TXT matched$'
CO13FAIL:DB 'FCB2 did not contain drive=2 ALPHA.TXT$'
CO0016:DB 'Unopened FCB controls are unspecified$'
CO0019:DB 'Command tail begins with SPACE$'
CO0025:DB 'Run: CCPTEST /0025$'
CO0028:DB 'Run: CCPTEST /0028$'
CO0031:DB 'General entry registers unspecified$'
CO0474:DB 'BIOS residual registers vary$'
CO0475:DB 'Run: CCPTEST /0475$'
CO0476:DB 'Prompt presentation is not fixed$'
CO0477:DB 'Run: CCPTEST /0477$'
CO0478:DB 'DRI-CCP: Run CCPTEST /0478$'
CO0479:DB 'Run: CCPTEST /0479$'
CO0480:DB 'Run: CCPTEST /0480$'
CO0481:DB 'Run: CCPTEST /0481$'
CO0482:DB 'Run: CCPTEST /0482$'
CO0483:DB 'Run: CCPTEST /0483$'
CO0484:DB 'Run: CCPTEST /0484$'
CO0485:DB 'Run: CCPTEST /0485$'
CO0486:DB 'Run: CCPTEST /0486$'
CO0487:DB 'Run: CCPTEST /0487$'
CO0488:DB 'Run: CCPTEST /0488$'
CO0489:DB 'Run: CCPTEST /0489$'
CO0490:DB 'DRI-DIAG-PRES: Run CCPTEST /0490$'
CO0492:DB 'CCPTEST image executed at 0100h$'
CO0493:DB 'Run: CCPTEST /0493$'
CO0494:DB 'Run: CCPTEST /0494$'
CO0495:DB 'Run: CCPTEST /0495$'
CO0496:DB 'Sequential COM image fully loaded$'
CO0497:DB 'Final image marker was present$'
CO0498:DB 'Final record padding is unspecified$'
CO0499:DB 'Loaded image stayed below BDOS$'
CO0500:DB 'Maximum transient size is configured$'
CO0501:DB 'Run: CCPTEST /0501$'
CO0502:DB 'CCP restored default DMA at 0080h$'
CO0503:DB 'Run: CCPTEST /0503$'
CO0504:DB 'Run: CCPTEST /0504$'
CO0506:DB 'DRI-CCP-ECO: Run CCPTEST /0506$'
CO0507:DB 'Residual FCB fields unspecified$'
CO0508:DB 'DECLARED-CCP: Run CCPTEST /0508$'
CO0510:DB 'RET need not rebuild page zero$'
CO0534:DB 'Complete transient image received$'
CO0536:DB 'Unloaded TPA bytes unspecified$'
CO0538:DB 'Loader left DMA at 0080h$'
CO0540:DB 'Run: CCPTEST /0540$'
CO0570:DB 'Run: CCPTEST /0570$'
CO0572:DB 'Run: CCPTEST /0572$'
CO0574:DB 'Run: CCPTEST /0574$'
CO0576:DB 'Run: CCPTEST /0576$'
CO0578:DB 'Run: CCPTEST /0578$'
CO0620:DB 'Run: CCPTEST /0620$'
CO0621:DB 'Run: CCPTEST /0621$'

CR0002:DB 'CCP-003-P0002 OR-0002$'
CR0004:DB 'CCP-003-P0004 OR-0004$'
CR0007:DB 'CCP-003-P0007 OR-0007$'
CR0010:DB 'CCP-003-P0010 OR-0010$'
CR0013:DB 'CCP-003-P0013 OR-0013$'
CR0016:DB 'CCP-003-P0016 OR-0016$'
CR0019:DB 'CCP-003-P0019 OR-0019$'
CR0022:DB 'CCP-003-P0022 OR-0022$'
CR0025:DB 'CCP-003-P0025 OR-0025$'
CR0028:DB 'CCP-003-P0028 OR-0028$'
CR0031:DB 'CCP-003-P0031 OR-0031$'
CR0474:DB 'CCP-001-P0474 OR-0474$'
CR0475:DB 'CCP-002-P0475 OR-0475$'
CR0476:DB 'CCP-001-P0476 OR-0476$'
CR0477:DB 'CCP-002-P0477 OR-0477$'
CR0478:DB 'CCP-001-P0478 OR-0478$'
CR0479:DB 'CCP-002-P0479 OR-0479$'
CR0480:DB 'CCP-001-P0480 OR-0480$'
CR0481:DB 'CCP-002-P0481 OR-0481$'
CR0482:DB 'CCP-001-P0482 OR-0482$'
CR0483:DB 'CCP-002-P0483 OR-0483$'
CR0484:DB 'CCP-001-P0484 OR-0484$'
CR0485:DB 'CCP-002-P0485 OR-0485$'
CR0486:DB 'CCP-001-P0486 OR-0486$'
CR0487:DB 'CCP-002-P0487 OR-0487$'
CR0488:DB 'CCP-001-P0488 OR-0488$'
CR0489:DB 'CCP-002-P0489 OR-0489$'
CR0490:DB 'CCP-001-P0490 OR-0490$'
CR0491:DB 'CCP-005-P0491 OR-0491$'
CR0492:DB 'CCP-005-P0492 OR-0492$'
CR0493:DB 'CCP-005-P0493 OR-0493$'
CR0494:DB 'CCP-005-P0494 OR-0494$'
CR0495:DB 'CCP-005-P0495 OR-0495$'
CR0496:DB 'CCP-005-P0496 OR-0496$'
CR0497:DB 'CCP-005-P0497 OR-0497$'
CR0498:DB 'CCP-005-P0498 OR-0498$'
CR0499:DB 'CCP-005-P0499 OR-0499$'
CR0500:DB 'CCP-005-P0500 OR-0500$'
CR0501:DB 'CCP-005-P0501 OR-0501$'
CR0502:DB 'CCP-005-P0502 OR-0502$'
CR0503:DB 'CCP-005-P0503 OR-0503$'
CR0504:DB 'CCP-005-P0504 OR-0504$'
CR0505:DB 'CCP-005-P0505 OR-0505$'
CR0506:DB 'CCP-005-P0506 OR-0506$'
CR0507:DB 'CCP-005-P0507 OR-0507$'
CR0508:DB 'CCP-005-P0508 OR-0508$'
CR0510:DB 'CCP-005-P0510 OR-0510$'
CR0534:DB 'MEM-004-P0534 OR-0534$'
CR0536:DB 'MEM-004-P0536 OR-0536$'
CR0538:DB 'MEM-004-P0538 OR-0538$'
CR0540:DB 'MEM-004-P0540 OR-0540$'
CR0568:DB 'CCP-006-P0568 OR-0568$'
CR0570:DB 'CCP-006-P0570 OR-0570$'
CR0572:DB 'CCP-006-P0572 OR-0572$'
CR0574:DB 'CCP-006-P0574 OR-0574$'
CR0576:DB 'CCP-006-P0576 OR-0576$'
CR0578:DB 'CCP-006-P0578 OR-0578$'
CR0620:DB 'CCP-007-P0620 OR-0620$'
CR0621:DB 'CCP-007-P0621 OR-0621$'
FCB13:  DB 'ALPHA   TXT'

O0001: DB 'Program began at 0100h$'
O0003: DB 'TPA lower boundary is 0100h$'
O0005: DB 'JMP at 0000h is warm start$'
O0006: DB 'IOBYTE resides at 0003h$'
O0008: DB 'JMP at 0005h is BDOS gateway$'
O0009: DB 'Page-zero gateway roles present$'
O0011: DB 'First default FCB is at 005Ch$'
O0012: DB 'Use /0012 SECOND.BIN; FCB2 must match$'
O0014: DB 'Use /0014 A:AB*.C?M$'
O0015: DB 'Use /0015 mixed.txt$'
O0017: DB 'Tail count read from 0080h$'
O0018: DB 'Tail text begins at 0081h$'
O0020: DB 'Use /0020 mixed Case; tail must uppercase$'
O0021: DB 'Tail-end byte observed$'
O0023: DB 'Entry DMA was 0080h$'
O0024: DB 'Tail and default DMA overlap$'
O0026: DB 'Run CCPTEST /0026 manually$'
O0027: DB 'Run CCPTEST /0027 manually$'
O0032: DB 'Extended registers unspecified$'
O0033: DB 'Flags/interrupt unspecified$'
O0509: DB 'Run CCPTEST /0509 manually$'
O0511: DB 'Open FCBs need explicit close$'
O0533: DB 'BDOS is not reentrant$'
O0537: DB 'BDOS ready at transient entry$'
O0539: DB 'Entry stack recorded$'
O0589: DB 'BDOS ceiling lies above program$'
O0590: DB 'Run CCPTEST /0590 manually$'
O0591: DB 'Application owns constraints$'
O0592: DB 'Entry stack may be overlayable$'
O0593: DB 'Run CCPTEST /0593 manually$'
O0594: DB 'BOOT need not clear all memory$'
O0595: DB 'Run CCPTEST /0595 manually$'
O0596: DB 'Residual WBOOT state varies$'
O0597: DB 'Post-WBOOT console state varies$'
O0598: DB 'WBOOT vector present at 0000h$'
O0599: DB 'Function 31 returned a DPB$'
O0600: DB 'Run CCPTEST /0600 manually$'
O0601: DB 'BIOS internals vary by profile$'
O0602: DB 'Function 40 consumed scratch FCB$'
O0603: DB 'Intervening records were zero$'
O0604: DB 'Sparse-hole behavior varies$'
O0605: DB 'Function 40 returned success$'
O0606: DB 'Run CCPTEST /0606 manually$'
O0607: DB 'Run CCPTEST /0607 manually$'
O0608: DB 'IOBYTE reassignment was visible$'
O0609: DB 'IOBYTE read/write was coherent$'
O0610: DB 'Other IOBYTE fields preserved$'
O0611: DB 'Assignment need not prove I/O$'
O0612: DB 'Run CCPTEST /0612 manually$'
O0613: DB 'Disk parameter block available$'
O0614: DB 'DPB block mask/limits coherent$'
O0615: DB 'Logical disk structures followed$'
O0616: DB 'Raw disk format is nonportable$'
O0617: DB 'Active DPH/DPB contract followed$'
O0619: DB 'Private BDOS is not a gateway$'

R0001: DB 'MEM-001-P0001 OR-0001$'
R0003: DB 'MEM-001-P0003 OR-0003$'
R0005: DB 'MEM-001-P0005 OR-0005$'
R0006: DB 'MEM-005-P0006 OR-0006$'
R0008: DB 'MEM-001-P0008 OR-0008$'
R0009: DB 'MEM-005-P0009 OR-0009$'
R0011: DB 'MEM-001-P0011 OR-0011$'
R0012: DB 'MEM-005-P0012 OR-0012$'
R0014: DB 'MEM-001-P0014 OR-0014$'
R0015: DB 'MEM-005-P0015 OR-0015$'
R0017: DB 'MEM-001-P0017 OR-0017$'
R0018: DB 'MEM-005-P0018 OR-0018$'
R0020: DB 'MEM-001-P0020 OR-0020$'
R0021: DB 'MEM-005-P0021 OR-0021$'
R0023: DB 'MEM-001-P0023 OR-0023$'
R0024: DB 'MEM-005-P0024 OR-0024$'
R0026: DB 'MEM-001-P0026 OR-0026$'
R0027: DB 'MEM-005-P0027 OR-0027$'
R0029: DB 'MEM-001-P0029 OR-0029$'
R0030: DB 'MEM-005-P0030 OR-0030$'
R0032: DB 'MEM-001-P0032 OR-0032$'
R0033: DB 'MEM-005-P0033 OR-0033$'
R0509: DB 'MEM-005-P0509 OR-0509$'
R0511: DB 'MEM-005-P0511 OR-0511$'
R0533: DB 'MEM-004-P0533 OR-0533$'
R0535: DB 'MEM-004-P0535 OR-0535$'
R0537: DB 'MEM-004-P0537 OR-0537$'
R0539: DB 'MEM-004-P0539 OR-0539$'
R0588: DB 'MEM-002-P0588 OR-0588$'
R0589: DB 'MEM-002-P0589 OR-0589$'
R0590: DB 'MEM-002-P0590 OR-0590$'
R0591: DB 'MEM-002-P0591 OR-0591$'
R0592: DB 'MEM-002-P0592 OR-0592$'
R0593: DB 'MEM-004-P0593 OR-0593$'
R0594: DB 'MEM-002-P0594 OR-0594$'
R0595: DB 'MEM-004-P0595 OR-0595$'
R0596: DB 'MEM-002-P0596 OR-0596$'
R0597: DB 'MEM-004-P0597 OR-0597$'
R0598: DB 'MEM-002-P0598 OR-0598$'
R0599: DB 'MEM-004-P0599 OR-0599$'
R0600: DB 'MEM-002-P0600 OR-0600$'
R0601: DB 'MEM-004-P0601 OR-0601$'
R0602: DB 'MEM-002-P0602 OR-0602$'
R0603: DB 'MEM-004-P0603 OR-0603$'
R0604: DB 'MEM-002-P0604 OR-0604$'
R0605: DB 'MEM-004-P0605 OR-0605$'
R0606: DB 'MEM-002-P0606 OR-0606$'
R0607: DB 'MEM-004-P0607 OR-0607$'
R0608: DB 'MEM-002-P0608 OR-0608$'
R0609: DB 'MEM-004-P0609 OR-0609$'
R0610: DB 'MEM-005-P0610 OR-0610$'
R0611: DB 'MEM-002-P0611 OR-0611$'
R0612: DB 'MEM-004-P0612 OR-0612$'
R0613: DB 'MEM-005-P0613 OR-0613$'
R0614: DB 'MEM-002-P0614 OR-0614$'
R0615: DB 'MEM-004-P0615 OR-0615$'
R0616: DB 'MEM-005-P0616 OR-0616$'
R0617: DB 'MEM-002-P0617 OR-0617$'
R0619: DB 'MEM-006-P0619 OR-0619$'

WILDFCB:DB 0,'CCPTEST','COM',0,0,0,0
        DS 20
FCB12:  DB 0,'SECOND  ','BIN'
FCB14:  DB 1,'AB??????','C?M'
FCB15:  DB 0,'MIXED   ','TXT'
F40INIT:DB 0,'ENT40   ','$$$',0,0,0,0
        DS 20
F40FCB: DS 36
F40DMA: DS 128
ITEMNO:DW 0
CURITEM:DW 0
PROCPTR:DW 0
OBSPTR:DW 0
PASSCT:DB 0
FAILCT:DB 0
OBSCT: DB 0
RUNMODE:DB 0
ENTRYSP:DW 0
DPHPTR:DW 0
DPBPTR:DW 0
BIOPTR: DW 0
        DS 128
STACKTOP:
ENDPROG:
LOADMARK:DB 0A5H
IMAGEEND:
        END     START
