; Investigation 001 entry-state probe for a Z80-hosted CP/M 2.2 system.
; Assemble with z80pack z80asm 2.1:
;   z80asm -fb -oENTRY001.COM ENTRY001.ASM
;
; The first instructions save registers without changing them.  AF is saved
; only after SP and the other main pairs have been recorded.  The probe then
; snapshots page zero and 16 bytes beginning at the entry SP before making
; any BDOS call.  Output is hexadecimal: a 33-byte register record, the
; 256-byte page-zero image, and the 16-byte entry-stack image.

	ORG	0100H

START:
	LD	(INIT_SP),SP
	LD	(INIT_BC),BC
	LD	(INIT_DE),DE
	LD	(INIT_HL),HL
	LD	(INIT_IX),IX
	LD	(INIT_IY),IY
	PUSH	AF
	POP	HL
	LD	(INIT_AF),HL
	EXX
	LD	(ALT_BC),BC
	LD	(ALT_DE),DE
	LD	(ALT_HL),HL
	EXX
	EX	AF,AF'
	PUSH	AF
	POP	HL
	LD	(ALT_AF),HL
	EX	AF,AF'
	LD	A,I
	LD	(INIT_I),A
	PUSH	AF
	POP	HL
	LD	(I_FLAGS),HL
	LD	A,R
	LD	(INIT_R),A

	LD	HL,0000H
	LD	DE,PAGE0
	LD	BC,0100H
	LDIR
	LD	HL,(INIT_SP)
	LD	DE,STACK16
	LD	BC,16
	LDIR

	LD	DE,REGREC
	LD	BC,REGEND-REGREC
	CALL	DUMP
	LD	DE,PAGE0
	LD	BC,0100H
	CALL	DUMP
	LD	DE,STACK16
	LD	BC,16
	CALL	DUMP
	RET

; Dump BC bytes at DE as uppercase hexadecimal, then CR/LF.
DUMP:
	LD	A,(DE)
	PUSH	BC
	PUSH	DE
	CALL	HEXBYTE
	POP	DE
	POP	BC
	INC	DE
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,DUMP
	LD	E,13
	LD	C,2
	CALL	0005H
	LD	E,10
	LD	C,2
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
	LD	C,2
	JP	0005H

; Little-endian pairs. I_FLAGS is the AF value immediately after LD A,I;
; its P/V bit therefore records IFF2 on a Z80.
REGREC:
INIT_SP:	DW 0
INIT_AF:	DW 0
INIT_BC:	DW 0
INIT_DE:	DW 0
INIT_HL:	DW 0
INIT_IX:	DW 0
INIT_IY:	DW 0
ALT_AF:		DW 0
ALT_BC:		DW 0
ALT_DE:		DW 0
ALT_HL:		DW 0
INIT_I:		DB 0
INIT_R:		DB 0
I_FLAGS:	DW 0
ENTRY_PC:	DW 0100H
FORMAT_VERSION:	DB 1
REGEND:

PAGE0:		DS 256
STACK16:	DS 16

	END
