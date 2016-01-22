	nam	xmasrush
	ttl	Xmas Rush

LOAD	equ	$4c00
START	equ	LOAD

P1DATA	equ	$0002
P2DATA	equ	$0003

TCSR	equ	$0008
TIMER	equ	$0009
TOCR	equ	$000b

KVSPRT	equ	$bfff

RESET	equ	$fffe

SQWAVE	equ	$80

FRAMCNT	equ	14934

TXTBASE	equ	$4000		memory map-related definitions
TXTEND	equ	$4200
VBASE	equ	$4000
VSIZE	equ	$0c00

INPUTRT	equ	$01		input bit flag definitions
INPUTLT	equ	$02
INPUTUP	equ	$04
INPUTDN	equ	$08
INPUTBT	equ	$10

INMVMSK	equ	$0f		mask of movement bits

MVDLR60	equ	$08		60Hz reset value for movement delay counter

#IS1BASE	equ	(TXTBASE+5*32+3)	string display location info
IS1BASE	equ	$40a3
#IS2BASE	equ	(TXTBASE+6*32+3)
IS2BASE	equ	$40c3
#IS3BASE	equ	(TXTBASE+7*32+3)
IS3BASE	equ	$40e3
#IS4BASE	equ	(TXTBASE+10*32+10)
IS4BASE	equ	$414a

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

#JS1BASE	equ	(TXTBASE+6*32+1)
JS1BASE	equ	$40c1
#JS2BASE	equ	(TXTBASE+8*32+5)
JS2BASE	equ	$4105

#PLAYPOS	equ	(TXTBASE+(9*32)+24)
PLAYPOS	equ	$4138

	org	START

	ldab	TIMER		Seed the LFSR data
	bne	lfsrini		Can't tolerate a zero-value LFSR seed...
	ldab	#$01
lfsrini	stab	lfsrdat

	clr	atmpcnt		clear results tallies
	clr	seizcnt
	clr	escpcnt

	ldaa	#MVDLR60	setup default movement count
	staa	mvdlrst

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

restrt1	ldaa	atmpcnt		bump attempts counter
	adda	#$01
	daa
	bcc	restrt2
	jsr	jokescn
	bra	restart
restrt2	staa	atmpcnt

	jsr	instscn

	jsr	clrscrn

	jsr	cg3init

	jsr	plfdraw

	jsr	bgcmini		init background collision map

	ldd	#$0f1e		point to grid offset for player
	std	playpos
	std	players

	ldd	#$1511		point to grid offset for xmas tree start
	std	xmstpos
	std	xmsters

	ldd	#$0703		point to grid offset for snowman 1 start
	std	snw1pos
	std	snw1ers

	ldd	#$0e0b		point to grid offset for snowman 2 start
	std	snw2pos
	std	snw2ers

	ldd	#$190d		point to grid offset for snowman 3 start
	std	snw3pos
	std	snw3ers

	ldd	#$0b18		point to grid offset for snowman 4 start
	std	snw4pos
	std	snw4ers

	ldaa	#$01		preset movement delay counter
	staa	mvdlcnt

vblank	ldab    TCSR		check for timer expiry
	andb    #$40
	bne	vtimer
	jmp	brkchck

vtimer	ldaa	vdgcnfg		restore CSS for BCMO colors
	oraa	#$40
	staa	KVSPRT
	staa	vdgcnfg

	ldd	TOCR		setup timer for ~1 frame duration
	addd	#FRAMCNT
	pshb
	psha
	pulx
	ldab    TCSR
	stx     TOCR

verase	ldd	players
	jsr	tileras

	ldd	xmsters
	jsr	tileras

	ldd	snw1ers
	jsr	tileras

	ldd	snw2ers
	jsr	tileras

	ldd	snw3ers
	jsr	tileras

	ldd	snw4ers
	jsr	tileras

vdraw	ldd	playpos
	std	players
	ldx	#player
	jsr	tiledrw

	ldd	xmstpos
	std	xmsters
	ldx	#xmstree
	jsr	tiledrw

	ldd	snw1pos
	std	snw1ers
	ldx	#snowman
	jsr	tiledrw

	ldd	snw2pos
	std	snw2ers
	ldx	#snowman
	jsr	tiledrw

	ldd	snw3pos
	std	snw3ers
	ldx	#snowman
	jsr	tiledrw

	ldd	snw4pos
	std	snw4ers
	ldx	#snowman
	jsr	tiledrw

