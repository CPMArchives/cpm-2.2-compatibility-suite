;****************************************************************************
;
;	CP/M 2.2 BIOS for Mostek Development System computers. This
;	includes the AID-80F and SYS-80FT systems. The primary criteria
;	is presence of the SDB-80 (or SDB-80E) CPU board and the FLP-80
;	(or FLP-80E) floppy controller board. The monitor PROMs on the
;	SDB-80 CPU board provide disk I/O support routines that are
;	called by this BIOS to do disk I/O.
;
;	MODE byte (BIOS flags)
;		0033h from start of BIOS
;		1633h from start of CP/M
;		1733h in the disk image file
;
;       To patch an update to this BIOS into a CP/M image created and saved
;	after running MOVCPM, use the following commands:
;
;	   A>DDT CPM56.COM    (specify the saved CP/M image file)
;	   -IBIOS.HEX
;	   -Rxxxx      	      (xxxx = the value of the BIAS equate below)
;	   -G0		      (Go zero, not "oh")
;
;	Ver	  Date		     Description
;	---	----------	---------------------
;	1.0 	03/05/2016	Original, Mike Douglas
;
;	1.1 	11/11/2017	Mike Douglas
;				Add the BIAS equate.
;				Update the code for testing the cold and
;				warm start command line flag in the MODE
;				byte. Not a bug fix, just a style change.
;				
;
;****************************************************************************

	maclib	z80		;include Z80 opcodes

;  CP/M location equates

MEMSIZE	equ	56		;memory size in K bytes

BIOSLEN	equ	0600h		;BIOS size assumed by generic MOVCPM
CCPLEN	equ	0800h		;CPM 2.2 fixed length
BDOSLEN	equ	0e00h		;CPM 2.2 fixed length

CPMSIZE	equ	CCPLEN+BDOSLEN+BIOSLEN
CCPBASE	equ	MEMSIZE*1024 - CPMSIZE
BDOSENT	equ	(CCPBASE+CCPLEN+6)	 ;entry address of BDOS
BIOSBAS	equ	(CCPBASE+CCPLEN+BDOSLEN) ;base address of this BIOS

BIAS	equ	0A00h-CCPBASE

; CP/M page zero equates

WBOOTV	equ	000h		;warm boot vector location
BDOSV	equ	005h		;bdos entry vector location
CDISK	equ	004h		;CPM current disk
DEFDMA	equ	080h		;default dma address
IOBYTE	equ	003h		;CPM IOBYTE

; CP/M (logical) disk information

NUMDISK	equ	4		;four drives supported
NUMTRK	equ	77		;number of tracks on the disk
NUMSEC	equ	26		;logical (128 byte) sectors per track
SECLEN	equ	128		;CP/M sector length
DSM	equ	242		;max block number (243 blocks of 1024 bytes)
DRM	equ	63		;max directory entry number (64 entries) 
CKS	equ	(DRM+1)/4	;directory check space
WBSECS	equ	(CCPLEN+BDOSLEN)/SECLEN   ;warm boot sectors to read
STRTSEC	equ	3		;start sector for CP/M image

; Serial I/O port equates

SIOCR	equ	0DDh		;serial port control register
SIODR	equ	0DCh		;serial port data register

SIOTDRE	equ	080h		;transmit register empty bit
SIORDRF	equ	040h		;receive register full bit

; PROM Disk Driver Equates

DSKDRV	equ	0EC00h		;disk driver entry point

dcSTAT	equ	10h		;return 1771 status
dcREAD	equ	11h		;read sector
dcWRITE	equ	12h		;write sector
dcSEEK	equ	13h		;seek track with verify
dcRESTR	equ	14h		;restore to track 0
dcGETRK	equ	15h		;read track # from disk, put in 1771
dcDEL	equ	16h		;write deleted sector data mark
dcFMT	equ	17h		;seek track, issue write track for fmt

dsPARAM	equ	80h		;bad parameter passsed in DCB
dsNRDY	equ	40h		;disk not ready
dsSKERR	equ	20h		;seek error
ds1771	equ	1Ch		;1771 status bits masked by 1C

; Misc equates

RETRIES	equ	5		;number of I/O retries
CR	equ	13		;ascii for carriage return
LF	equ	10		;ascii for line feed

	org	BIOSBAS
;-----------------------------------------------------------------------------
;  BIOS Entry Jump Table. 
;-----------------------------------------------------------------------------
	jmp	boot		;cold start
wboote	jmp	wBoot		;warm start
	jmp	conSt		;console status
	jmp	conIn		;console character in
	jmp	conOut		;console character out
	jmp	conOut		;list character out
	jmp	conOut		;punch character out
	jmp	conIn		;reader character in
	jmp	home		;move head to home position
	jmp	selDsk		;select disk
	jmp	setTrk		;set track number
	jmp	setSec		;set sector number
	jmp	setDma		;set dma address
	jmp	read		;read disk
	jmp	write		;write disk
	jmp	conSt		;return list status
	jmp	secTran		;sector translate

