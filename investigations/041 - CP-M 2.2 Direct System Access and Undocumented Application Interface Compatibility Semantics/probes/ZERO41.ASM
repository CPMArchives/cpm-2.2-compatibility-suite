; Investigation 041: deterministic documented zero-page snapshot.
        ORG 0100H
        LD DE,HDR1
        LD C,9
        CALL 0005H
        CALL SNAP
        LD C,12
        CALL 0005H
        LD (VER),HL
        LD DE,HDR2
        LD C,9
        CALL 0005H
        CALL SNAP
        LD DE,VMSG
        LD C,9
        CALL 0005H
        LD HL,(VER)
        LD A,H
        CALL HEXB
        LD HL,(VER)
        LD A,L
        CALL HEXB
        CALL CRLF
        RET
SNAP:   LD HL,0000H
        LD B,8
S0:     LD A,(HL)
        INC HL
        PUSH BC
        PUSH HL
        CALL HEXB
        CALL SPACE
        POP HL
        POP BC
        DJNZ S0
        LD HL,005CH
        LD B,4
S1:     LD A,(HL)
        INC HL
        PUSH BC
        PUSH HL
        CALL HEXB
        CALL SPACE
        POP HL
        POP BC
        DJNZ S1
        LD HL,0080H
        LD B,4
S2:     LD A,(HL)
        INC HL
        PUSH BC
        PUSH HL
        CALL HEXB
        CALL SPACE
        POP HL
        POP BC
        DJNZ S2
        JP CRLF
SPACE:  LD E,' '
        LD C,2
        JP 0005H
CRLF:   LD E,13
        LD C,2
        CALL 0005H
        LD E,10
        LD C,2
        JP 0005H
HEXB:   PUSH AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL NIB
        POP AF
NIB:    AND 0FH
        ADD A,'0'
        CP '9'+1
        JR C,OUT
        ADD A,7
OUT:    LD E,A
        LD C,2
        JP 0005H
HDR1:   DB 'ZERO41 before 0000-07 005C-5F 0080-83 ',13,10,'$'
HDR2:   DB 'ZERO41 after-fn12 ',13,10,'$'
VMSG:   DB 'ZERO41 fn12-HL $'
VER:    DW 0
        END
