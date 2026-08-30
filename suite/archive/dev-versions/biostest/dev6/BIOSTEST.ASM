; BetterCP/M executable conformance suite - BIOSTEST
; Version 0.1.0-dev6 - guarded BIOS disk-call tracing
; Intel 8080 instruction subset; accepted by z80asm and CP/M M80 in .Z80 mode.
;
; Dev1 established the public interface and BIO-001 through BIO-023.
; Dev2 completes the catalog with BIO-024 through BIO-046. It does not turn a
; shallow pointer/call smoke test into a conformance PASS.  Required rows name
; the controlled procedure still needed; portability and scope rows explain
; why no baseline PASS/FAIL is assigned.

        ORG     0100H
BDOS    EQU     0005H
NCASES  EQU     46

START:  LD      SP,STACKTOP
        LD      HL,0
        PUSH    HL
        CALL    PARSE
        CP      1
        JP      Z,HELP
        CP      2
        JP      Z,LIST
        CP      3
        JP      Z,RUNALL
        CP      8
        JP      Z,RUNSAFE
        CP      4
        JP      Z,RUNONE
        CP      5
        JP      Z,INFO
        CP      6
        JP      Z,HRESULTS
        CP      7
        JP      Z,HPROFILES
        LD      DE,BADSEL
        CALL    PUTS
        RET

; Return A=1 help, 2 list, 3 all, 4 numeric, 5 info,
; 6 help-results, 7 help-profiles, or 8 safe.
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
        CP      'L'
        JP      Z,PARSEL
        CP      'A'
        JP      Z,PARSEA
        CP      'S'
        JP      Z,PARSES
        CP      'I'
        JP      Z,PARSEI
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
        CALL    PUTS
        RET
LIST:  LD      DE,LSTMSG
        CALL    PUTS
        RET
INFO:  LD      DE,INFMSG
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

RUNALL:CALL    AUTOTESTS
        CALL    CONTROLGATE
        JP      RUNROWS
RUNSAFE:
        CALL    AUTOTESTS
RUNROWS:
        LD      DE,HEADMSG
        CALL    PUTS
        LD      HL,CASES
        LD      B,NCASES
RALOOP:PUSH    BC
        PUSH    HL
        CALL    PRINTROW
        POP     HL
        LD      DE,8
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RALOOP
        JP      SUMMARY

RUNONE:
        CALL    AUTOTESTS
        CALL    ISCONTROL
        OR      A
        CALL    NZ,CONTROLGATE
        LD      HL,CASES
        LD      B,NCASES
ROLOOP:PUSH    BC
        PUSH    HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      DE,SELBUF
        LD      C,4
ROCMP: LD      A,(DE)
        CP      (HL)
        JP      NZ,RONEXT
        INC     DE
        INC     HL
        DEC     C
        JP      NZ,ROCMP
        POP     HL
        POP     BC
        LD      DE,HEADMSG
        CALL    PUTS
        CALL    PRINTROW
        CALL    SHOWDETAIL
        LD      DE,ONESUM
        CALL    PUTS
        RET
RONEXT:POP     HL
        LD      DE,8
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,ROLOOP
        LD      DE,BADSEL
        CALL    PUTS
        RET

; Each table row contains pointers to item, status, class, and observation.
PRINTROW:
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        CALL    PUTS
        LD      DE,SP2
        CALL    PUTS
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        CALL    PUTS
        LD      DE,SP2
        CALL    PUTS
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        CALL    PUTS
        LD      DE,SP2
        CALL    PUTS
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        CALL    PUTS
        LD      DE,CRLF
        JP      PUTS

PUTS:  PUSH    HL
        PUSH    BC
        LD      C,9
        CALL    BDOS
        POP     BC
        POP     HL
        RET

; Return A=1 only for the seven controlled-disk selectors implemented here.
ISCONTROL:
        LD      A,(SELBUF)
        CP      '0'
        JP      NZ,ICNO
        LD      A,(SELBUF+1)
        CP      '4'
        JP      NZ,ICNO
        LD      A,(SELBUF+2)
        CP      '2'
        JP      Z,IC42
        CP      '3'
        JP      Z,IC43
        CP      '4'
        JP      Z,IC44
        CP      '5'
        JP      Z,IC45
ICNO:  XOR     A
        RET
IC42:  LD      A,(SELBUF+3)
        CP      '4'
        JP      C,ICNO
        CP      '8'
        JP      NC,ICNO
        LD      A,1
        RET
IC43:  LD      A,(SELBUF+3)
        CP      '1'
        JP      C,ICNO
        CP      '4'
        JP      NC,ICNO
        LD      A,1
        RET
IC44:  LD      A,(SELBUF+3)
        CP      '9'
        JP      NZ,ICNO
        LD      A,1
        RET
IC45:  LD      A,(SELBUF+3)
        CP      '0'
        JP      Z,ICYES
        CP      '4'
        JP      Z,ICYES
        CP      '6'
        JP      Z,ICYES
        CP      '8'
        JP      NZ,ICNO
ICYES: LD      A,1
        RET

; Obtain a distinct, expendable disk prepared by SCRATCH /BLANK.  Q leaves
; every controlled row UNTESTED.  The confirmation is deliberately local to
; BIOSTEST because the one-record lifecycle changes the directory temporarily.
CONTROLGATE:
        CALL    SAVEENV
CGASK: LD      DE,CGMSG
        CALL    PUTS
        CALL    GETKEY
        CP      'Q'
        RET     Z
        CP      'B'
        JP      C,CGBAD
        CP      'P'+1
        JP      NC,CGBAD
        SUB     'A'
        LD      B,A
        LD      A,(OLDDRV)
        CP      B
        JP      Z,CGSAME
        LD      A,B
        LD      (SCRDRV),A
        INC     A
        LD      (TESTFCB),A
        LD      DE,CGCONF
        CALL    PUTS
        CALL    GETKEY
        CP      'Y'
        RET     NZ
        CALL    RUNCONTROL
        RET
CGBAD: LD      DE,CGBADMSG
        CALL    PUTS
        JP      CGASK
CGSAME:LD      DE,CGSAMEMSG
        CALL    PUTS
        JP      CGASK

SAVEENV:
        LD      C,25
        CALL    BDOS
        LD      (OLDDRV),A
        LD      E,0FFH
        LD      C,32
        CALL    BDOS
        LD      (OLDUSR),A
        RET
RESTENV:
        LD      DE,0080H
        LD      C,26
        CALL    BDOS
        LD      C,13
        CALL    BDOS
        LD      A,(OLDUSR)
        LD      E,A
        LD      C,32
        CALL    BDOS
        LD      A,(OLDDRV)
        LD      E,A
        LD      C,14
        CALL    BDOS
        RET
GETKEY:LD      C,1
        CALL    BDOS
        AND     5FH
        RET