;---------------------------------------------------------------------------
; MODE byte - BIOS flags. 
;     Must remain at offset 33h from start of BIOS
;---------------------------------------------------------------------------
mode	db	00h		;no options enabled

fCLDCMD	equ	01h		;true = CCP process cmd on cold start
fWRMCMD	equ	02h		;true = CCP process cmd on warm start

;---------------------------------------------------------------------------
;  CPM Welcome Message. This area also serves as the stack once
;     running, so make note of the resulting stack size based
;     on the welcome message length.
;---------------------------------------------------------------------------
cpmStr	db	CR,LF,LF
	db	MEMSIZE/10 + '0',MEMSIZE mod 10 + '0'
	db	'K CP/M 2.2 Ver 1.1',CR,LF
	db	' for Mostek AID-80F',CR,LF,0
lclStk	equ	$

;----------------------------------------------------------------------------
; boot - Cold boot BIOS entry. CPM is already loaded in memory. Hand
;    control to the CCP.
;----------------------------------------------------------------------------
boot	lxi	sp,0100h	;init stack pointer

	xra	a
	sta	CDISK		;current CPM disk is drive zero
	sta	IOBYTE		;not used, but init to zero

	lxi	h,cpmStr	;HL->cpm welcome message

dispMsg	mov	a,m		;next character
	ora	a		;test for null terminator
	jz	tstCmd		;done, test run command flag

	mov	c,a		;character to send in c
	call	conOut
	inx	h		;point to next character
	jmp	dispMsg

; Determine whether or not execution of a cold start command line is
;    requested, then enter CP/M.

tstCmd	lda	mode		;see if cold start command line requested
	ani	fCLDCMD
	push	psw		;save result

	jmp	coldCpm		;enter CP/M

;----------------------------------------------------------------
; wboot - Warm boot BIOS entry. Reload CPM from disk up to, but
;    not including the BIOS. Re-enter CPM after loading.
;----------------------------------------------------------------
wboot	lxi	sp,0100h	;init stack pointer

	lxi	b,WBSECS*256+STRTSEC    ;B=secs to read, C=start sec
	lxi	h,CCPBASE	;HL->CP/M load address
	mvi	a,dcREAD	;put read command in DCB
	sta	dcbCmd
	xra	a		;boot from drive zero
	sta	dcbDrv

wbTrk	sta	dcbTrk		;save track number to use

; wbLoop - read sector loop for warm boot

wbLoop	shld	dmaAddr		;set read destination in DCB
	mov	a,c		;set sector number in DCB
	sta	dcbSec

	push	b		;read next sector preserving BC
	call	read
	pop	b
	xchg			;put DE->next address into HL
	
	dcr	b		;decrement total sector count
	jz	entCpm		;warm boot is done, enter CP/M
	
	inr	c		;bump to next sector number
	mov	a,c		;track done?
	cpi	NUMSEC+1
	jc	wbLoop		;no, read next sector
	
	mvi	c,1		;restart at sector 1
	lda	dcbTrk		;move to next track
	inr	a
	jmp	wbTrk		;start again on new track

; entCpm - enter CPM. Set page zero variables, enter CPM with or without
;   command line based on MODE flags.

entCpm	lda	mode		;see if warm start command line requested
	ani	fWRMCMD
	push	psw		;save result

coldCpm	lxi	h,DEFDMA	;set the default dma address (080h)
	shld	dmaAddr

	mvi	a,JMP		;8080 "jump" opcode
	sta	WBOOTV		;store in 1st byte of warm boot vecctor
	sta	BDOSV		;and 1st byte of bdos entry vecctor

	lxi	h,wboote	;get the warm boot address
	shld	WBOOTV+1	;and put it after the jump

	lxi	h,BDOSENT	;BDOS entry address
	shld	BDOSV+1		;put it after the jump opcode

	lda	CDISK		;get current disk number
	mov	c,a		;pass it to CPM in register c

	pop	psw		;restore command line test
	jz	CCPBASE+3	;enter CCP and don't run command line
	jmp	CCPBASE		;enter CCP with possible cmd line

;---------------------------------------------------------------------------
; conSt - Console status BIOS entry point. Return FF if character ready,
;    return zero otherwise.
;---------------------------------------------------------------------------
conSt	in	SIOCR		;test for serial data present
	ani	SIORDRF
	mvi	a,0
	rz			;return zero if data present

	cma			;FF if data not present
	ret

