;***********************************************************************
;*               B E T T E R   C P / M   E N T R Y T S T              *
;*              TRANSIENT ENTRY AND PAGE-ZERO EXERCISER                *
;*                         VERSION DEV11                               *
;***********************************************************************
;
; Version 0.1.0-dev11
; Intel 8080 subset; accepted by Z80ASM and by M80 in .Z80 mode.
;
; PROGRAMMER'S NOTES
; ------------------
;
; ENTRYTST examines the machine exactly where the CCP hands it to a transient:
; page zero, default FCBs, command tail, DMA, entry stack, and loaded image.
; It does not infer private CCP or BDOS machinery from those public effects.
;
; ENTRYSP is saved before our private stack is installed.  The selected RET
; card restores it.  Function-zero and WBOOT cards deliberately do not return.
; These terminal cards are operator procedures and never run in a batch.
;
; An A5h byte at the end of the COM proves the loader reached the final byte.
; A5h paint at 0080h lets Search First prove the entry DMA: its 0..3 result is
; multiplied by 32 to select the changed slot, after FFh has been rejected.
;
; The Function 40 sandbox uses ENT40.$$$, writes random record two, and reads
; zero-filled holes back.  Returning roads restore DMA and delete the file.
; The direct-structure probe follows the public BIOS table, DPH, DPB, and
; SECTRAN pointer without writing disk data.
;
; Manual and profile rows remain UNTESTED until their recipe is performed.

        ORG     0100H
BDOS    EQU     0005H
NCASES  EQU     59

START:  LD      HL,0
        ; Save the CCP's entry stack before borrowing our own.
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

; THE SWITCH YARD
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

; THE NINE-BYTE CARD DECK
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
; Class 0 REQUIRED, 1 NOT GUARANTEED, 2 separately-run REQUIRED,
; 3 separately-run PROFILE, 4 selected REQUIRED, 5 selected PROFILE, 6 OUTSIDE.
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
; THE OPERATOR'S CLIPBOARD -- selected manual cards print the full recipe.
MANDETAIL:LD   HL,MANTAB
        LD      B,10
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
        LD      DE,26
        CALL    CMPEQ
        OR      A
        JP      Z,MDTERM26
        LD      HL,(CURITEM)
        LD      DE,27
        CALL    CMPEQ
        OR      A
        JP      Z,MDTERM27
        LD      HL,(CURITEM)
        LD      DE,595
        CALL    CMPEQ
        OR      A
        JP      Z,MDTERM95
        RET
MDTERM26:LD    DE,MDGO26
        CALL    MDPAUSE
        LD      C,0
        CALL    BDOS
        LD      DE,MDFAIL26
        JP      PUTS
MDTERM27:LD    DE,MDGO27
        CALL    MDPAUSE
        LD      HL,(ENTRYSP)
        LD      SP,HL
        RET
