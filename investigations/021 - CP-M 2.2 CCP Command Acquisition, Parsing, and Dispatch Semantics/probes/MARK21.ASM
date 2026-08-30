; Harmless resident-precedence marker, installed under resident basenames.
        ORG 0100H
        LD DE,MSG
        LD C,9
        CALL 5
        RET
MSG:   DB 13,10,'*** TRANSIENT MARK21 EXECUTED ***',13,10,'$'
        END
