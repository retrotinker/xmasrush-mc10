	nam	xmasrush
	ttl	Xmas Rush

LOAD	equ	$4400
START	equ	LOAD

P1DATA  equ     $0002
P2DATA  equ     $0003

TCSR    equ     $0008
TIMER   equ     $0009
TOCR    equ     $000b

KVSPRT  equ     $bfff

TXTBASE	equ	$4000			memory map-related definitions

IS1BASE	equ	(TXTBASE+5*32+3)	string display location info
IS2BASE	equ	(TXTBASE+6*32+3)
IS3BASE	equ	(TXTBASE+7*32+3)
IS4BASE	equ	(TXTBASE+10*32+10)

ATSTBAS	equ	(TXTBASE+2*32+10)
SZSTBAS	equ	(TXTBASE+4*32+10)
ESSTBAS	equ	(TXTBASE+6*32+11)
CLSTBAS	equ	(TXTBASE+9*32+6)
BRSTBAS	equ	(TXTBASE+10*32+8)

JS1BASE	equ	(TXTBASE+6*32+1)
JS2BASE	equ	(TXTBASE+8*32+5)

#PLAYPOS	equ	(TXTBASE+(9*32)+24)
PLAYPOS	equ	$4138

	org	START

	pshx			save state for exit to Micro Color BASIC
	pshb
	psha
	tpa
	psha
	tsx
	stx	savestk

	jsr	intro

	jmp	exit

*
* Show intro screen
*
intro	jsr	txtinit		setup text screen

	ldx	#intscrn	write intro screen data to buffer
	pshx
	ldx	#TXTBASE
	pshx
	tsx
	ldx	2,x
intsclp	ldaa	,x
	tsx
	ldx	,x
	staa	,x
	tsx
	ldd	,x
	addd	#$0001
	std	,x
	ldd	2,x
	addd	#$0001
	std	2,x
	ldx	2,x
	cpx	#intscrn+512
	blt	intsclp

	pulx
	pulx

	ldaa	#$1e		setup counter for 30 frames
	psha
inttimr	ldd     TIMER		setup timer for ~1 frame duration
        addd    #14915
        pshb
        psha
        pulx
        ldab    TCSR
        stx     TOCR

intkylp	ldaa	#$fb		check for BREAK
	staa	P1DATA
	ldaa	P2DATA
	anda	#$02
	beq	exit

	ldaa	#$7f		check for SPACEBAR
	staa	P1DATA
	ldaa	KVSPRT
	anda	#$08
	beq	intkyex

	ldab    TCSR		check for timer expiry
	andb    #$40
	beq     intkylp
	tsx
	dec     ,x
	bne     inttimr

	ldx	#PLAYPOS	invert text for PLAY
	ldab	#$04
intfllp	ldaa	,x
	eora	#$40
	staa	,x
	inx
	decb
	bne	intfllp

	tsx			restore counter for 30 more frames
	ldaa    #$1e
	staa    ,x
	bra	inttimr

intkyex	ins
	rts

*
* txtinit -- setup text screen
*
txtinit	clr	KVSPRT
	rts

*
* Exit to Micro Color BASIC
*
exit	ldx	savestk
	txs
	pula
	tap
	pula
	pulb
	pulx
	rts

*
* Intro screen data
*
* 	generated @ http://cocobotomy.roust-it.dk/sgedit/
*
intscrn	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$9f,$9a,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$87,$8f,$8f,$82,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$87,$8f,$bf,$8f,$8f,$82
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$87,$8f,$8f,$8f,$8f,$ff,$8f
	fcb	$82,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$87,$8f,$af,$8f,$8f,$8f,$8f,$8f
	fcb	$8f,$82,$80,$80,$80,$80,$53,$50,$41,$43,$45,$42,$41,$52,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$87,$ff,$8f,$8f,$8f,$18,$0d,$01,$13
	fcb	$8f,$8f,$82,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$87,$8f,$8f,$8f,$8f,$8f,$8f,$12,$15,$13
	fcb	$08,$8f,$8f,$82,$80,$80,$80,$80,$80,$54,$4f,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$87,$8f,$8f,$af,$8f,$8f,$bf,$8f,$8f,$8f,$8f
	fcb	$8f,$8f,$ef,$8f,$82,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$87,$ff,$8f,$8f,$8f,$8f,$8f,$8f,$8f,$8f,$8f,$02
	fcb	$19,$8f,$8f,$8f,$8f,$82,$80,$80,$50,$4c,$41,$59,$80,$80,$80,$80
	fcb	$80,$80,$80,$84,$8f,$8f,$8f,$8f,$ef,$8f,$8f,$8f,$ff,$8f,$0a,$0f
	fcb	$08,$0e,$8f,$8f,$af,$8e,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$84,$8f,$bf,$8f,$8f,$8f,$af,$8f,$0c,$09,$0e,$16
	fcb	$09,$0c,$0c,$05,$8e,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$84,$8f,$8f,$8f,$8f,$8f,$8f,$8f,$8f,$8f,$8f
	fcb	$8f,$8f,$8f,$8e,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$f5,$ff,$ff,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$f5,$ff,$ff,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80
	fcb	$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80,$80

*
* Data declarations
*
savestk	rmb	2

	end	START