MDTERM95:LD    DE,MDGO95
        CALL    MDPAUSE
        JP      0000H
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
; ENTRY FURNITURE AND PAGE ZERO
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
; THE PAINTED-DMA TRICK -- convert Search First's 0..3 result to DMA+32*A.
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
; LOAD-LIMIT WITNESS -- the complete image must lie below the BDOS ceiling.
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
; BORROWED IOBYTE -- toggle one bit and restore the entry value.
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
; THE FUNCTION 40 SANDBOX -- all exits restore DMA and remove ENT40.$$$.
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
; A READ-ONLY WALK THROUGH THE BIOS PUBLIC TABLE, DPH, DPB, AND SECTRAN.
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
; DIAGNOSTIC RESIDUE IS RECORDED, NEVER PROMOTED TO A PORTABLE RULE.
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
        DW 1,P0001,O0001,R0001
        DB 0
        DW 3,P0003,O0003,R0003
        DB 0
        DW 5,P0005,O0005,R0005
        DB 0
        DW 6,P0006,O0006,R0006
        DB 0
        DW 8,P0008,O0008,R0008
        DB 0
        DW 9,P0009,O0009,R0009
        DB 0
        DW 11,P0011,O0011,R0011
        DB 0
        DW 12,P0012,O0012,R0012
        DB 5
        DW 14,P0014,O0014,R0014
        DB 4
        DW 15,P0015,O0015,R0015
        DB 4
        DW 17,P0017,O0017,R0017
        DB 0
        DW 18,P0018,O0018,R0018
        DB 0
        DW 20,P0020,O0020,R0020
        DB 4
        DW 21,P0021,O0021,R0021
        DB 1
        DW 23,P0023,O0023,R0023
        DB 0
        DW 24,P0024,O0024,R0024
        DB 0
        DW 26,P0001,O0026,R0026
        DB 2
        DW 27,P0001,O0027,R0027
        DB 2
        DW 29,P0001,OOSOBS,R0029
        DB 6
        DW 30,P0001,OOSOBS,R0030
        DB 6
        DW 32,P0032,O0032,R0032
        DB 1
        DW 33,P0033,O0033,R0033
        DB 1
        DW 509,P0001,O0509,R0509
        DB 2
        DW 511,P0511,O0511,R0511
        DB 1
        DW 533,P0533,O0533,R0533
        DB 1
        DW 535,P0001,OOSOBS,R0535
        DB 6
        DW 537,P0537,O0537,R0537
        DB 0
        DW 539,P0539,O0539,R0539
        DB 1
        DW 588,P0001,OOSOBS,R0588
        DB 6
        DW 589,P0589,O0589,R0589
        DB 0
        DW 590,P0001,O0590,R0590
        DB 2
        DW 591,P0001,O0591,R0591
        DB 1
        DW 592,P0001,O0592,R0592
        DB 1
        DW 593,P0001,O0593,R0593
        DB 2
        DW 594,P0001,O0594,R0594
        DB 1
        DW 595,P0001,O0595,R0595
        DB 2
        DW 596,P0001,O0596,R0596
        DB 1
        DW 597,P0001,O0597,R0597
        DB 1
        DW 598,P0598,O0598,R0598
        DB 0
        DW 599,P0599,O0599,R0599
        DB 0
        DW 600,P0001,O0600,R0600
        DB 2
        DW 601,P0001,O0601,R0601
        DB 1
        DW 602,P0602,O0602,R0602
        DB 0
        DW 603,P0603,O0603,R0603
        DB 0
        DW 604,P0001,O0604,R0604
        DB 1
        DW 605,P0605,O0605,R0605
        DB 0
        DW 606,P0001,O0606,R0606
        DB 2
        DW 607,P0001,O0607,R0607
        DB 2
        DW 608,P0608,O0608,R0608
        DB 0
        DW 609,P0609,O0609,R0609
        DB 0
        DW 610,P0610,O0610,R0610
        DB 0
        DW 611,P0001,O0611,R0611
        DB 1
        DW 612,P0001,O0612,R0612
        DB 2
        DW 613,P0613,O0613,R0613
        DB 0
        DW 614,P0614,O0614,R0614
        DB 0
        DW 615,P0615,O0615,R0615
        DB 0
        DW 616,P0001,O0616,R0616
        DB 1
        DW 617,P0617,O0617,R0617
        DB 0
        DW 619,P0001,O0619,R0619
        DB 1

MANTAB:DW 26,MD0026
        DW 27,MD0027
        DW 509,MD0509
        DW 590,MD0590
        DW 593,MD0593
        DW 595,MD0595
        DW 600,MD0600
        DW 606,MD0606
        DW 607,MD0607
        DW 612,MD0612

