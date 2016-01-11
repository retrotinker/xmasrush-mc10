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
TXTEND	equ	$4200

IS1BASE	equ	(TXTBASE+5*32+3)	string display location info
IS2BASE	equ	(TXTBASE+6*32+3)
IS3BASE	equ	(TXTBASE+7*32+3)
IS4BASE	equ	(TXTBASE+10*32+10)

#ATSTBAS	equ	(TXTBASE+4*32+10)
ATSTBAS	equ	$408a
#SZSTBAS	equ	(TXTBASE+6*32+10)
SZSTBAS	equ	$40ca
#ESSTBAS	equ	(TXTBASE+8*32+11)
ESSTBAS	equ	$410b
#CTSTBAS	equ	(TXTBASE+13*32+6)
CTSTBAS	equ	$41a6
#BRSTBAS	equ	(TXTBASE+14*32+8)
BRSTBAS	equ	$41c8

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

	clr	atmpcnt		clear results tallies
	clr	seizcnt
	clr	escpcnt

restart	ldd	#$400
	pshb
	psha
	jsr	intro
	ins
	ins
	bcs	restrt1

	ldd	#$400
	pshb
	psha
	jsr	talyscn
	ins
	ins
	bcs	restrt1

	bra	restart

restrt1	jmp	exit

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

	ldaa	#$20		setup counter for 30 frames
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
	bne	intkyl1
	jmp	exit

intkyl1	ldaa	#$7f		check for SPACEBAR
	staa	P1DATA
	ldaa	KVSPRT
	anda	#$08
	beq	intkypr

	ldab    TCSR		check for timer expiry
	andb    #$40
	beq     intkylp
	tsx
	dec     ,x
	bne     intkyl2

	ldx	#PLAYPOS	invert text for PLAY
	ldab	#$04
intfllp	ldaa	,x
	eora	#$40
	staa	,x
	inx
	decb
	bne	intfllp

	tsx			restore counter for 30 more frames
	ldaa    #$20
	staa    ,x

intkyl2	dec	4,x
	bne	inttimr
	ldaa	3,x
	beq	intkyto
	deca
	staa	3,x
	bra	inttimr

intkyto	clc
	bra	intkyex

intkypr	ldaa	KVSPRT
	anda	#$08
	beq	intkypr
	sec
intkyex	ins
	rts

*
* Show tally screen
*
talyscn	jsr	txtinit		setup text screen

	jsr	clrtscn		clear text screen

	ldx	#atmpstr
	pshx
        ldx	#ATSTBAS
	pshx
        jsr	drawstr
	pulx
	pulx

	ldx	#ATSTBAS+10
	ldaa	atmpcnt
	jsr	bcdshow

	ldx	#seizstr
	pshx
        ldx	#SZSTBAS
	pshx
        jsr	drawstr
	pulx
	pulx

	ldx	#SZSTBAS+10
	ldaa	seizcnt
	jsr	bcdshow

	ldx	#escpstr
	pshx
        ldx	#ESSTBAS
	pshx
        jsr	drawstr
	pulx
	pulx

	ldx	#ESSTBAS+9
	ldaa	escpcnt
	jsr	bcdshow

	ldx	#ctlstr
	pshx
        ldx	#CTSTBAS
	pshx
        jsr	drawstr
	pulx
	pulx

	ldx	#brkstr
	pshx
        ldx	#BRSTBAS
	pshx
        jsr	drawstr
	pulx
	pulx

	ldaa	#$20		setup counter for 30 frames
	psha
tlytimr	ldd     TIMER		setup timer for ~1 frame duration
        addd    #14915
        pshb
        psha
        pulx
        ldab    TCSR
        stx     TOCR

tlykylp	ldaa	#$fb		check for BREAK
	staa	P1DATA
	ldaa	P2DATA
	anda	#$02
	bne	tlykyl1
	jmp	exit

tlykyl1	ldaa	#$7f		check for SPACEBAR
	staa	P1DATA
	ldaa	KVSPRT
	anda	#$08
	beq	tlykypr

	ldab    TCSR		check for timer expiry
	andb    #$40
	beq     tlykylp
	tsx
	dec     ,x
	bne     tlykyl2

	tsx			restore counter for 30 more frames
	ldaa    #$20
	staa    ,x

tlykyl2	dec	4,x
	bne	tlytimr
	ldaa	3,x
	beq	tlykyto
	deca
	staa	3,x
	bra	tlytimr

tlykyto	clc
	bra	tlykyex

tlykypr	ldaa	KVSPRT
	anda	#$08
	beq	tlykypr
	sec
tlykyex	ins
	rts

*
* txtinit -- setup text screen
*
txtinit	clr	KVSPRT
	rts

*
* Clear text screen
*
clrtscn ldaa	#$20
	ldx	#TXTBASE
clrts.1	staa	,x
	inx
	cpx	#TXTEND
	blt	clrts.1
	rts

*
* Draw string
*
drawstr	tsx
	ldx	4,x
	ldaa	,x
	beq	draws.1
	tsx
	ldx	2,x
	staa	,x
	tsx
	ldd	4,x
	addd	#$0001
	std	4,x
	ldd	2,x
	addd	#$0001
	std	2,x
	bra	drawstr
draws.1	rts

*
* Show BCD encoded number on screen
*
bcdshow	psha
	anda	#$f0
	lsra
	lsra
	lsra
	lsra
	adda	#$30
	staa	,x
	inx
	pula
	anda	#$0f
	adda	#$30
	staa	,x
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
* Tally screen data
*
atmpstr	fcb	$01,$14,$14,$05,$0d,$10,$14,$13,$00

seizstr	fcb	$13,$05,$09,$1a,$15,$12,$05,$13,$00

escpstr	fcb	$05,$13,$03,$01,$10,$05,$13,$00

ctlstr	fcb	$43,$4f,$4e,$54,$52,$4f,$4c,$20,$06,$0f,$12,$20,$0e,$05,$17,$20
	fcb	$10,$0c,$01,$19,$05,$12,$00

brkstr	fcb	$42,$52,$45,$41,$4b,$20,$14,$0f,$20,$05,$0e,$04,$20,$07,$01,$0d
	fcb	$05,$00

*
* Data declarations
*
savestk	rmb	2

atmpcnt	rmb	1
seizcnt	rmb	1
escpcnt	rmb	1

	end	START
