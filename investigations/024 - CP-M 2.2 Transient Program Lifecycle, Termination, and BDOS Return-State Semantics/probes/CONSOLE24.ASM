; Exercise console output and change only the LIST routing IOBYTE field.
        ORG 100H
        LD E,'C'
        LD C,2
        CALL 5
        LD E,'2'
        LD C,2
        CALL 5
        LD E,'4'
        LD C,2
        CALL 5
        LD E,13
        LD C,2
        CALL 5
        LD E,10
        LD C,2
        CALL 5
        LD A,40H
        LD (0003H),A
        LD A,(0082H)
        CP 'F'
        JR Z,DOF0
        CP 'J'
        JP Z,0
        RET
DOF0:   LD C,0
        JP 5
        END