; Run every controlled probe in a fixed order so the blank-state checks occur
; before the temporary file lifecycle.  SETRESULT converts each real oracle
; result to PASS/FAIL and increments the aggregate counters.
RUNCONTROL:
        XOR     A
        LD      E,A
        LD      C,32
        CALL    BDOS
        CALL    SELECTSCR
        LD      DE,R0424
        CALL    PUTS
        CALL    T0424
        LD      HL,CASES+8
        LD      DE,V0424
        CALL    SETRESULT
        LD      DE,R0425
        CALL    PUTS
        CALL    T0425
        LD      HL,CASES+16
        LD      DE,V0425
        CALL    SETRESULT
        LD      DE,R0426
        CALL    PUTS
        CALL    T0426
        LD      HL,CASES+24
        LD      DE,V0426
        CALL    SETRESULT
        LD      DE,R0427
        CALL    PUTS
        CALL    T0427
        LD      HL,CASES+32
        LD      DE,V0427
        CALL    SETRESULT
        LD      DE,R0431
        CALL    PUTS
        CALL    T0431
        LD      HL,CASES+64
        LD      DE,V0431
        CALL    SETRESULT
        LD      DE,R0432
        CALL    PUTS
        CALL    T0432
        LD      HL,CASES+72
        LD      DE,V0432
        CALL    SETRESULT
        LD      DE,R0433
        CALL    PUTS
        CALL    T0433
        LD      HL,CASES+80
        LD      DE,V0433
        CALL    SETRESULT
        LD      DE,RTRACE
        CALL    PUTS
        CALL    RUNTRACE
        OR      A
        LD      A,23
        JP      NZ,RCREM
        LD      A,(TRACECOUNT)
        LD      B,A
        LD      A,23
        SUB     B
RCREM:
        LD      (REMCNT),A
        CALL    RESTENV
        RET

SELECTSCR:
        LD      A,(SCRDRV)
        LD      E,A
        LD      C,14
        CALL    BDOS
        RET

; Query and retain the current public DPB and allocation-vector pointers.
GETMETA:
        LD      C,31
        CALL    BDOS
        LD      A,H
        OR      L
        JP      Z,TFAIL
        LD      (DPBPTR),HL
        CALL    VALIDDPB
        OR      A
        RET     NZ
        LD      C,27
        CALL    BDOS
        LD      A,H
        OR      L
        JP      Z,TFAIL
        LD      (ALVPTR),HL
        XOR     A
        RET

; Validate the public 15-byte DPB structurally without imposing one geometry.
; SPT must be nonzero; BSH is bounded and BLM must equal 2^BSH-1; DSM, DRM,
; and the directory-reservation bitmap must describe usable media.
VALIDDPB:
        PUSH    HL
        LD      A,(HL)
        INC     HL
        OR      (HL)
        JP      Z,VDFAIL
        INC     HL
        LD      B,(HL)             ; BSH
        LD      A,B
        CP      8
        JP      NC,VDFAIL
        LD      A,1
VDSH:  DEC     B
        JP      M,VDSHDONE
        ADD     A,A
        JP      VDSH
VDSHDONE:
        DEC     A
        INC     HL
        CP      (HL)               ; BLM
        JP      NZ,VDFAIL
        INC     HL                 ; EXM
        INC     HL                 ; DSM low
        LD      A,(HL)
        INC     HL
        OR      (HL)
        JP      Z,VDFAIL
        INC     HL                 ; DRM low
        LD      A,(HL)
        INC     HL
        OR      (HL)
        JP      Z,VDFAIL
        INC     HL                 ; AL0
        LD      A,(HL)
        INC     HL                 ; AL1
        OR      (HL)
        JP      Z,VDFAIL
        POP     HL
        XOR     A
        RET
VDFAIL:POP     HL
TFAIL: LD      A,1
        RET

T0424: CALL    SELECTSCR
        CALL    GETMETA
        RET

; On a SCRATCH /BLANK disk, the two directory-reservation bytes must match
; AL0/AL1 and every represented data block beyond them must be free.
T0425: CALL    SELECTSCR
        CALL    GETMETA
        OR      A
        RET     NZ
        CALL    ALVLENGTH
        LD      A,D
        OR      A
        JP      NZ,TFAIL
        LD      A,E
        CP      2
        JP      C,TFAIL
        LD      B,A
        LD      HL,(ALVPTR)
        INC     HL
        INC     HL
        DEC     B
        DEC     B
T25LP: LD      A,B
        OR      A
        JP      Z,TPASS
        LD      A,(HL)
        OR      A
        JP      NZ,TFAIL
        INC     HL
        DEC     B
        JP      T25LP

T0426: CALL    SELECTSCR
        CALL    GETMETA
        OR      A
        RET     NZ
        LD      HL,(DPBPTR)
        LD      DE,9
        ADD     HL,DE
        LD      B,(HL)             ; AL0
        INC     HL
        LD      C,(HL)             ; AL1
        LD      HL,(ALVPTR)
        LD      A,(HL)
        CP      B
        JP      NZ,TFAIL
        INC     HL
        LD      A,(HL)
        CP      C
        JP      NZ,TFAIL
TPASS: XOR     A
        RET

; Return DE=(DSM/8)+1, the number of bytes required to represent blocks
; zero through DSM inclusive.
ALVLENGTH:
        LD      HL,(DPBPTR)
        LD      DE,5
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        XOR     A
        LD      A,D
        RRA
        LD      D,A
        LD      A,E
        RRA
        LD      E,A
        XOR     A
        LD      A,D
        RRA
        LD      D,A
        LD      A,E
        RRA
        LD      E,A
        XOR     A
        LD      A,D
        RRA
        LD      D,A
        LD      A,E
        RRA
        LD      E,A
        INC     DE
        RET

; Create, write, close, and delete one record.  The allocated block's ALV bit
; must become one after the write and return to zero after successful Delete.
T0427: CALL    SELECTSCR
        CALL    GETMETA
        OR      A
        RET     NZ
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS                ; remove stale interrupted-run fixture
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        LD      DE,E27MAKE
        JP      Z,T27ABORT
        LD      DE,TESTDMA
        LD      C,26
        CALL    BDOS
        LD      DE,TESTFCB
        LD      C,21
        CALL    BDOS
        OR      A
        LD      DE,E27WRITE
        JP      NZ,T27ABORT
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        CP      0FFH
        LD      DE,E27CLOSE
        JP      Z,T27ABORT
        CALL    FCBLOCK
        EX      DE,HL
        LD      (TESTBLK),HL
        EX      DE,HL
        LD      A,D
        OR      E
        JP      NZ,T27HAVE
        LD      DE,E27BLOCK
        JP      T27ABORT
T27HAVE:
        PUSH    DE
        LD      DE,D27BLOCK
        CALL    PUTS
        POP     DE
        CALL    ALVBIT
        OR      A
        LD      DE,E27SET
        JP      Z,T27ABORT
        LD      DE,D27SET
        CALL    PUTS
        LD      A,1
        LD      (T27WROTE),A
        JP      T27DELETE
T27DELETE:
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS
        CP      0FFH
        LD      DE,E27DELETE
        JP      Z,T27ERR
        LD      DE,D27DELETE
        CALL    PUTS
        LD      C,27
        CALL    BDOS
        LD      (ALVPTR),HL
        LD      HL,(TESTBLK)
        EX      DE,HL
        CALL    ALVBIT
        LD      B,A
        LD      A,(T27WROTE)
        OR      A
        LD      DE,E27STATE
        JP      Z,T27ERR
        LD      A,B
        OR      A
        LD      DE,E27CLEAR
        JP      NZ,T27ERR
        XOR     A
        RET
T27ABORT:
        PUSH    DE
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS
        POP     DE
T27ERR:CALL    PUTS
        JP      TFAIL

INITFCB:
        LD      HL,TESTFCB+1
        LD      B,35
        XOR     A
IFCLR: LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,IFCLR
        LD      HL,TNAME
        LD      DE,TESTFCB+1
        LD      B,11
IFNAME:LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,IFNAME
        RET

; Decode the first allocation entry according to DSM width.
FCBLOCK:
        LD      HL,(DPBPTR)
        LD      DE,6
        ADD     HL,DE
        LD      A,(HL)             ; DSM high
        OR      A
        LD      HL,TESTFCB+16
        JP      NZ,FBWORD
        LD      E,(HL)
        LD      D,0
        RET
FBWORD:LD      E,(HL)
        INC     HL
        LD      D,(HL)
        RET

