; Mutate drive/user/DMA/page zero, then terminate according to tail R/F/J.
        ORG 100H
        LD DE,MSG
        LD C,9
        CALL 5
        LD E,1
        LD C,14
        CALL 5                  ; current drive B
        LD E,1
        LD C,32
        CALL 5                  ; user 1
        LD DE,0200H
        LD C,26
        CALL 5                  ; nondefault DMA
        LD A,40H
        LD (0003H),A            ; LIST-field IOBYTE test, console unchanged
        LD HL,(0001H)
        LD (0041H),HL
        LD A,0C3H
        LD (0040H),A            ; 0040: JP original WBOOT
        LD HL,0040H
        LD (0001H),HL
        LD (0000H),A
        LD HL,(0006H)
        LD (0044H),HL
        LD (0043H),A            ; 0043: JP original BDOS
        LD HL,0043H
        LD (0006H),HL
        LD (0005H),A
        LD A,011H              ; coherent packed user 1 / drive B state
        LD (0004H),A
        LD A,(0082H)            ; first letter after leading blank
        CP 'F'
        JR Z,DOF0
        CP 'J'
        JP Z,0000H
        RET
DOF0:   LD C,0
        JP 0005H
MSG:    DB 'STATE24 MUTATE B/U1/DMA0200/PZ',13,10,'$'
        END