BADSEL:DB 'ENTRYTST: unknown selector. Use ENTRYTST /LIST.',13,10,'$'
HLPMSG:DB 13,10,'ENTRYTST 0.1.0-dev11 - CP/M entry tests',13,10,13,10
        DB '  ENTRYTST /NNNN   Run one ledger item',13,10
        DB '  ENTRYTST /SAFE   Run automated REQUIRED items',13,10
        DB '  ENTRYTST /ALL    Include observations and metadata',13,10
        DB '  ENTRYTST /LIST   List ledger entries',13,10
        DB '  ENTRYTST /INFO   Show version and coverage totals',13,10
        DB '  ENTRYTST /H      Show this command summary',13,10
        DB '  ENTRYTST /H:RESULTS   Explain results and classes',13,10
        DB '  ENTRYTST /H:PROFILES  Explain named profiles',13,10,'$'
RESMSG:DB 13,10,'ENTRYTST result terminology',13,10,13,10
        DB 'STATUS: P=Pass F=Fail -=Not-run O=Observed.',13,10
        DB 'PASS=completed and matched; FAIL=completed and mismatched.',13,10
        DB 'CLASS: R=Required N=Not-guaranteed S=Out-of-scope X=Profile.',13,10
        DB 'PROFILE=required only when its named profile is claimed.',13,10
        DB 'OUT SCOPE=ENTRYTST cannot execute or judge the item.',13,10
        DB 'OBSERVED gives evidence or the command still required.',13,10,'$'
PRFMSG:DB 13,10,'ENTRYTST named profiles',13,10,13,10
        DB 'DRI-CCP: strict DRI default-FCB parsing behavior (0012).',13,10
        DB 'A PROFILE row applies only when that named behavior is claimed.',13,10
        DB 'Run the numbered item for prerequisites and expected behavior.',13,10
        DB 'For expendable-media procedures, first run SCRATCH /BLANK.',13,10,'$'
INFMSG:DB 'BetterCP/M ENTRYTST 0.1.0-dev11',13,10
        DB 'Implemented: all 59 assigned rows',13,10
        DB 'Required: 38 (10 manual, 3 selected); diagnostics: 16',13,10
        DB 'Profile: 1 selected; outside scope: 4',13,10
        DB 'Catalog rows represented: 59 of 59; remaining 0',13,10,'$'