vcalc	jsr	inpread		read player input for next frame

	ldx	playpos		copy player position for movement check
	pshx
	tsx

	ldab	inpflgs		check for any indication of movement
	andb	#INMVMSK
	bne	vcalc.1
	jmp	vcalc.6

vcalc.1	dec	mvdlcnt		decrement movement delay counter
	beq	vcalc.2
	jmp	vcalc.6

vcalc.2	ldaa	mvdlrst		reset movement delay counter
	staa	mvdlcnt

	ldaa	#$04		make player movement sound
	psha
	psha
	tsx
vplms.1	brn	*		hard-coded delay, approximately 57 cycles
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
vplms.2	brn	*		outer loop re-entry, fix-up for lost cycles
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	dec	,x
	bne	vplms.1
	ldaa	#$04
	staa	,x
	jsr	lfsrget
	anda	#SQWAVE
	eora	vdgcnfg
	staa	KVSPRT
	staa	vdgcnfg
	dec	1,x
	bne	vplms.2
	ins
	ins
	tsx

	bitb	#INPUTUP
	beq	vcalc.3
	tst	1,x
	beq	vcalc.3
	dec	1,x
	bra	vcalc.6
vcalc.3	bitb	#INPUTDN
	beq	vcalc.4
	ldaa	#$1e
	cmpa	1,x
	beq	vcalc.4
	inc	1,x
	bra	vcalc.6
vcalc.4	bitb	#INPUTLT
	beq	vcalc.5
	tst	,x
	beq	vcalc.5
	dec	,x
	bra	vcalc.6
vcalc.5	bitb	#INPUTRT
	beq	vcalc.6
	ldaa	#$1e
	cmpa	,x
	beq	vcalc.6
	inc	,x

vcalc.6	ldd	,x		check for pending collision
	jsr	bgcolck
	bcc	vcalc.7

	pulx			if collision, don't move

	ldaa	vdgcnfg		also, flash the screen (w/ CSS change)
	anda	#$bf
	staa	KVSPRT
	staa	vdgcnfg

	bra	brkchck

vcalc.7	pulx			allow movement
	stx	playpos

brkchck	ldaa	#$fb		check for BREAK
	staa	P1DATA
	ldaa	P2DATA
	anda	#$02
	bne	vloop
	jmp	exit

vloop	jmp	vblank

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
inttimr	ldd	TOCR		setup timer for ~1 frame duration
	addd	#FRAMCNT
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR

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
* Chide player into resetting statistics
*
jokescn	jsr	txtinit		setup text screen

	jsr	clrtscn		clear text screen

	ldx	#jokstr1
	pshx
	ldx	#JS1BASE
	pshx
	jsr	drawstr
	pulx
	pulx

	ldx	#jokstr2
	pshx
	ldx	#JS2BASE
	pshx
	jsr	drawstr
	pulx
	pulx

	ldaa	#$80		setup counter for 128 frames
	psha
jkstimr	ldd	TOCR		setup timer for ~1 frame duration
	addd	#FRAMCNT
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR

jkskylp	ldaa	#$fb		check for BREAK
	staa	P1DATA
	ldaa	P2DATA
	anda	#$02
	bne	jkskyl1
	jmp	exit

jkskyl1	ldaa	#$7f		check for SPACEBAR
	staa	P1DATA
	ldaa	KVSPRT
	anda	#$08
	beq	jkskyex

	ldab    TCSR		check for timer expiry
	andb    #$40
	beq     jkskylp
	tsx
	dec     ,x
	bne     jkstimr

jkskyex	ldaa	KVSPRT
	anda	#$08
	beq	jkskyex
	ins
	rts

*
* Show instruction screen
*
instscn	jsr	txtinit		setup text screen

	jsr	clrtscn		clear text screen

	ldx	#instrs1
	pshx
	ldx	#IS1BASE
	pshx
	jsr	drawstr
	pulx
	pulx

	ldx	#instrs2
	pshx
	ldx	#IS2BASE
	pshx
	jsr	drawstr
	pulx
	pulx

	ldx	#instrs3
	pshx
	ldx	#IS3BASE
	pshx
	jsr	drawstr
	pulx
	pulx

	ldx	#instrs4
	pshx
	ldx	#IS4BASE
	pshx
	jsr	drawstr
	pulx
	pulx

	ldaa	#$80		setup counter for 128 frames
	psha
instimr	ldd	TOCR		setup timer for ~1 frame duration
	addd	#FRAMCNT
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR

