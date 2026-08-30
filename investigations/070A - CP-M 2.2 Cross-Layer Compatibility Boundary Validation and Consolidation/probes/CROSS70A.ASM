; Investigation 070A cross-layer state/transition validation probe.
        ORG 100H
        LD A,(0001H)
        LD (WBOOT),A
        LD A,(0002H)
        LD (WBOOT+1),A
        LD A,(0006H)
        LD (BDOSV),A
        LD A,(0007H)
        LD (BDOSV+1),A

        LD C,12
        CALL 5
        LD (VERS),HL
        LD C,25
        CALL 5
        LD (D0),A
        LD E,0FFH
        LD C,32
        CALL 5
        LD (U0),A

        LD HL,ALTDMA
        LD (HL),0CCH
        LD DE,ALTDMA
        LD C,26
        CALL 5
        LD DE,FCBA0
        LD C,17
        CALL 5
        LD (S0),A
        CP 0FFH
        JR Z,S0DONE
        LD L,A
        LD H,0
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        LD DE,ALTDMA
        ADD HL,DE
        LD DE,DIRENT
        LD BC,12
        LDIR
S0DONE:
        LD E,1
        LD C,14
        CALL 5
        LD E,1
        LD C,32
        CALL 5
        LD DE,FCBA1
        LD C,17
        CALL 5
        LD (SUSER1),A
        LD E,0
        LD C,32
        CALL 5
        LD DE,FCBA2
        LD C,17
        CALL 5
        LD (SUSER0),A
        LD C,25
        CALL 5
        LD (DAFTER),A

        LD HL,(WBOOT)
        INC HL
        INC HL
        INC HL
        CALL CALLHL
        LD (BICON),A

        LD C,13
        CALL 5
        LD C,25
        CALL 5
        LD (DRESET),A
        LD E,0FFH
        LD C,32
        CALL 5
        LD (URESET),A
        LD DE,0080H
        LD C,26
        CALL 5

        LD DE,TITLE
        CALL PRINT
        LD DE,LVEC
        CALL PRINT
        LD HL,(WBOOT)
        CALL HEXHL
        LD E,'/'
        CALL OUT
        LD HL,(BDOSV)
        CALL HEXHLCR
        LD DE,LENTRY
        CALL PRINT
        LD HL,(VERS)
        CALL HEXHL
        LD A,(D0)
        CALL HEX
        LD A,(U0)
        CALL HEXCR
        LD DE,LSRCH
        CALL PRINT
        LD A,(S0)
        CALL HEX
        LD A,(DIRENT)
        CALL HEX
        LD HL,DIRENT+1
        LD B,11
PNAME:  LD E,(HL)
        PUSH BC
        PUSH HL
        CALL OUT
        POP HL
        POP BC
        INC HL
        DJNZ PNAME
        CALL CRLF
        LD DE,LCTX
        CALL PRINT
        LD A,(SUSER1)
        CALL HEX
        LD A,(SUSER0)
        CALL HEX
        LD A,(DAFTER)
        CALL HEXCR
        LD DE,LBIOS
        CALL PRINT
        LD A,(BICON)
        CALL HEXCR
        LD DE,LRESET
        CALL PRINT
        LD A,(DRESET)
        CALL HEX
        LD A,(URESET)
        CALL HEXCR
        LD DE,DONE
        CALL PRINT
        RET

CALLHL: LD DE,RETBIOS
        PUSH DE
        JP (HL)
RETBIOS: RET
HEXHLCR:
        PUSH HL
        LD A,H
        CALL HEX
        POP HL
        LD A,L
        JP HEXCR
HEXHL:  PUSH HL
        LD A,H
        CALL HEX
        POP HL
        LD A,L
        JP HEX
HEXCR:  CALL HEX
CRLF:   LD E,13
        CALL OUT
        LD E,10
        JP OUT
HEX:    PUSH AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL NIB
        POP AF
NIB:    AND 0FH
        ADD A,'0'
        CP '9'+1
        JR C,HOUT
        ADD A,7
HOUT:   LD E,A
OUT:    PUSH BC
        LD C,2
        CALL 5
        POP BC
        RET
PRINT:  LD C,9
        JP 5

TITLE:  DB 'CROSS70A CROSS-LAYER MATRIX',13,10,'$'
LVEC:   DB 'WBOOT/BDOS TARGET=','$'
LENTRY: DB 'VERSION DRIVE USER=','$'
LSRCH:  DB 'ALT-DMA SEARCH RC/ENTRY=','$'
LCTX:   DB 'A:ATTR USER1/USER0 RC, CURRENT DRIVE=','$'
LBIOS:  DB 'DIRECT BIOS CONST=','$'
LRESET: DB 'RESET DRIVE/USER=','$'
DONE:   DB 'CROSS70A COMPLETE',13,10,'$'
WBOOT:  DW 0
BDOSV:  DW 0
VERS:   DW 0
D0:     DB 0
U0:     DB 0
S0:     DB 0FFH
SUSER1: DB 0FFH
SUSER0: DB 0FFH
DAFTER: DB 0FFH
BICON:  DB 0FFH
DRESET: DB 0FFH
URESET: DB 0FFH
DIRENT: DS 12,0
FCBA0:  DB 0,'ATTR    ','DAT',0,0,0,0
        DS 20
FCBA1:  DB 1,'ATTR    ','DAT',0,0,0,0
        DS 20
FCBA2:  DB 1,'ATTR    ','DAT',0,0,0,0
        DS 20
ALTDMA: DS 128,0CCH
        END