; Return A=nonzero when allocation block DE is set in the current ALV.
ALVBIT:LD      HL,(ALVPTR)
ABBYTE:LD      A,D
        OR      A
        JP      NZ,ABSUB
        LD      A,E
        CP      8
        JP      C,ABMASK
ABSUB: LD      A,E
        SUB     8
        LD      E,A
        LD      A,D
        SBC     A,0
        LD      D,A
        INC     HL
        JP      ABBYTE
ABMASK:LD      B,E
        LD      C,080H
ABSHIFT:
        LD      A,B
        OR      A
        JP      Z,ABTEST
        LD      A,C
        OR      A
        RRA
        LD      C,A
        DEC     B
        JP      ABSHIFT
ABTEST:LD      A,(HL)
        AND     C
        RET

T0431: CALL    CAPTURE2
        RET
T0432: CALL    CAPTURE2
        RET

; Decode complete public DPBs for the original and scratch drives.  Identical
; or distinct pointers and values are both valid; structural validity is not.
CAPTURE2:
        LD      A,(OLDDRV)
        LD      E,A
        LD      C,14
        CALL    BDOS
        LD      C,31
        CALL    BDOS
        LD      A,H
        OR      L
        JP      Z,TFAIL
        LD      (DPBOLD),HL
        CALL    VALIDDPB
        OR      A
        RET     NZ
        LD      DE,DPBCOPY1
        CALL    COPY15
        CALL    SELECTSCR
        LD      C,31
        CALL    BDOS
        LD      A,H
        OR      L
        JP      Z,TFAIL
        LD      (DPBSCR),HL
        CALL    VALIDDPB
        OR      A
        RET     NZ
        LD      DE,DPBCOPY2
        CALL    COPY15
        XOR     A
        RET
COPY15:LD      B,15
C15LP: LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,C15LP
        RET

; Change only OFF high, re-query the live object, verify the changed byte, and
; restore it before any subsequent disk operation.
T0433: CALL    SELECTSCR
        LD      C,31
        CALL    BDOS
        LD      A,H
        OR      L
        JP      Z,TFAIL
        LD      DE,14
        ADD     HL,DE
        LD      (MODPTR),HL
        LD      A,(HL)
        LD      (MODORIG),A
        XOR     1
        LD      (MODNEW),A
        LD      (HL),A
        LD      C,31
        CALL    BDOS
        LD      DE,14
        ADD     HL,DE
        LD      A,(HL)
        LD      B,A
        LD      HL,(MODPTR)
        LD      A,(MODORIG)
        LD      (HL),A
        LD      A,(MODNEW)
        CP      B
        JP      NZ,TFAIL
        XOR     A
        RET

; Guarded public-vector interposition.  The operand words of the seven disk
; JMP entries are patched only after their opcodes and write/readback behavior
; are verified.  Every exit restores all original targets.
RUNTRACE:
        CALL    TRACEINSTALL
        OR      A
        RET     NZ
        CALL    TRACEWORK
        CALL    TESTSEL
        CALL    TRACERESTORE
        CALL    TRACEJUDGE
        RET

TRACEINSTALL:
        XOR     A
        LD      (PATCHCNT),A
        LD      HL,(0001H)
        DEC     HL
        DEC     HL
        DEC     HL
        LD      (BIOSBASE),HL
        LD      DE,28
        ADD     HL,DE
        LD      DE,WRSEL
        LD      BC,ORGSEL
        CALL    PATCHONE
        OR      A
        JP      NZ,TIBAD
        LD      HL,(BIOSBASE)
        LD      DE,31
        ADD     HL,DE
        LD      DE,WRTRK
        LD      BC,ORGTRK
        CALL    PATCHONE
        OR      A
        JP      NZ,TIBAD
        LD      HL,(BIOSBASE)
        LD      DE,34
        ADD     HL,DE
        LD      DE,WRSEC
        LD      BC,ORGSEC
        CALL    PATCHONE
        OR      A
        JP      NZ,TIBAD
        LD      HL,(BIOSBASE)
        LD      DE,37
        ADD     HL,DE
        LD      DE,WRDMA
        LD      BC,ORGDMA
        CALL    PATCHONE
        OR      A
        JP      NZ,TIBAD
        LD      HL,(BIOSBASE)
        LD      DE,40
        ADD     HL,DE
        LD      DE,WRREAD
        LD      BC,ORGREAD
        CALL    PATCHONE
        OR      A
        JP      NZ,TIBAD
        LD      HL,(BIOSBASE)
        LD      DE,43
        ADD     HL,DE
        LD      DE,WRWRITE
        LD      BC,ORGWRITE
        CALL    PATCHONE
        OR      A
        JP      NZ,TIBAD
        LD      HL,(BIOSBASE)
        LD      DE,49
        ADD     HL,DE
        LD      DE,WRXLT
        LD      BC,ORGXLT
        CALL    PATCHONE
        OR      A
        RET     NZ
        CALL    PREPTRAMP
        XOR     A
        RET
TIBAD: CALL    TRACERESTORE
        LD      DE,TRACEBAD
        CALL    PUTS
        LD      A,1
        RET

; HL=JMP operand, DE=new target, BC=word receiving original target.
PATCHONE:
        LD      (PATCHLOC),HL
        EX      DE,HL
        LD      (PATCHNEW),HL
        LD      H,B
        LD      L,C
        LD      (PATCHSAVE),HL
        LD      HL,(PATCHLOC)
        DEC     HL
        LD      A,(HL)
        CP      0C3H
        JP      NZ,TFAIL
        INC     HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        LD      HL,(PATCHSAVE)
        LD      (HL),E
        INC     HL
        LD      (HL),D
        LD      HL,(PATCHNEW)
        EX      DE,HL
        LD      HL,(PATCHLOC)
        LD      (HL),E
        INC     HL
        LD      (HL),D
        DEC     HL
        LD      A,(HL)
        CP      E
        JP      NZ,POREST
        INC     HL
        LD      A,(HL)
        CP      D
        JP      NZ,POREST
        LD      A,(PATCHCNT)
        INC     A
        LD      (PATCHCNT),A
        XOR     A
        RET
POREST:LD      HL,(PATCHSAVE)
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        LD      HL,(PATCHLOC)
        LD      A,E
        LD      (HL),A
        INC     HL
        LD      A,D
        LD      (HL),A
        JP      TFAIL

PREPTRAMP:
        LD      HL,ORGSEL
        LD      DE,CSEL+1
        CALL    COPYWORD
        LD      HL,ORGTRK
        LD      DE,JTRK+1
        CALL    COPYWORD
        LD      HL,ORGSEC
        LD      DE,JSEC+1
        CALL    COPYWORD
        LD      HL,ORGDMA
        LD      DE,JDMA+1
        CALL    COPYWORD
        LD      HL,ORGREAD
        LD      DE,CREAD+1
        CALL    COPYWORD
        LD      HL,ORGWRITE
        LD      DE,CWRITE+1
        CALL    COPYWORD
        LD      HL,ORGXLT
        LD      DE,CXLT+1
COPYWORD:
        LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        LD      A,(HL)
        LD      (DE),A
        RET

TRACERESTORE:
        LD      A,(PATCHCNT)
        CP      7
        CALL    NC,RXLT
        LD      A,(PATCHCNT)
        CP      6
        CALL    NC,RWRITE
        LD      A,(PATCHCNT)
        CP      5
        CALL    NC,RREAD
        LD      A,(PATCHCNT)
        CP      4
        CALL    NC,RDMA
        LD      A,(PATCHCNT)
        CP      3
        CALL    NC,RSEC
        LD      A,(PATCHCNT)
        CP      2
        CALL    NC,RTRK
        LD      A,(PATCHCNT)
        OR      A
        CALL    NZ,RSEL
        XOR     A
        LD      (PATCHCNT),A
        RET