inskylp	ldaa	#$fb		check for BREAK
	staa	P1DATA
	ldaa	P2DATA
	anda	#$02
	bne	inskyl1
	jmp	exit

inskyl1	ldaa	#$7f		check for SPACEBAR
	staa	P1DATA
	ldaa	KVSPRT
	anda	#$08
	beq	inskyex

	ldab    TCSR		check for timer expiry
	andb    #$40
	beq     inskylp
	tsx
	dec     ,x
	bne     instimr

inskyex	ldaa	KVSPRT
	anda	#$08
	beq	inskyex
	ins
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
tlytimr	ldd	TOCR		setup timer for ~1 frame duration
	addd	#FRAMCNT
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR

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
* inpread -- read keyboard input
*
*	D clobbered
*
inpread	clrb

	ldaa	#$7f
	staa	P1DATA
	ldaa	KVSPRT
	anda	#$08
	bne	inpre.1
	orab	#INPUTBT
inpre.1	ldaa	#$f7
	staa	P1DATA
	ldaa	KVSPRT
	anda	#$04
	bne	inpre.2
	orab	#INPUTRT
inpre.2	ldaa	#$fd
	staa	P1DATA
	ldaa	KVSPRT
	anda	#$01
	bne	inpre.3
	orab	#INPUTLT
inpre.3	ldaa	#$fb
	staa	P1DATA
	ldaa	KVSPRT
	anda	#$08
	bne	inpre.4
	orab	#INPUTDN
inpre.4	ldaa	#$7f
	staa	P1DATA
	ldaa	KVSPRT
	anda	#$04
	bne	inpre.5
	orab	#INPUTUP
inpre.5	ldaa	#$ff
	staa	P1DATA

inprdex	stab	inpflgs
	rts

*
* txtinit -- setup text screen
*
txtinit	clr	KVSPRT
	clr	vdgcnfg
	rts

*
* cg3init -- setup initial CG3 video mode/screen
*
cg3init	ldaa	#$64
	staa	KVSPRT
	staa	vdgcnfg
	rts

*
* clrscrn -- clear both video fields to the background color
*
*       D,X clobbered
*
clrscrn	ldx	#VBASE
	clra
	clrb
clrsc.1	std	,x
	inx
	inx
	cpx	#VBASE+VSIZE
	blt	clrsc.1
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
* bgcolck -- check for collision with background
*
*	D -- x- and y-coordinate (in A and B)
*
*	D,X clobbered
*
bgcolck	psha			save x-offset

	lslb			transform x- and y-offset to pointer
	lslb
	ldx	#bgclmap
	abx
	lsra
	lsra
	lsra
	tab
	abx

	pula			use x-offset to build bitmask
	anda	#$07
	inca
	ldab	#$c0		two bits wide for tile/sprite size

bgclck1	deca
	beq	bgclck2
	lsrb
	bra	bgclck1

bgclck2	bitb	,x		check bitmask against collision map
	bne	bgclckx			at each relevant position
	bitb	4,x
	bne	bgclckx
	cmpb	#$01
	bne	bgclck3
	ldab	#$80
	bitb	1,x
	bne	bgclckx
	bitb	5,x
	bne	bgclckx

bgclck3	clc			clear carry on no collision
	rts

bgclckx	sec			set carry on collision
	rts

*
* bgcmini -- init background collision map
*
*	D,X clobbered
*
bgcmini	ldx	#plyfmap
	pshx
	ldaa	#plyfmsz	init map size counter
	psha

	ldx	#bgclmap
bginilp	clr	,x
	inx
	deca
	bne	bginilp
	ldx	#bgclmap
	pshx

bgcloop	psha

	tsx
	ldx	4,x
	ldaa	,x
	psha
	inx
	pshx
	pula
	pulb
	tsx
	std	5,x

	ldaa	,x
	clrb
	lsrd
	oraa	,x
	inx
	ins

	oraa	,x
	inx
	ins
	ldx	,x
	staa	4,x

	oraa	,x
	staa	,x

	inx
	pshb
	pshx
	pula
	pulb
	tsx
	std	1,x

	pulb
	inx

	tba
	dec	2,x
	bne	bgcloop

	ldab	#$05
	abx
	txs
	rts


*
* plfdraw -- draw playfield based on plyfmap data
*
*	D,X clobbered
*
plfdraw	ldx	#plyfmap	init map pointer value
	clra			init x- and y- coordinates
	clrb
	pshb
	psha
	ldaa	#$04		init map byte width counter
	psha
	ldaa	#plyfmsz	init map size counter
	psha
	pshx

