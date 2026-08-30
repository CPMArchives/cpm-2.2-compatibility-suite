; Build with -dmarkch=<ASCII> to create drive/user lookup variants.
        ORG 0100H
        LD DE,MSG
        LD C,9
        CALL 5
        RET
MSG:   DB 13,10,'MARK22 variant ',markch,13,10,'$'
        END