LSTMSG:DB 13,10,'BetterCP/M ENTRYTST ledger entries',13,10
        DB '0001  .COM load origin',13,10
        DB '0003  TPA lower boundary',13,10
        DB '0005  Warm-start gateway at 0000h',13,10
        DB '0006  IOBYTE location',13,10
        DB '0008  BDOS gateway at 0005h',13,10
        DB '0009  Reserved restart/interrupt region roles',13,10
        DB '0011  First default FCB location',13,10
        DB '0012  Second default FCB at 006Ch',13,10
        DB '0014  Default FCB wildcard expansion',13,10
        DB '0015  Default FCB case and padding',13,10
        DB '0017  Command-tail count location',13,10
        DB '0018  Command-tail character location',13,10
        DB '0020  Uppercase command-tail representation',13,10
        DB '0021  NUL after counted command tail',13,10
        DB '0023  Default DMA address',13,10
        DB '0024  Command-tail/default-DMA overlap',13,10
        DB '0026  Program termination through BDOS function 0',13,10
        DB '0027  RET termination',13,10
        DB '0029  Exact entry SP',13,10
        DB '0030  Exact entry return address',13,10
        DB '0032  Z80 extended-register entry state',13,10
        DB '0033  Entry flags and interrupt state',13,10
        DB '0509  Transient termination mechanisms',13,10
        DB '0511  Termination does not implicitly close application FCBs',13,10
        DB '0533  BDOS reentrancy',13,10
        DB '0535  Handoff preparation ordering',13,10
        DB '0537  Immediate BDOS readiness',13,10
        DB '0539  Transient stack preparation',13,10
        DB '0588  Exact recovery internals are not part of the contract',13,10
        DB '0589  Loader ceiling and overlay TPA are distinct',13,10
        DB '0590  CCP overlay invalidates ordinary RET assumptions',13,10
        DB '0591  System ownership is an application obligation',13,10
        DB '0592  Entry-stack storage may occupy overlayable memory',13,10
        DB '0593  Cold BOOT public postcondition',13,10
        DB '0594  Cold BOOT does not promise blanket memory clearing',13,10
        DB '0595  WBOOT command-environment reconstruction',13,10
        DB '0596  Residual state across WBOOT',13,10
        DB '0597  Console-pending state across WBOOT',13,10
        DB '0598  BIOS vector is a public runtime ABI',13,10
        DB '0599  DPH structures are compatibility-visible',13,10
        DB '0600  Direct BIOS calls expose raw device behavior',13,10
        DB '0601  BIOS implementation details remain profile-specific',13,10
        DB '0602  Function 40 selector and input',13,10
        DB '0603  Function 40 allocation-block zero fill',13,10
        DB '0604  Function 40 is not universal sparse-hole materialization',13,10
        DB '0605  Function 40 result family',13,10
        DB '0606  BIOS character services are raw device interfaces',13,10
        DB '0607  Character devices remain distinct runtime paths',13,10
        DB '0608  IOBYTE reassignment is runtime visible',13,10
        DB '0609  IOBYTE access coherence',13,10
        DB '0610  Field-preserving assignment changes',13,10
        DB '0611  IOBYTE assignment does not validate device presence',13,10
        DB '0612  STAT device-assignment semantics',13,10
        DB '0613  Parameterized disk-structure coherence',13,10
        DB '0614  DPB-dependent directory allocation-map width',13,10
        DB '0615  Logical directory placement',13,10
        DB '0616  Raw-format universality',13,10
        DB '0617  Direct-structure caller responsibility',13,10
        DB '0619  Private BDOS target is not an application gateway',13,10
        DB '$'
HEADER: DB 13,10,'ENTRYTST',13,10
        DB 'ITEM  S  C  OBSERVED',13,10
        DB '----  -  -  ----------------------------------------------------------',13,10,'$'
SPASS: DB 'P  R  $'
SFAIL: DB 'F  R  $'
SOBS:  DB 'O  N  $'
SOBFAIL:DB 'F  N  $'
SOOS:  DB '-  S  $'
SMAN:  DB '-  R  $'
SPROF: DB '-  X  $'
SSEL:  DB '-  R  $'
SPPASS:DB 'P  X  $'
SPFAIL:DB 'F  X  $'
OOSOBS:DB 'Outside executable scope$'
TWO:   DB '  $'
CRLF:  DB 13,10,'$'
SUM1:  DB 13,10,'Summary: $'
SUM2:  DB ' pass, $'
SUM3:  DB ' fail, 0 error, $'
SUM4:  DB ' observations',13,10,'$'
DIAGTAIL:DB 'Tail-end=00; not guaranteed$'
DIAGSP:DB 'SP=0000; not guaranteed$'

MD0012:DB 13,10,'PROCEDURE: run ENTRYTST /0012 SECOND.BIN',13,10
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
        DB 'ENTRYTST cannot print a result after it terminates.',13,10,'$'
MDGO26:DB 'Press Enter to run the test: $'
MDFAIL26:DB 'FAIL: BDOS C=0 returned to ENTRYTST.',13,10,'$'
MD0027:DB 13,10,'This restores the original entry stack and executes RET.',13,10
        DB 'SUCCESS: control returns to the CCP with a usable prompt.',13,10
        DB 'ENTRYTST cannot print a result after it terminates.',13,10,'$'
MDGO27:DB 'Press Enter to run the test: $'
MD0509:DB 13,10,'Run these three commands and follow each prompt:',13,10
        DB '  ENTRYTST /0026   (BDOS Function 0)',13,10
        DB '  ENTRYTST /0027   (entry RET)',13,10
        DB '  ENTRYTST /0595   (JMP 0000h / WBOOT)',13,10
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
        DB 'ENTRYTST cannot continue across the reset.',13,10,'$'