RXLT:  LD      DE,49
        LD      BC,ORGXLT
        JP      RESTONE
RWRITE:LD      DE,43
        LD      BC,ORGWRITE
        JP      RESTONE
RREAD: LD      DE,40
        LD      BC,ORGREAD
        JP      RESTONE
RDMA:  LD      DE,37
        LD      BC,ORGDMA
        JP      RESTONE
RSEC:  LD      DE,34
        LD      BC,ORGSEC
        JP      RESTONE
RTRK:  LD      DE,31
        LD      BC,ORGTRK
        JP      RESTONE
RSEL:  LD      DE,28
        LD      BC,ORGSEL
RESTONE:
        LD      HL,(BIOSBASE)
        ADD     HL,DE
        LD      A,(BC)
        LD      (HL),A
        INC     BC
        INC     HL
        LD      A,(BC)
        LD      (HL),A
        RET

TRACEWORK:
        LD      HL,TRACELOG
        LD      B,TRACEEND-TRACELOG
        XOR     A
TWCLR: LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,TWCLR
        CALL    SELECTSCR
        LD      DE,TWMAKE
        CALL    PUTS
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        JP      Z,TWFAIL
        LD      DE,TWWR1
        CALL    PUTS
        LD      DE,TESTDMA
        LD      C,26
        CALL    BDOS
        LD      DE,TESTFCB
        LD      C,21
        CALL    BDOS
        OR      A
        JP      NZ,TWFAIL
        LD      DE,TWWR2
        CALL    PUTS
        LD      DE,TESTFCB
        LD      C,21
        CALL    BDOS
        OR      A
        JP      NZ,TWFAIL
        LD      DE,TWCLOSE
        CALL    PUTS
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        CP      0FFH
        JP      Z,TWFAIL
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS
        CP      0FFH
        JP      Z,TWFAIL
        XOR     A
        RET
TWFAIL:LD      A,1
        LD      (IOFAIL),A
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS
        RET

TRACEJUDGE:
        LD      A,4
        LD      (TRACECOUNT),A
        LD      A,(TRKCNT)
        OR      A
        JP      Z,TJ49F
        LD      A,(SECCNT)
        OR      A
        JP      Z,TJ49F
        LD      A,(DMACNT)
        OR      A
        JP      Z,TJ49F
        LD      A,(WRITECNT)
        OR      A
        JP      Z,TJ49F
        LD      A,(IOFAIL)
        OR      A
        JP      NZ,TJ49F
        XOR     A
        JP      TJ49S
TJ49F: LD      A,1
TJ49S: LD      HL,CASES+160
        LD      DE,V0449
        CALL    SETRESULT
        LD      A,(CONFSEL)
        LD      B,A
        LD      A,(ABSENTSEL)
        AND     B
        JP      Z,TJ50SKIP
        XOR     A
        LD      HL,CASES+168
        LD      DE,V0450
        CALL    SETRESULT
        LD      A,5
        LD      (TRACECOUNT),A
TJ50SKIP:
        LD      A,(XLTCHAIN)
        XOR     1
        LD      HL,CASES+200
        LD      DE,V0454
        CALL    SETRESULT
        LD      A,(APPDMA)
        LD      B,A
        LD      A,(DIRDMA)
        AND     B
        XOR     1
        LD      HL,CASES+216
        LD      DE,V0456
        CALL    SETRESULT
        LD      A,(WRTYPES)
        CP      7
        LD      A,0
        JP      Z,TJ58S
        INC     A
TJ58S: LD      HL,CASES+232
        LD      DE,V0458
        CALL    SETRESULT
        XOR     A
        RET

; Exercise the saved SELDSK implementation directly.  A configured scratch
; drive must return a DPH; at least one unconfigured A-P number must return 0.
TESTSEL:
        LD      A,(SCRDRV)
        LD      C,A
        CALL    CSEL
        LD      A,H
        OR      L
        JP      Z,TSABS
        LD      A,1
        LD      (CONFSEL),A
TSABS: LD      C,15
TSLOOP:LD      A,C
        LD      B,A
        LD      A,(SCRDRV)
        CP      B
        JP      Z,TSNEXT
        CALL    CSEL
        LD      A,H
        OR      L
        JP      NZ,TSNEXT
        LD      A,1
        LD      (ABSENTSEL),A
        JP      TSREST
TSNEXT:DEC     C
        JP      P,TSLOOP
TSREST:CALL    SELECTSCR
        RET

; Wrappers preserve all documented inputs and delegate to the saved target.
WRSEL: LD      A,C
        LD      (LASTSEL),A
CSEL:  CALL    0000H
        LD      (SELRESULT),HL
        LD      A,(SELCNT)
        INC     A
        LD      (SELCNT),A
        RET
WRTRK: PUSH    HL
        LD      H,B
        LD      L,C
        LD      (LASTTRK),HL
        POP     HL
        PUSH    AF
        LD      A,(TRKCNT)
        INC     A
        LD      (TRKCNT),A
        POP     AF
JTRK:  JP      0000H
WRSEC: PUSH    HL
        LD      H,B
        LD      L,C
        LD      (LASTSEC),HL
        LD      A,(XLTOUT)
        CP      C
        JP      NZ,WSNO
        LD      A,(XLTOUT+1)
        CP      B
        JP      NZ,WSNO
        LD      A,(XLTVALID)
        OR      A
        JP      Z,WSNO
        LD      A,1
        LD      (XLTCHAIN),A
WSNO:  XOR     A
        LD      (XLTVALID),A
        POP     HL
        PUSH    AF
        LD      A,(SECCNT)
        INC     A
        LD      (SECCNT),A
        POP     AF
JSEC:  JP      0000H
WRDMA: PUSH    HL
        LD      H,B
        LD      L,C
        LD      (LASTDMA),HL
        LD      A,TESTDMA AND 0FFH
        CP      C
        JP      NZ,WDOTHER
        LD      A,TESTDMA/256
        CP      B
        LD      A,1
        JP      Z,WDAPP
WDOTHER:
        LD      A,1
        LD      (DIRDMA),A
        JP      WDDONE
WDAPP: LD      (APPDMA),A
WDDONE:POP     HL
        PUSH    AF
        LD      A,(DMACNT)
        INC     A
        LD      (DMACNT),A
        POP     AF
JDMA:  JP      0000H
WRREAD:
CREAD: CALL    0000H
        OR      A
        JP      Z,WRROK
        LD      (IOFAIL),A
WRROK: LD      (WRSTATUS),A
        LD      A,(READCNT)
        INC     A
        LD      (READCNT),A
        LD      A,(WRSTATUS)
        RET
WRWRITE:
        PUSH    BC
        PUSH    AF
        LD      A,C
        CP      1
        JP      Z,WW1
        CP      2
        JP      Z,WW2
        LD      A,1
        JP      WWSET
WW1:   LD      A,2
        JP      WWSET
WW2:   LD      A,4
WWSET: LD      B,A
        LD      A,(WRTYPES)
        OR      B
        LD      (WRTYPES),A
        POP     AF
        POP     BC
CWRITE:CALL    0000H
        OR      A
        JP      Z,WWOK
        LD      (IOFAIL),A
WWOK:  LD      (WRSTATUS),A
        LD      A,(WRITECNT)
        INC     A
        LD      (WRITECNT),A
        LD      A,(WRSTATUS)
        RET