plfloop	pulx			load next byte of map data
	ldaa	,x
	inx
	pshx
	ldab	#$08		init bit counter for current byte
plfloo1	asla			check for tile indicator
	bcc	plftskp

	pshb			save important data
	psha
	tsx			retrieve current x- and y-pos
	ldd	6,x
	ldx	#bartree	point to data for bare tree
	jsr	tiledrw		draw bare tree tile
	pula			restore important data
	pulb

plftskp	tsx			advance x-pos
	inc	4,x

	decb			decrement bit counter
	bne	plfloo1		process data for next bit

	dec	3,x		check for end of map row
	bne	plflxck		if not move along

	ldaa	#$04		reset map byte width counter
	staa	3,x

	clr	4,x		reset x-pos
	inc	5,x		advance y-pos

plflxck	dec	2,x		check for end of map data
	bne	plfloop		if not, loop

	ldab	#$06		clean-up stack
	abx
	txs
	rts

*
* tileras -- erase background tile
*
*	D -- x- and y-coordinate (in A and B)
*
*	D,X clobbered
*
tileras	jsr	cvtpos
	addd	#VBASE
	pshb
	psha
	pulx

	clra
	clrb
	std	,x
	std	$20,x
	std	$40,x
	std	$60,x

	ldab	#$80
	abx
	clrb
	std	,x
	std	$20,x

	rts

*
* tiledrw -- draw background tile
*
*	D -- x- and y-coordinate (in A and B)
*	X -- pointer to tile data
*
*	D,X clobbered
*
tiledrw	pshx
	jsr	cvtpos
	addd	#VBASE
	pshb
	psha
	tsx

	ldx	2,x
	ldd	,x
	tsx
	pulx
	eora	,x
	eorb	1,x
	std	,x

	ldab	#$20
	abx
	pshx

	tsx
	ldx	2,x
	ldd	2,x
	pulx
	eora	,x
	eorb	1,x
	std	,x

	ldab	#$20
	abx
	pshx

	tsx
	ldx	2,x
	ldd	4,x
	pulx
	eora	,x
	eorb	1,x
	std	,x

	ldab	#$20
	abx
	pshx

	tsx
	ldx	2,x
	ldd	6,x
	pulx
	eora	,x
	eorb	1,x
	std	,x

	ldab	#$20
	abx
	pshx

	tsx
	ldx	2,x
	ldd	8,x
	pulx
	eora	,x
	eorb	1,x
	std	,x

	ldab	#$20
	abx
	pshx

	tsx
	ldx	2,x
	ldd	10,x
	pulx
	eora	,x
	eorb	1,x
	std	,x

	pula
	pulb
	rts

*
* cvtpos -- convert grid position to screen offset
*
*	D -- x- and y-coordinate (in A and B)
*
cvtpos	pshb
	psha
	tsx
	tba
	ldab	,x
	clrb
	lsrd
	adda	1,x
	lsrd
	lsrd
	orab	,x
	ins
	ins
	rts

*
* Advance the LFSR value and return pseudo-random value
*
*	A returns pseudo-random value
*	B gets clobbered
*
* 	Wikipedia article on LFSR cites this polynomial for a maximal 8-bit LFSR:
*
*		x8 + x6 + x5 + x4 + 1
*
*	http://en.wikipedia.org/wiki/Linear_feedback_shift_register
*
lfsrget	ldaa	lfsrdat		Get MSB of LFSR data
	anda	#$80		Capture x8 of LFSR polynomial
	lsra
	lsra
	eora	lfsrdat		Capture X6 of LFSR polynomial
	lsra
	eora	lfsrdat		Capture X5 of LFSR polynomial
	lsra
	eora	lfsrdat		Capture X4 of LFSR polynomial
	lsra			Move result to Carry bit of CC
	lsra
	lsra
	lsra
	ldaa	lfsrdat		Get all of LFSR data
	rola			Shift result into 8-bit LFSR
	staa	lfsrdat		Store the result
	rts

*
* Exit to Micro Color BASIC
*
exit	jsr	clrscrn

	ldx	RESET
	jmp	,x

*
* Data Declarations
*
snowman	fcb	$05,$40
	fcb	$19,$90
	fcb	$15,$50
	fcb	$56,$94
	fcb	$59,$64
	fcb	$15,$50

xmstree	fcb	$01,$00
	fcb	$05,$40
	fcb	$15,$50
	fcb	$55,$54
	fcb	$03,$00
	fcb	$03,$00

