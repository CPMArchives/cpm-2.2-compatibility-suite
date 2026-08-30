; Investigation 004: BDOS function 6 and 11 probe.
; Assemble: z80asm -fb -oDIO004.COM DIO004.ASM
;
; Modes are selected by the first command-tail operand:
;   E  no queued key: record functions 11, 6/FF, and 6/FE results
;   6  scripted BIOS makes one byte ready: function 6/FF consumes it
;   S  scripted BIOS makes one byte ready: function 11 observes and buffers it,
;      a second function 11 re-observes it, then function 6/FF tests whether
;      direct input consumes the BDOS pending-key buffer.
;   F  scripted BIOS makes one byte ready: undocumented function 6/FE status.
;   O  emit framed direct-output bytes including TAB, '$', and Ctrl-P.

	ORG	0100H

START:
	LD	A,(0080H)
	OR	A
	JR	Z,MODEE
	LD	A,(0082H)	; tail begins with blank, operand at 0082h
	CP	'6'
	JR	Z,MODE6
	CP	'S'
	JR	Z,MODES
	CP	'O'
	JR	Z,MODEO
	CP	'F'
	JP	Z,MODEF

MODEE:
	LD	C,11
	CALL	0005H
	LD	(R1),A
	LD	E,0FFH
	LD	C,6
	CALL	0005H
	LD	(R2),A
	LD	E,0FEH
	LD	C,6
	CALL	0005H
	LD	(R3),A
	LD	DE,LABE
	JP	REPORT

MODE6:
	CALL	PATCHBIOS
	LD	E,0FFH
	LD	C,6
	CALL	0005H
	LD	(R1),A
	LD	E,0FFH
	LD	C,6
	CALL	0005H
	LD	(R2),A
	CALL	RESTBIOS
	XOR	A
	LD	(R3),A
	LD	DE,LAB6
	JP	REPORT

MODES:
	CALL	PATCHBIOS
	LD	C,11
	CALL	0005H
	LD	(R1),A
	LD	C,11
	CALL	0005H
	LD	(R2),A
	LD	E,0FFH
	LD	C,6
	CALL	0005H
	LD	(R3),A
	CALL	RESTBIOS
	LD	DE,LABS
	JP	REPORT

MODEO:
	LD	DE,OUTPRE
	CALL	PRINT9
	LD	E,'A'
	CALL	PUT6
	LD	E,9
	CALL	PUT6
	LD	E,'$'
	CALL	PUT6
	LD	E,16		; Ctrl-P must be emitted, not toggle echo
	CALL	PUT6
	LD	E,'B'
	CALL	PUT6
	LD	DE,OUTPOST
	CALL	PRINT9
	RET

MODEF:
	CALL	PATCHBIOS
	LD	E,0FEH
	LD	C,6
	CALL	0005H
	LD	(R1),A
	LD	E,0FEH
	LD	C,6
	CALL	0005H
	LD	(R2),A
	CALL	RESTBIOS
	XOR	A
	LD	(R3),A
	LD	DE,LABF
	JP	REPORT

; Replace only BIOS CONST and CONIN jump vectors in the running disposable
; image. The warm-boot target at 0001h is BIOS+3, hence BIOS=target-3.
; Original six bytes are restored before any diagnostic output.
PATCHBIOS:
	LD	HL,(0001H)
	DEC	HL
	DEC	HL
	DEC	HL
	LD	DE,6
	ADD	HL,DE		; BIOS CONST vector
	LD	(CONSTADR),HL
	LD	DE,SAVECONST
	LD	BC,3
	LDIR
	LD	HL,(CONSTADR)
	LD	(HL),0C3H
	INC	HL
	LD	DE,HCONST
	LD	A,E
	LD	(HL),A
	INC	HL
	LD	A,D
	LD	(HL),A
	LD	HL,(CONSTADR)
	LD	DE,3
	ADD	HL,DE		; BIOS CONIN vector
	LD	(CONINADR),HL
	LD	DE,SAVECONIN
	LD	BC,3
	LDIR
	LD	HL,(CONINADR)
	LD	(HL),0C3H
	INC	HL
	LD	DE,HCONIN
	LD	A,E
	LD	(HL),A
	INC	HL
	LD	A,D
	LD	(HL),A
	LD	A,1
	LD	(HREADY),A
	RET

RESTBIOS:
	LD	HL,SAVECONST
	LD	DE,(CONSTADR)
	LD	BC,3
	LDIR
	LD	HL,SAVECONIN
	LD	DE,(CONINADR)
	LD	BC,3
	LDIR
	RET

HCONST:
	LD	A,(HREADY)
	OR	A
	RET	Z
	LD	A,0FFH
	RET

HCONIN:
	XOR	A
	LD	(HREADY),A
	LD	A,'Z'
	RET

REPORT:
	CALL	PRINT9
	LD	A,(R1)
	CALL	HEXBYTE
	LD	E,' '
	CALL	PUT2
	LD	A,(R2)
	CALL	HEXBYTE
	LD	E,' '
	CALL	PUT2
	LD	A,(R3)
	CALL	HEXBYTE
	LD	DE,CRLF
	CALL	PRINT9
	RET

PUT2:
	LD	C,2
	JP	0005H

PUT6:
	LD	C,6
	JP	0005H

PRINT9:
	LD	C,9
	JP	0005H

HEXBYTE:
	PUSH	AF
	RRCA
	RRCA
	RRCA
	RRCA
	CALL	HEXNIB
	POP	AF
HEXNIB:
	AND	0FH
	ADD	A,'0'
	CP	'9'+1
	JR	C,HEXOUT
	ADD	A,7
HEXOUT:
	LD	E,A
	JP	PUT2

R1:	DB 0
R2:	DB 0
R3:	DB 0
CONSTADR: DW 0
CONINADR: DW 0
SAVECONST: DS 3
SAVECONIN: DS 3
HREADY: DB 0
LABE:	DB 13,10,'EMPTY 11,6FF,6FE: $'
LAB6:	DB 13,10,'PEND6 first,second: $'
LABS:	DB 13,10,'PEND11 first,second,6FF: $'
LABF:	DB 13,10,'PEND6FE first,second: $'
OUTPRE:	DB 13,10,'RAW-BEGIN[','$'
OUTPOST: DB ']RAW-END',13,10,'$'
CRLF:	DB 13,10,'$'

	END