WRXLT: PUSH    HL
        LD      H,B
        LD      L,C
        LD      (XLTIN),HL
        EX      DE,HL
        LD      (XLTPTR),HL
        EX      DE,HL
        POP     HL
CXLT:  CALL    0000H
        LD      (XLTOUT),HL
        LD      A,1
        LD      (XLTVALID),A
        LD      A,(XLTCNT)
        INC     A
        LD      (XLTCNT),A
        RET

; Run only probes whose complete oracle can be evaluated without destructive
; media, terminal loss of control, or an undeclared physical-device provider.
; The table is in the transient's writable TPA, so each result replaces that
; row's initial UNTESTED status and explanatory observation.
AUTOTESTS:
        XOR     A
        LD      (PASSCNT),A
        LD      (FAILCNT),A
        LD      A,30
        LD      (REMCNT),A
        CALL    P0443
        LD      HL,CASES+128
        LD      DE,V0443
        CALL    SETRESULT
        CALL    P0451
        LD      HL,CASES+176
        LD      DE,V0451
        CALL    SETRESULT
        CALL    P0461
        LD      HL,CASES+256
        LD      DE,V0461
        CALL    SETRESULT
        CALL    P0463
        LD      HL,CASES+272
        LD      DE,V0463
        CALL    SETRESULT
        CALL    P0622
        LD      HL,CASES+360
        LD      DE,V0622
        CALL    SETRESULT
        RET

; A=0 PASS, nonzero FAIL; HL addresses the row and DE the passing evidence.
SETRESULT:
        PUSH    AF
        PUSH    HL
        LD      BC,6
        ADD     HL,BC
        LD      (HL),E
        INC     HL
        LD      (HL),D
        POP     HL
        INC     HL
        INC     HL
        POP     AF
        OR      A
        LD      DE,STPASS
        JP      NZ,SRFAIL
        LD      A,(PASSCNT)
        INC     A
        LD      (PASSCNT),A
        JP      SRSTORE
SRFAIL:LD      A,(FAILCNT)
        INC     A
        LD      (FAILCNT),A
        LD      DE,STFAIL
        PUSH    HL
        LD      BC,4
        ADD     HL,BC
        LD      BC,VFAIL
        LD      (HL),C
        INC     HL
        LD      (HL),B
        POP     HL
SRSTORE:LD     (HL),E
        INC     HL
        LD      (HL),D
        RET

; Aggregate counters are calculated from the returning probes rather than
; printed as a predetermined success claim.
SUMMARY:LD     DE,SUMA
        CALL    PUTS
        LD      A,(PASSCNT)
        CALL    PUTDEC
        LD      DE,SUMB
        CALL    PUTS
        LD      A,(FAILCNT)
        CALL    PUTDEC
        LD      DE,SUMC1
        CALL    PUTS
        LD      A,(REMCNT)
        CALL    PUTDEC
        LD      DE,SUMC2
        JP      PUTS
PUTDEC:LD      B,0
PD10:  CP      10
        JP      C,PDDONE
        SUB     10
        INC     B
        JP      PD10
PDDONE:LD      (DECTMP),A
        LD      A,B
        OR      A
        JP      Z,PDONES
        ADD     A,'0'
        LD      E,A
        LD      C,2
        CALL    BDOS
PDONES:LD      A,(DECTMP)
        ADD     A,'0'
        LD      E,A
        LD      C,2
        JP      BDOS

; Selected nonreturning/provider rows receive an actionable procedure. The
; row itself names the exact oracle; these category instructions define the
; authority, evidence, failure handling, and restoration common to the group.
SHOWDETAIL:
        CALL    ISCONTROL
        OR      A
        JP      Z,DETSTART
        LD      A,(REMCNT)
        CP      23
        RET     Z                  ; selected controlled oracle already ran
DETSTART:
        LD      A,(SELBUF)
        CP      '0'
        RET     NZ
        LD      A,(SELBUF+1)
        CP      '6'
        JP      Z,DET06
        CP      '4'
        RET     NZ
        LD      A,(SELBUF+2)
        CP      '2'
        JP      Z,DET42
        CP      '3'
        JP      Z,DET43
        CP      '4'
        JP      Z,DET44
        CP      '5'
        JP      Z,DET45
        CP      '6'
        JP      Z,DET46
        CP      '7'
        JP      Z,DETDEV
        RET
DET06: LD      A,(SELBUF+2)
        CP      '2'
        RET     NZ
        RET
DET42: LD      A,(SELBUF+3)
        CP      '4'
        RET     C
        CP      '8'
        JP      C,DETDISK
        RET
DET43: LD      A,(SELBUF+3)
        CP      '1'
        JP      Z,DETDPB
        CP      '2'
        JP      Z,DETDPB
        CP      '3'
        JP      Z,DETDPB
        CP      '5'
        JP      Z,DETFN37
        CP      '7'
        JP      Z,DETDEV
        CP      '9'
        JP      Z,DETDEV
        RET
DET44: LD      A,(SELBUF+3)
        CP      '5'
        JP      Z,DETDEV
        CP      '8'
        JP      Z,DETDEV
        CP      '9'
        JP      Z,DETDISK
        RET
DET45: LD      A,(SELBUF+3)
        CP      '3'
        RET     C
        CP      '9'
        JP      C,DETDISK
        RET
DET46: LD      A,(SELBUF+3)
        CP      '4'
        RET     C
        CP      '7'
        JP      C,DETBOOT
        CP      '8'
        JP      Z,DETDEV
        CP      '9'
        JP      Z,DETDEV
        RET
DETDISK:LD     DE,DISKPROC
        JP      PUTS
DETDPB:LD      DE,DPBPROC
        JP      PUTS
DETBOOT:LD     DE,BOOTPROC
        JP      PUTS
DETDEV:LD      DE,DEVPROC
        JP      PUTS
DETFN37:LD     DE,FN37PROC
        JP      PUTS

; Function 7/8 must expose one coherent IOBYTE. Restore the entry value on
; every path so this read/write probe has no lasting system-state effect.
P0443: LD      C,7
        CALL    BDOS
        LD      (IOBORIG),A
        XOR     1
        LD      (IOBNEW),A
        LD      E,A
        LD      C,8
        CALL    BDOS
        LD      C,7
        CALL    BDOS
        LD      HL,IOBNEW
        CP      (HL)
        XOR     A
        LD      (PROBERES),A
        JP      Z,P43MEM
        INC     A
        LD      (PROBERES),A
P43MEM:LD      A,(0003H)
        LD      HL,IOBNEW
        CP      (HL)
        JP      Z,P43REST
        LD      A,(PROBERES)
        INC     A
        LD      (PROBERES),A
P43REST:LD     A,(IOBORIG)
        LD      E,A
        LD      C,8
        CALL    BDOS
        LD      A,(PROBERES)
        RET

; Select the current drive through the public SELDSK vector and validate the
; documented DPH pointers. The DPB pointer must agree with BDOS Function 31.
P0451: LD      C,25
        CALL    BDOS
        LD      C,A
        LD      HL,(0001H)
        LD      DE,24             ; WBOOT entry + (8 * 3) = SELDSK
        ADD     HL,DE
        LD      E,0
        CALL    CALLHL
        LD      A,H
        OR      L
        RET     Z
        LD      (DPHPTR),HL
        LD      DE,8
        ADD     HL,DE
        LD      A,(HL)
        INC     HL
        OR      (HL)            ; directory buffer pointer
        RET     Z
        INC     HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)          ; public DPB pointer
        LD      A,D
        OR      E
        RET     Z
        PUSH    DE
        LD      C,31
        CALL    BDOS
        POP     DE
        LD      A,H
        CP      D
        JP      NZ,PFAIL
        LD      A,L
        CP      E
        JP      NZ,PFAIL
        LD      HL,(DPHPTR)
        LD      DE,14
        ADD     HL,DE
        LD      A,(HL)
        INC     HL
        OR      (HL)            ; allocation-vector pointer
        JP      Z,PFAIL
        XOR     A
        RET