bartree	fcb	$00,$80
	fcb	$83,$00
	fcb	$3B,$F8
	fcb	$0E,$00
	fcb	$0B,$00
	fcb	$0E,$00

player	fcb	%00000010,%00000000
	fcb	%00101010,%10100000
	fcb	%00100010,%00100000
	fcb	%00000010,%00000000
	fcb	%00001000,%10000000
	fcb	%00101000,%10100000

plyfmap	fcb	%10101010,%10101010,%10101010,%10101010
	fcb	%00000000,%00000000,%00000000,%00000000
	fcb	%01010100,%00000000,%00000000,%01010100
	fcb	%00000000,%00000000,%00000000,%00000000

	fcb	%10100000,%00000000,%01000000,%00001010
	fcb	%00000000,%00000000,%00000000,%00000000
	fcb	%01000000,%00100001,%00010000,%00000100
	fcb	%00000000,%10000000,%01000100,%00000000

	fcb	%10000000,%00000000,%00010001,%01000010
	fcb	%00000001,%01000000,%01000100,%00000000
	fcb	%01000100,%00010000,%00010000,%00000100
	fcb	%00000001,%01000000,%00000000,%00000000

	fcb	%10000000,%00010000,%00000000,%00000010
	fcb	%00000000,%01000000,%00000000,%00000000
	fcb	%01000000,%00000000,%00000000,%00000100
	fcb	%00000000,%00000000,%00000000,%00000000

	fcb	%10000000,%00000000,%00000000,%00000010
	fcb	%00000000,%00000000,%00000000,%00000000
	fcb	%01000000,%10000000,%00100000,%10000100
	fcb	%00000010,%00100000,%00000000,%00000000

	fcb	%10000000,%10001000,%00001000,%10000010
	fcb	%00000010,%00100000,%00000000,%00000000
	fcb	%01000000,%10000100,%00000101,%00000100
	fcb	%00000010,%00000000,%00000000,%00000000

	fcb	%10000000,%10000000,%00000010,%00000010
	fcb	%00000000,%00000000,%00000000,%00000000
	fcb	%01000000,%00000000,%00000000,%00010100
	fcb	%00000000,%00000000,%00000000,%00000000

	fcb	%10100000,%00000000,%00000000,%00101010
	fcb	%00000000,%00000000,%00000000,%00000000
	fcb	%01010101,%01000000,%00000101,%01010100
	fcb	%00000000,%00000000,%00000000,%00000000
plyfmsz	equ	*-plyfmap

*
* Joke screen data
*
jokstr1	fcb	$39,$39,$20,$14,$12,$09,$05,$13,$20,$09,$13,$20,$05,$0e,$0f,$15
	fcb	$07,$08,$20,$06,$0f,$12,$20,$01,$0e,$19,$0f,$0e,$05,$21,$00

jokstr2	fcb	$14,$09,$0d,$05,$20,$06,$0f,$12,$20,$01,$20,$0e,$05,$17,$20,$10
	fcb	$0c,$01,$19,$05,$12,$3f,$00

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
* Instruction screen data
*
instrs1	fcb	$05,$0e,$14,$05,$12,$20,$14,$08,$05,$20,$06,$0f,$12,$05,$13,$14
	fcb	$2c,$00

instrs2	fcb	$13,$05,$09,$1a,$05,$20,$14,$08,$05,$20,$0c,$01,$13,$14,$20,$18,$0d
	fcb	$01,$13,$20,$14,$12,$05,$05,$2c,$00

instrs3	fcb	$05,$13,$03,$01,$10,$05,$20,$14,$08,$05,$20,$05,$16,$09,$0c,$20
	fcb	$13,$0e,$0f,$17,$0d,$05,$0e,$2e,$2e,$2e,$00

instrs4	fcb	$03,$01,$12,$10,$05,$20,$01,$12,$02,$0f,$12,$05,$13,$21,$00

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

inpflgs	rmb	1

lfsrdat	rmb	1

mvdlrst	rmb	1
mvdlcnt	rmb	1

bgclmap	rmb	plyfmsz

playpos	rmb	2
xmstpos	rmb	2

snw1pos	rmb     2
snw2pos	rmb	2
snw3pos	rmb	2
snw4pos	rmb	2

players	rmb	2
xmsters	rmb	2

snw1ers	rmb     2
snw2ers	rmb	2
snw3ers	rmb	2
snw4ers	rmb	2

atmpcnt	rmb	1
seizcnt	rmb	1
escpcnt	rmb	1

vdgcnfg	rmb	1

	end	START