;---------------------------------------------------------------------------
; conIn - Console input byte BIOS entry point. Wait for character
;    and return it
;---------------------------------------------------------------------------
conIn	in	SIOCR		;wait for character
	ani	SIORDRF
	jz	conIn

	in	SIODR		;read the character
	ani	07Fh		;clear msb
	ret

;---------------------------------------------------------------------------
; conOut - Console output BIOS entry point. Output the character in C
;    through the serial port.
;---------------------------------------------------------------------------
conOut:	in	SIOCR		;wait for OK to transmit
	ani	SIOTDRE
	jz	conOut

	mov	a,c		;transmit the passed character
	out	SIODR
	ret

;----------------------------------------------------------------------------
; seldsk - Select Disk BIOS entry. C contains the disk number to select.
;    Validate the disk number and return a pointer to the disk parameter
;    header in HL. Zero is returned in HL for invalid drive number. The
;    disk number is stored in drvNum. No drive activity takes place.
;----------------------------------------------------------------------------
seldsk	lxi	h,0		;hl of zero is error flag
	mov	a,c		;A=drive number
	cpi	NUMDISK		;verify drive number less than number of disks
	rnc			;invalid drive number, return with HL=0=error

	mov	a,c		;save the selected disk number in the DCB
	sta	dcbDrv
	
	rlc			;compute disk parameter header address
	rlc			;   as (16*drvNum) + dpHead
	rlc
	rlc
	lxi	h,dpHead  	;HL->start of disk parameter headers
	mov	e,a
	mvi	d,0
	dad	d		;HL->DPH for the passed drive number
	ret

;----------------------------------------------------------------------------
; home - Home BIOS entry. Set track number to zero. No drive activity 
;     takes place.
;----------------------------------------------------------------------------
home	xra	a		;set trkNum to zero
	sta	dcbTrk		;save track number in the DCB
	ret

;----------------------------------------------------------------------------
; settrk - Set Track BIOS entry. C contains the desired track number.
;    The track number is saved in the DCB for later use. No actual
;    drive activity takes place.
;----------------------------------------------------------------------------
settrk	mov	a,c		;save track number passed in C
	sta	dcbTrk
	ret

;----------------------------------------------------------------------------
; setsec - Set Sector BIOS entry. C contains the desired sector number.
;    The sector number is saved in the DCB for later use. No actual
;    drive activity takes place.
;----------------------------------------------------------------------------
setsec	mov	a,c		;save sector number passed in C
	sta	dcbSec
	ret

;----------------------------------------------------------------------------
; setdma - Set DMA BIOS entry. BC contains the address for reading or
;    writing sector data for subsequent I/O operations. The address is
;    stored in dmaAddr. A copy separate from the DCB is maintained
;    because the disk driver modifies the value stored in the DCB.
;----------------------------------------------------------------------------
setdma	mov	h,b		;save buffer address passed in BC
	mov	l,c
	shld	dmaAddr
	ret

;----------------------------------------------------------------------------
; sectran - Sector translation BIOS entry. Convert zero-indexed logical 
;    sector number in BC to a sector number in HL based on the translate
;    table passed in DE.
;----------------------------------------------------------------------------
sectran	xchg			;HL->translate table
	mvi	b,0		;make sure msb of sector is zero
	dad	b		;HL->translated sector num
	mov	l,m		;L=lsb of sector
	mov	h,b		;H=0=msb of sector
	ret

;----------------------------------------------------------------------------
; read - Read sector BIOS entry. Read one sector using the drive, track,
;    sector, and dmaAddr previously specified.
;
; On Exit: A = 0, Z true if read was successful
;    	   A = 1, Z false if read failed
;	   DE = dmaAddr + SECLEN
; 	   Clobbers all
;----------------------------------------------------------------------------
read	sspd	stkSave		;save stack pointer
	lxi	sp,lclStk	;set local stack pointer

	mvi	a,dcREAD	;set read command in DCB
	sta	dcbCmd
	lhld	dmaAddr		;set DMA address in DCB
	shld	dcbDma
	lxiy	dcb		;point IY to the DCB
	xra	a		;A=0, preserved in DSKDRV call
	mvi	b,RETRIES	;B=retry counter

rdRtry	call	DSKDRV		;call disk driver in firmware
	jz	rdGood		;read worked

	dcr	b		;decrement retry counter 
	jnz	rdRtry		;and try again

; Retries failed, exit with error

	lspd	stkSave		;restore stack pointer
	inr	a		;A=1 (not zero), Z false
	ret			

; rdGood - Read was successful. The driver puts the last four bytes
;     of the sector in the DCB instead of the destination buffer.
;     Move these last four bytes to the buffer.

