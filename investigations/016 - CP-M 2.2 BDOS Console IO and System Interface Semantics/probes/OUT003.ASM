; Investigation 003 probe: BDOS functions 2 and 9 output semantics.
; Assemble: z80asm -fb -oOUT003.COM OUT003.ASM
;
; The cases are self-framing ASCII lines. LF is emitted before each tab case
; because DRI BDOS resets its logical column on LF. No diagnostic BDOS output
; is interleaved with a measured sequence.

	ORG	0100H

START:
	LD	DE,INTRO
	CALL	PRINT9

; Function 2: '$' is ordinary data. At logical column 5, TAB expands to
; three spaces and X appears at the next eight-column tab stop.
	LD	E,10
	CALL	PUT2
	LD	DE,F2PREFIX
	CALL	PRINT9
	LD	E,'$'
	CALL	PUT2
	LD	E,9
	CALL	PUT2
	LD	E,'X'
	CALL	PUT2
	CALL	CRLF

; Function 9: TAB uses the same expansion. "F9:A" is four columns, so
; TAB expands to four spaces. The first '$' terminates the string; neither
; it nor the following "HIDDEN" is emitted.
	LD	E,10
	CALL	PUT2
	LD	DE,F9TAB
	CALL	PRINT9
	CALL	CRLF
	LD	DE,F9TERM
	CALL	PRINT9
	LD	DE,AFTER
	CALL	PRINT9
	CALL	CRLF

; Empty function-9 string (first byte '$') emits nothing between brackets.
	LD	DE,EMPTYL
	CALL	PRINT9
	LD	DE,EMPTY
	CALL	PRINT9
	LD	DE,EMPTYR
	CALL	PRINT9
	CALL	CRLF

; Function 9 passes CR/LF through and continues afterward.
	LD	DE,MULTI
	CALL	PRINT9
	CALL	CRLF
	RET

PUT2:
	LD	C,2
	JP	0005H

PRINT9:
	LD	C,9
	JP	0005H

CRLF:
	LD	E,13
	CALL	PUT2
	LD	E,10
	JP	PUT2

INTRO:	DB 13,10,'OUT003 BEGIN$'
F2PREFIX: DB 'F2:A$'               ; '$' terminates this helper prefix
F9TAB:	DB 'F9:A',9,'X$'
F9TERM: DB 'F9TERM:VISIBLE$HIDDEN$'
AFTER:	DB ':AFTER$'
EMPTYL:	DB 'EMPTY:[$'
EMPTY:	DB '$'
EMPTYR:	DB ']$'
MULTI:	DB 'MULTI:A',13,10,'B$'

	END
