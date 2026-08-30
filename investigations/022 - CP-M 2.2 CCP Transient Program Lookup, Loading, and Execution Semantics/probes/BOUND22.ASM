; Header for boundary-sized COM fixtures. If executed it identifies the file.
; Build with -dmarkch and then pad with make-fixtures.sh.
        ORG 0100H
        LD DE,MSG
        LD C,9
        CALL 5
        RET
MSG:   DB 13,10,'BOUND22 EXECUTED ',markch,13,10,'$'
        END