; Derive the BIOS base solely from the WBOOT gateway and verify all seventeen
; consecutive three-byte public JMP entries.
P0461: LD      HL,(0001H)
        DEC     HL
        DEC     HL
        DEC     HL
        LD      B,17
P61LP: LD      A,(HL)
        CP      0C3H
        JP      NZ,PFAIL
        INC     HL
        INC     HL
        INC     HL
        DEC     B
        JP      NZ,P61LP
        XOR     A
        RET
P0463: JP      P0461

; Execute two independently placed instruction sequences after changing their
; immediate operands in place. Both later instruction fetches must observe the
; modified TPA bytes.
P0622: LD      HL,SMCODE
        LD      DE,SMBUF1
        LD      B,4
        CALL    COPY4
        LD      HL,SMCODE
        LD      DE,SMBUF2
        LD      B,4
        CALL    COPY4
        LD      A,05AH
        LD      (SMBUF1+1),A
        LD      A,0A5H
        LD      (SMBUF2+1),A
        LD      HL,SMBUF1
        CALL    CALLHL
        CP      05AH
        JP      NZ,PFAIL
        LD      HL,SMBUF2
        CALL    CALLHL
        CP      0A5H
        JP      NZ,PFAIL
        XOR     A
        RET
COPY4: LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,COPY4
        RET
CALLHL:LD      DE,CALLRET
        PUSH    DE
        JP      (HL)
CALLRET:RET
PFAIL: LD      A,1
        RET

HLPMSG:DB 13,10,'BIOSTEST 0.1.0-dev6',13,10,13,10
        DB '  BIOSTEST /NNNN   Run or explain one ledger item',13,10
        DB '  BIOSTEST /ALL    Run all returning checks and observations',13,10
        DB '  BIOSTEST /SAFE   Run rows requiring no destructive media',13,10
        DB '  BIOSTEST /LIST   List implemented ledger items',13,10
        DB '  BIOSTEST /H      Show this help',13,10
        DB '  BIOSTEST /INFO   Show build information',13,10,'$'
INFMSG:DB 13,10,'BetterCP/M BIOSTEST 0.1.0-dev6',13,10
        DB 'Catalog: BIO-001 through BIO-046 (46 rows)',13,10
        DB 'Processor required: Intel 8080',13,10
        DB 'Returning checks: 5 safe, 12 controlled-disk',13,10,'$'
RESMSG:DB 13,10,'PASS and FAIL are emitted only after the complete oracle runs.',13,10
        DB 'UNTESTED identifies a required procedure not yet automated.',13,10
        DB 'OBSERVED records a permitted variation without claiming PASS.',13,10,'$'
PRFMSG:DB 13,10,'OPT-FN37: optional undocumented Function 37 compatibility.',13,10
        DB 'Device-dependent rows require a declared hardware provider.',13,10,'$'
BADSEL:DB 13,10,'Unknown selector. Use BIOSTEST /H.',13,10,'$'
HEADMSG:DB 13,10,'ITEM  STATUS    CLASS       OBSERVED',13,10
        DB '----  --------  ----------  ----------------------------------------',13,10,'$'
SUMA:   DB 'Summary: $'
SUMB:   DB ' pass, $'
SUMC1:  DB ' fail, 0 error, 11 observations',13,10,'$'
SUMC2:  DB ' scope/required/profile procedures remain untested.',13,10,'$'
ONESUM:DB 'Summary: selected row reported above.',13,10,'$'
SP2:    DB '  $'
CRLF:   DB 13,10,'$'

; Catalog text is deliberately compact enough for an 80-column terminal.
LSTMSG:DB 13,10
        DB '0423 OUT SCOPE  Function 34 is not Compute File Size',13,10
        DB '0424 REQUIRED   Function 27 allocation-vector pointer',13,10
        DB '0425 REQUIRED   Allocation-vector length and bit mapping',13,10
        DB '0426 REQUIRED   Reserved directory allocation bits',13,10
        DB '0427 REQUIRED   Live allocation state',13,10
        DB '0428 NOT GUAR.  Allocation-pointer address and lifetime',13,10
        DB '0429 NOT GUAR.  Application modification of allocation vector',13,10
        DB '0430 NOT GUAR.  Read-only allocation information',13,10
        DB '0431 REQUIRED   Function 31 DPB pointer and layout',13,10
        DB '0432 REQUIRED   DPB configuration and sharing',13,10
        DB '0433 REQUIRED   Documented DPB modification',13,10
        DB '0434 NOT GUAR.  DPB address and lifetime',13,10
        DB '0435 OPTIONAL   Function 37 compatibility status',13,10
        DB '0437 NOT GUAR.  Reader completion and optional-device behavior',13,10
        DB '0439 REQUIRED   Function 4 Punch convention',13,10
        DB '0441 NOT GUAR.  Character-output result values',13,10
        DB '0443 REQUIRED   Function 8 IOBYTE set',13,10
        DB '0445 REQUIRED   IOBYTE routing boundary',13,10
        DB '0447 NOT GUAR.  IOBYTE set has no initialization contract',13,10
        DB '0448 REQUIRED   Character-device DMA independence',13,10
        DB '0449 REQUIRED   Stateful BIOS disk setup',13,10
        DB '0450 REQUIRED   SELDSK result and deferral',13,10
        DB '0451 REQUIRED   Public DPH layout',13,10
        DB '0452 NOT GUAR.  DPH address and private workspace',13,10
        DB '0453 REQUIRED   Track mapping and OFF',13,10
        DB '0454 REQUIRED   Sector translation chain',13,10
        DB '0455 NOT GUAR.  Translation implementation freedom',13,10
        DB '0456 REQUIRED   BIOS DMA state',13,10
        DB '0457 REQUIRED   BIOS logical-sector transfer',13,10
        DB '0458 REQUIRED   BIOS WRITE type codes',13,10
        DB '0459 OUT SCOPE  Physical storage freedom',13,10
        DB '0460 NOT GUAR.  BIOS disk-call reentrancy',13,10
        DB '0461 REQUIRED   BIOS jump-vector structure',13,10
        DB '0462 NOT GUAR.  BIOS vector address freedom',13,10
        DB '0463 REQUIRED   BIOS-base discovery through WBOOT gateway',13,10
        DB '0464 REQUIRED   BOOT control contract',13,10
        DB '0465 REQUIRED   WBOOT control contract',13,10
        DB '0466 REQUIRED   Warm-start gateway reconstruction',13,10
        DB '0467 OUT SCOPE  Boot implementation freedom',13,10
        DB '0468 REQUIRED   BIOS console status contract',13,10
        DB '0469 REQUIRED   BIOS console input contract',13,10
        DB '0470 REQUIRED   BIOS character output contracts',13,10
        DB '0471 REQUIRED   BIOS reader contract',13,10
        DB '0472 PROFILE    LISTST result policy',13,10
        DB '0473 REQUIRED   Direct BIOS call layering',13,10
        DB '0622 REQUIRED   Self-modifying transient execution',13,10,'$'

STOUT: DB 'UNTESTED$'
STOBS: DB 'OBSERVED$'
STPASS:DB 'PASS$'
STFAIL:DB 'FAIL$'
CLREQ: DB 'REQUIRED$'
CLNG:  DB 'NOT GUAR.$'
CLOUT: DB 'OUT SCOPE$'
CLOPT: DB 'OPTIONAL$'

