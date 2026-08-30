; Controlled page-zero WBOOT restoration initiator.
        ORG 0100H
        LD DE,MSG
        LD C,9
        CALL 5
        LD HL,(0001H)
        LD (GO+1),HL
        LD HL,0
        LD B,8
        CALL DUMP
        LD DE,DMG
        LD C,9
        CALL 5
        XOR A
        LD (0000H),A             ; damage only documented JMP opcodes
        LD (0005H),A             ; operands/actual targets stay intact
GO:     JP 0000H                 ; patched to saved real WBOOT target
DUMP:   LD A,(HL)
        INC HL
        PUSH HL
        PUSH BC
        CALL HEX
        LD E,' '
        LD C,2
        CALL 5
        POP BC
        POP HL
        DJNZ DUMP
        LD E,13
        LD C,2
        CALL 5
        LD E,10
        LD C,2
        JP 5
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
        JR C,OUT
        ADD A,7
OUT:    LD E,A
        LD C,2
        JP 5
MSG:    DB 'WBOOT20 BEFORE PZ00-07: $'
DMG:    DB 'WBOOT20: setting 0000h and 0005h opcodes to 00, then WBOOT',13,10,'$'
        END