rdGood	lxi	b,4		;BC=counter of bytes to move
	lhld	dcbDma		;HL->end of initial 124 bytes
	xchg			;DE->end of initial 124 byte
	lxi	h,dcbLst4	;HL->last 4 data bytes in DCB
	ldir			;copy from DCB to user buffer

	lspd	stkSave		;restore stack pointer
	ret			;return with A=0, Z true

;----------------------------------------------------------------------------
; write - Write sector BIOS entry. Write one sector using the drive, track,
;    sector, and dmaAddr previously specified for drvNum.
;
; On Exit: A = 0, Z true if write was successful (read verify is NOT done)
;    	   A = 1, Z false if write failed
; 	   Clobbers all
;----------------------------------------------------------------------------
;  The driver expects the last four data bytes of the sector to be in
;     the DCB, not the user's buffer. Copy the last four bytes from
;     the dmaAddr+124 to the DCB.

write	sspd	stkSave		;save stack pointer
	lxi	sp,lclStk	;set local stack pointer

	lxi	b,4		;BC=counter of bytes to move
	lhld	dmaAddr		;HL->user buffer
	shld	dcbDma		;put in DCB for upcoming write
	lxi	d,SECLEN-4	;compute offset of bytes 125-128
	dad	d		;HL->user buffer + 124
	lxi	d,dcbLst4	;DE->last 4 data bytes in DCB
	ldir			;copy from user buffer to DCB

; Issue the write call to the device driver

	mvi	a,dcWRITE	;set write command in DCB
	sta	dcbCmd
	lxiy	dcb		;point IY to the DCB
	xra	a		;A=0, preserved in DSKDRV call
	mvi	b,RETRIES	;B=retry counter

wrRtry	call	DSKDRV		;call disk driver in firmware
	jz	wrExit		;exit if good, A is zero

	dcr	b		;decrement retry counter 
	jnz	wrRtry		;and try again

; Retries failed, exit with error

	inr	a		;A=1 (not zero), Z false

wrExit	lspd	stkSave		;restore stack pointer
	ret

;-----------------------------------------------------------------------------
; dpHead - disk parameter header for each drive
;-----------------------------------------------------------------------------
dpHead	dw	tranTbl,0,0,0,dirBuf,dpb,csv0,alv0
	dw	tranTbl,0,0,0,dirBuf,dpb,csv1,alv1
	dw	tranTbl,0,0,0,dirBuf,dpb,csv2,alv2
	dw	tranTbl,0,0,0,dirBuf,dpb,csv3,alv3

;-----------------------------------------------------------------------------
; dpb - disk parameter block. This table gives a block size of 1024 bytes
;   and 64 directory entries. 
;-----------------------------------------------------------------------------
dpb	dw	NUMSEC		;sectors per track
	db	3		;allocation block shift factor (BSH)
	db	07h		;data location block mask (BLM)
	db	0		;extent mask (EXM)
	dw	DSM		;maximum block number (DSM 242)	
	dw	DRM		;maximum directory entry number (DRM 63)
	db	0C0h,0		;AL0, AL1 
	dw	CKS		;CKS=(DRM+1)/4
	dw	2		;reserved tracks for CPM and bootloader

tranTbl	db	01,07,13,19,25,05,11,17,23,03,09,15,21
	db	02,08,14,20,26,06,12,18,24,04,10,16,22
	
;-----------------------------------------------------------------------------
; dcb - disk control block. This structure is used to pass parameters
;    to the firmware disk driver.
;-----------------------------------------------------------------------------
dcb	equ	$
	db	0,0,0		;0-2 not used
dcbDrv	db	0		;drive number (0-3) at offset 3
dcbFn	db	0,0,0,0,0,0,0,0,0,0,0	;file name (not used) 04-0E
dcbCmd	db	0		;command at offset 0F
	db	0,0,0,0,0,0,0,0,0
dcbDma	db	0,0		;transfer buffer address at 19,1A
	db	0,0
dcbWSec	db	1		;number of sectors for dump (not used)
dcbSec	db	1		;sector to read/write at offset 1E
dcbTrk	db	0		;track to read/write at offset 1F
dcbLst4	db	0,0,0,0		;last four bytes of track are placed here

;-----------------------------------------------------------------------------
; Uninitialized data
;-----------------------------------------------------------------------------
stkSave	ds	2		;saved stack pointer
dmaAddr	ds	2		;dma address for disk operations

;-----------------------------------------------------------------------------
;  Disk scratchpad areas defined in the DPH table
;-----------------------------------------------------------------------------
dirBuf	ds	128		;bdos directory scratchpad
alv0	ds	(DSM/8 + 1)	;allocation vector storage
csv0	ds	CKS		;change disk scratchpad
alv1	ds	(DSM/8 + 1)
csv1	ds	CKS
alv2	ds	(DSM/8 + 1)
csv2	ds	CKS
alv3	ds	(DSM/8 + 1)
csv3	ds	CKS

	end