I0423: DB '0423$'
I0424: DB '0424$'
I0425: DB '0425$'
I0426: DB '0426$'
I0427: DB '0427$'
I0428: DB '0428$'
I0429: DB '0429$'
I0430: DB '0430$'
I0431: DB '0431$'
I0432: DB '0432$'
I0433: DB '0433$'
I0434: DB '0434$'
I0435: DB '0435$'
I0437: DB '0437$'
I0439: DB '0439$'
I0441: DB '0441$'
I0443: DB '0443$'
I0445: DB '0445$'
I0447: DB '0447$'
I0448: DB '0448$'
I0449: DB '0449$'
I0450: DB '0450$'
I0451: DB '0451$'
I0452: DB '0452$'
I0453: DB '0453$'
I0454: DB '0454$'
I0455: DB '0455$'
I0456: DB '0456$'
I0457: DB '0457$'
I0458: DB '0458$'
I0459: DB '0459$'
I0460: DB '0460$'
I0461: DB '0461$'
I0462: DB '0462$'
I0463: DB '0463$'
I0464: DB '0464$'
I0465: DB '0465$'
I0466: DB '0466$'
I0467: DB '0467$'
I0468: DB '0468$'
I0469: DB '0469$'
I0470: DB '0470$'
I0471: DB '0471$'
I0472: DB '0472$'
I0473: DB '0473$'
I0622: DB '0622$'

O0423: DB 'No baseline Function 34 assertion$'
O0424: DB 'Use SCRATCH /BLANK and two controlled disks$'
O0425: DB 'Needs DPB-derived ALV and controlled files$'
O0426: DB 'Needs controlled empty disk$'
O0427: DB 'Needs controlled one-record lifecycle$'
O0428: DB 'Fixed address/lifetime is not portable$'
O0429: DB 'Applications must not depend on ALV writes$'
O0430: DB 'Post-Function-28 ALV accuracy may vary$'
O0431: DB 'Needs two configured drives and DPB decode$'
O0432: DB 'Shared or distinct valid DPBs accepted$'
O0433: DB 'Needs guarded modify, re-query, and restore$'
O0434: DB 'Fixed DPB address/lifetime is not portable$'
O0435: DB 'Run only when OPT-FN37 is claimed$'
O0437: DB 'Reader/device provider behavior may vary$'
O0439: DB 'Needs declared punch provider$'
O0441: DB 'Character-output return values may vary$'
O0443: DB 'Needs set/query/restore IOBYTE round trip$'
O0445: DB 'Needs declared routes at multiple IOBYTE values$'
O0447: DB 'No initialization side effect is guaranteed$'
O0448: DB 'Needs device provider and DMA sentinels$'
O0449: DB 'Needs direct BIOS disk-call sequence$'
O0450: DB 'Needs configured/absent drives and deferred I/O$'
O0451: DB 'Needs current-drive DPH pointer validation$'
O0452: DB 'Fixed DPH/private workspace is not portable$'
O0453: DB 'Needs boundary tracks with nonzero OFF$'
O0454: DB 'Needs controlled nonidentity XLT$'
O0455: DB 'Table or equivalent algorithm is accepted$'
O0456: DB 'Needs application/directory DMA tracing$'
O0457: DB 'Needs successful and injected-fault transfers$'
O0458: DB 'Needs controlled WRITE type-code lifecycle$'
O0459: DB 'Physical mapping is outside the public contract$'
O0460: DB 'Nested disk-call state is not guaranteed$'
O0461: DB 'Needs independent jump-vector validation$'
O0462: DB 'No fixed BIOS vector address is portable$'
O0463: DB 'Needs page-zero-only BIOS-base discovery$'
O0464: DB 'Needs cold-start state validation$'
O0465: DB 'Needs programmed warm-restart validation$'
O0466: DB 'Needs controlled gateway reconstruction test$'
O0467: DB 'Boot implementation is outside public contract$'
O0468: DB 'Needs queued character and status transitions$'
O0469: DB 'Needs controlled raw console input$'
O0470: DB 'Needs captured bytes at each output vector$'
O0471: DB 'Needs reader and absent-device provider$'
O0472: DB 'Needs declared LISTST result profile$'
O0473: DB 'Needs direct/BDOS character comparison$'
O0622: DB 'Needs patch/execute at multiple TPA placements$'
V0443: DB 'Function 7/8 and 0003h were coherent; restored$'
V0424: DB 'Function 27 returned current scratch-disk ALV$'
V0425: DB 'DPB-derived ALV length and bits matched blank disk$'
V0426: DB 'AL0/AL1 matched reserved ALV directory bits$'
V0427: DB 'One-record block set then cleared its ALV bit$'
V0431: DB 'Decoded valid 15-byte DPBs for both drives$'
V0432: DB 'Both configured DPBs valid; sharing accepted$'
V0433: DB 'DPB field changed, re-queried, and restored$'
V0449: DB 'Traced persistent track/sector/DMA write context$'
V0450: DB 'SELDSK accepted scratch and rejected absent drive$'
V0454: DB 'SECTRAN result was passed to SETSEC$'
V0456: DB 'Traced application and directory DMA addresses$'
V0458: DB 'Observed WRITE type codes 0, 1, and 2$'
V0451: DB 'Current DPH pointers and Function 31 agreed$'
V0461: DB 'Found 17 consecutive public JMP vectors$'
V0463: DB 'BIOS base derived only from WBOOT gateway$'
V0622: DB 'Modified code executed at two TPA locations$'
VFAIL: DB 'Returning oracle check failed$'

DISKPROC:DB 13,10,'SETUP: use a disposable disk prepared by SCRATCH /BLANK and',13,10
        DB 'a declared BIOS trace/fault provider when the row requires one.',13,10
        DB 'ACTION: run the selected operation and capture its exact BIOS calls.',13,10
        DB 'SUCCESS: the trace and result match the selected ledger oracle.',13,10
        DB 'FAILURE: any wrong argument, order, transfer, or result is FAIL.',13,10
        DB 'RESTORE: discard/remount the scratch disk and reset the disk system.',13,10,'$'
DPBPROC:DB 13,10,'SETUP: mount two configured disks with declared geometries.',13,10
        DB 'ACTION: obtain and decode each DPH/DPB/ALV without fixed addresses.',13,10
        DB 'SUCCESS: every public field and selected-drive relationship agrees.',13,10
        DB 'FAILURE: a null, incoherent, or incorrectly shared object is FAIL.',13,10
        DB 'RESTORE: restore any guarded field before another BDOS disk call.',13,10,'$'
BOOTPROC:DB 13,10,'TERMINAL TEST: preserve the current gateways and capture CCP output.',13,10
        DB 'Perform the selected BOOT/WBOOT action exactly as named above.',13,10
        DB 'SUCCESS: CCP resumes and documented page-zero/DMA state is rebuilt.',13,10
        DB 'FAILURE: return to caller, hang, or invalid public state is FAIL.',13,10
        DB 'RESTORE: cold boot the pristine system image after recording evidence.',13,10,'$'
DEVPROC:DB 13,10,'SETUP: declare and connect the required reader/punch/list/console',13,10
        DB 'capture or loopback provider; record its ready/not-ready encodings.',13,10
        DB 'ACTION: run the selected raw BIOS and mediated BDOS operations.',13,10
        DB 'SUCCESS: bytes, status, nonconsumption, and layering match the oracle.',13,10
        DB 'FAILURE: transformed, lost, consumed, or misrouted data is FAIL.',13,10
        DB 'RESTORE: restore IOBYTE and drain only provider-supplied input.',13,10,'$'
