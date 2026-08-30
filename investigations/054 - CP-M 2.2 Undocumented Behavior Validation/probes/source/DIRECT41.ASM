; Investigation 041: private-target observation and BIOS failure boundary.
        ORG 0100H
        LD DE,MSG
        LD C,9
        CALL 0005H

        ; Deliberately bypass the public 0005h gateway and call its current
        ; target. This is observed DRI behavior, not a portable requirement.
        LD HL,(0006H)
        LD (BDCALL+1),HL
        LD C,12
BDCALL: CALL 0000H
        LD (BDRES),HL

        ; Derive BIOS base from WBOOT and call SELDSK with an invalid drive.
        LD HL,(0001H)
        DEC HL
        DEC HL
        DEC HL
        LD DE,27
        ADD HL,DE
        LD (BICALL+1),HL
        LD C,0FFH
BICALL: CALL 0000H
        LD (BIRES),HL
        LD HL,(BDRES)
        LD A,H
        CALL HEXB
        LD HL,(BDRES)
        LD A,L
        CALL HEXB
        LD E,' '
        LD C,2
        CALL 0005H
        LD HL,(BIRES)
        LD A,H
        CALL HEXB
        LD HL,(BIRES)
        LD A,L
        CALL HEXB
        LD E,13
        LD C,2
        CALL 0005H
        LD E,10
        LD C,2
        CALL 0005H
        RET
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
MSG:    DB 'DIRECT41 private-BDOS-HL invalid-SELDSK-HL $'
BDRES:  DW 0
BIRES:  DW 0
        END