MD0595:DB 13,10,'This jumps through 0000h to invoke WBOOT.',13,10
        DB 'SUCCESS: CP/M reconstructs a usable CCP prompt.',13,10
        DB 'ENTRYTST cannot print a result after WBOOT.',13,10,'$'
MDGO95:DB 'Press Enter to run the test: $'
MD0600:DB 13,10,'PREREQUISITE: documented BIOS disk profile and scratch disk.',13,10
        DB 'Prepare the expendable disk first with SCRATCH /BLANK.',13,10
        DB '1. Record sector size, numbering, translation, and error codes.',13,10
        DB '2. Run ENTRYTST /0617 to validate public DPH/DPB access.',13,10
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

O0001: DB 'Program began at 0100h$'
O0003: DB 'TPA lower boundary is 0100h$'
O0005: DB 'JMP at 0000h is warm start$'
O0006: DB 'IOBYTE resides at 0003h$'
O0008: DB 'JMP at 0005h is BDOS gateway$'
O0009: DB 'Page-zero gateway roles present$'
O0011: DB 'First default FCB is at 005Ch$'
O0012: DB 'DRI-CCP: Run: ENTRYTST /0012 SECOND.BIN$'
O0014: DB 'Use /0014 A:AB*.C?M$'
O0015: DB 'Use /0015 mixed.txt$'
O0017: DB 'Tail count read from 0080h$'
O0018: DB 'Tail text begins at 0081h$'
O0020: DB 'Use /0020 mixed Case; tail must uppercase$'
O0021: DB 'Tail-end byte observed$'
O0023: DB 'Entry DMA was 0080h$'
O0024: DB 'Tail and default DMA overlap$'
O0026: DB 'Run ENTRYTST /0026 manually$'
O0027: DB 'Run ENTRYTST /0027 manually$'
O0032: DB 'Extended registers unspecified$'
O0033: DB 'Flags/interrupt unspecified$'
O0509: DB 'Run ENTRYTST /0509 manually$'
O0511: DB 'Open FCBs need explicit close$'
O0533: DB 'BDOS is not reentrant$'
O0537: DB 'BDOS ready at transient entry$'
O0539: DB 'Entry stack recorded$'
O0589: DB 'BDOS ceiling lies above program$'
O0590: DB 'Run ENTRYTST /0590 manually$'
O0591: DB 'Application owns constraints$'
O0592: DB 'Entry stack may be overlayable$'
O0593: DB 'Run ENTRYTST /0593 manually$'
O0594: DB 'BOOT need not clear all memory$'
O0595: DB 'Run ENTRYTST /0595 manually$'
O0596: DB 'Residual WBOOT state varies$'
O0597: DB 'Post-WBOOT console state varies$'
O0598: DB 'WBOOT vector present at 0000h$'
O0599: DB 'Function 31 returned a DPB$'
O0600: DB 'Run ENTRYTST /0600 manually$'
O0601: DB 'BIOS internals vary by profile$'
O0602: DB 'Function 40 consumed scratch FCB$'
O0603: DB 'Intervening records were zero$'
O0604: DB 'Sparse-hole behavior varies$'
O0605: DB 'Function 40 returned success$'
O0606: DB 'Run ENTRYTST /0606 manually$'
O0607: DB 'Run ENTRYTST /0607 manually$'
O0608: DB 'IOBYTE reassignment was visible$'
O0609: DB 'IOBYTE read/write was coherent$'
O0610: DB 'Other IOBYTE fields preserved$'
O0611: DB 'Assignment need not prove I/O$'
O0612: DB 'Run ENTRYTST /0612 manually$'
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

WILDFCB:DB 0,'ENTRYTST','COM',0,0,0,0
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
        END     START