FN37PROC:DB 13,10,'OPTIONAL PROFILE: select OPT-FN37 only when the candidate',13,10
        DB 'claims the undocumented Function 37 compatibility behavior.',13,10
        DB 'Test inactive, current, multiple, and read-only-vector inputs.',13,10
        DB 'SUCCESS: every declared state effect matches the profile.',13,10
        DB 'RESTORE: reset the disk system and remount pristine test media.',13,10,'$'
CGMSG: DB 13,10,'Controlled tests require a disk prepared by SCRATCH /BLANK.',13,10
        DB 'Enter its configured drive letter, or Q to skip (B-P or Q): $'
CGBADMSG:DB 13,10,'Enter a configured drive B through P, or Q.',13,10,'$'
CGSAMEMSG:DB 13,10,'The scratch drive must differ from the utility drive.',13,10,'$'
CGCONF:DB 13,10,'BIOSTEST will create and delete BTBIO.TMP, then leave the',13,10
        DB 'scratch disk empty. Continue (Y/N)? $'
R0424: DB 13,10,'Running controlled item 0424...',13,10,'$'
R0425: DB 'Running controlled item 0425...',13,10,'$'
R0426: DB 'Running controlled item 0426...',13,10,'$'
R0427: DB 'Running controlled item 0427...',13,10,'$'
R0431: DB 'Running controlled item 0431...',13,10,'$'
R0432: DB 'Running controlled item 0432...',13,10,'$'
R0433: DB 'Running controlled item 0433...',13,10,'$'
RTRACE:DB 'Installing guarded BIOS disk trace...',13,10,'$'
TRACEBAD:DB 'Trace unavailable: BIOS JMP operands are not safely writable.',13,10,'$'
TWMAKE:DB 'Trace: Make...',13,10,'$'
TWWR1: DB 'Trace: first sequential write...',13,10,'$'
TWWR2: DB 'Trace: second sequential write...',13,10,'$'
TWCLOSE:DB 'Trace: Close/Delete...',13,10,'$'
E27MAKE:DB '0427 FAIL: could not create BTBIO.TMP.',13,10,'$'
E27WRITE:DB '0427 FAIL: one-record write was rejected.',13,10,'$'
E27CLOSE:DB '0427 FAIL: close was rejected.',13,10,'$'
E27BLOCK:DB '0427 FAIL: no allocation block appeared in the FCB.',13,10,'$'
E27SET: DB '0427 FAIL: allocated block was not set in the ALV.',13,10,'$'
E27DELETE:DB '0427 FAIL: delete was rejected.',13,10,'$'
E27STATE:DB '0427 FAIL: lifecycle did not reach allocated state.',13,10,'$'
E27CLEAR:DB '0427 FAIL: released block remained set in the ALV.',13,10,'$'
D27BLOCK:DB '0427: allocation block decoded.',13,10,'$'
D27SET:DB '0427: allocation bit set after write.',13,10,'$'
D27DELETE:DB '0427: temporary file deleted.',13,10,'$'

CASES: DW I0423,STOUT,CLOUT,O0423
       DW I0424,STOUT,CLREQ,O0424
       DW I0425,STOUT,CLREQ,O0425
       DW I0426,STOUT,CLREQ,O0426
       DW I0427,STOUT,CLREQ,O0427
       DW I0428,STOBS,CLNG,O0428
       DW I0429,STOBS,CLNG,O0429
       DW I0430,STOBS,CLNG,O0430
       DW I0431,STOUT,CLREQ,O0431
       DW I0432,STOUT,CLREQ,O0432
       DW I0433,STOUT,CLREQ,O0433
       DW I0434,STOBS,CLNG,O0434
       DW I0435,STOUT,CLOPT,O0435
       DW I0437,STOBS,CLNG,O0437
       DW I0439,STOUT,CLREQ,O0439
       DW I0441,STOBS,CLNG,O0441
       DW I0443,STOUT,CLREQ,O0443
       DW I0445,STOUT,CLREQ,O0445
       DW I0447,STOBS,CLNG,O0447
       DW I0448,STOUT,CLREQ,O0448
       DW I0449,STOUT,CLREQ,O0449
       DW I0450,STOUT,CLREQ,O0450
       DW I0451,STOUT,CLREQ,O0451
       DW I0452,STOBS,CLNG,O0452
       DW I0453,STOUT,CLREQ,O0453
       DW I0454,STOUT,CLREQ,O0454
       DW I0455,STOBS,CLNG,O0455
       DW I0456,STOUT,CLREQ,O0456
       DW I0457,STOUT,CLREQ,O0457
       DW I0458,STOUT,CLREQ,O0458
       DW I0459,STOUT,CLOUT,O0459
       DW I0460,STOBS,CLNG,O0460
       DW I0461,STOUT,CLREQ,O0461
       DW I0462,STOBS,CLNG,O0462
       DW I0463,STOUT,CLREQ,O0463
       DW I0464,STOUT,CLREQ,O0464
       DW I0465,STOUT,CLREQ,O0465
       DW I0466,STOUT,CLREQ,O0466
       DW I0467,STOUT,CLOUT,O0467
       DW I0468,STOUT,CLREQ,O0468
       DW I0469,STOUT,CLREQ,O0469
       DW I0470,STOUT,CLREQ,O0470
       DW I0471,STOUT,CLREQ,O0471
       DW I0472,STOUT,CLOPT,O0472
       DW I0473,STOUT,CLREQ,O0473
       DW I0622,STOUT,CLREQ,O0622

SELBUF:DS 4
PASSCNT:DB 0
FAILCNT:DB 0
REMCNT: DB 30
DECTMP: DB 0
DPHPTR:DW 0
DPBPTR:DW 0
ALVPTR:DW 0
DPBOLD:DW 0
DPBSCR:DW 0
MODPTR:DW 0
TESTBLK:DW 0
BIOSBASE:DW 0
PATCHLOC:DW 0
PATCHNEW:DW 0
PATCHSAVE:DW 0
PATCHCNT:DB 0
ORGSEL: DW 0
ORGTRK: DW 0
ORGSEC: DW 0
ORGDMA: DW 0
ORGREAD:DW 0
ORGWRITE:DW 0
ORGXLT: DW 0
TRACELOG:
SELCNT: DB 0
TRKCNT: DB 0
SECCNT: DB 0
DMACNT: DB 0
READCNT:DB 0
WRITECNT:DB 0
XLTCNT: DB 0
WRTYPES:DB 0
APPDMA: DB 0
DIRDMA: DB 0
XLTVALID:DB 0
XLTCHAIN:DB 0
IOFAIL: DB 0
WRSTATUS:DB 0
CONFSEL:DB 0
ABSENTSEL:DB 0
TRACECOUNT:DB 0
LASTSEL:DB 0
SELRESULT:DW 0
LASTTRK:DW 0
LASTSEC:DW 0
LASTDMA:DW 0
XLTIN:  DW 0
XLTPTR: DW 0
XLTOUT: DW 0
TRACEEND:
OLDDRV:DB 0
OLDUSR:DB 0
SCRDRV:DB 0
MODORIG:DB 0
MODNEW:DB 0
T27WROTE:DB 0
IOBORIG:DB 0
IOBNEW: DB 0
PROBERES:DB 0
SMCODE:DB 03EH,00H,0C9H,00H
SMBUF1:DS 4
SMBUF2:DS 4
DPBCOPY1:DS 15
DPBCOPY2:DS 15
TESTFCB:DB 0
        DS 35
TNAME:  DB 'BTBIO   TMP'
TESTDMA:DB 'BIOSTEST-CONTROLLED-RECORD'
        DS 102
        DS 128
STACKTOP:
        END     START
