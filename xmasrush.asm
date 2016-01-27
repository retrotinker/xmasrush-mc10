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

FRMCT60	equ	14934		60Hz frame timer value
FRMCT50	equ	17784		50Hz frame timer value

VBLNK60	equ	3762		60Hz vblank timer value
VBLNK50	equ	6612		50Hz vblank timer value

VACTCNT	equ	FRMCT60-VBLNK60	same for both 50Hz and 60Hz

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

GMFXMTR	equ	$01		game status bit flag definitions
GMFSNW1	equ	$02
GMFSNW2	equ	$04
GMFSNW3	equ	$08
GMFSNW4	equ	$10

MVDLR60	equ	$08		60Hz reset value for movement delay counter
MVDLR50	equ	$07		50Hz reset value for movement delay counter

SNMDR60	equ	$10		60Hz reset value for snowman move delay counter
SNMDR50	equ	$0d		50Hz reset value for snowman move delay counter

#IS1BASE	equ	(TXTBASE+5*32+3)	 string display location info
IS1BASE	equ	$40a3		string display location info
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

XMRBASE	equ	$402b	(TXTBASE+1*32+11)
TMCBASE	equ	$4067	(TXTBASE+3*32+7)
UDABASE	equ	$40c5	(TXTBASE+6*32+5)
TOMBASE	equ	$40e9	(TXTBASE+7*32+9)
CPGBASE	equ	$4108	(TXTBASE+8*32+8)
STCBASE	equ	$4166	(TXTBASE+11*32+6)
SHSBASE	equ	$41a3	(TXTBASE+13*32+3)
RTXBASE	equ	$41c3	(TXTBASE+14*32+3)

#PLAYPOS	equ	(TXTBASE+(9*32)+24)
PLAYPOS	equ	$4138

	org	START

	ldab	TIMER		Seed the LFSR data
	bne	lfsrini		Can't tolerate a zero-value LFSR seed...
	ldab	#$01
lfsrini	stab	lfsrdat

	jsr	bgcmini		init background collision map

	ldd	#FRMCT60	setup default frame timing count
	std	framcnt
	ldd	#VBLNK60
	std	vblkcnt

	ldaa	#MVDLR60	setup default movement counts
	staa	mvdlrst
	ldaa	#SNMDR60
	staa	snmdrst

	clr	atmpcnt		clear results tallies
	clr	seizcnt
	clr	escpcnt

	jsr	timrcal		manually synchronize timer w/ screen

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

tmsyn.1	ldab	TCSR
	andb	#$40
	beq	tmsyn.1

	ldd	TOCR
	addd	framcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR

	jsr	clrscrn

	jsr	cg3init

tmsyn.2	ldab	TCSR
	andb	#$40
	beq	tmsyn.2

	ldd	TOCR
	addd	framcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR

	jsr	plfdraw

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

	ldaa	snmdrst		reset snowman movement delay counters
	staa	sn1mcnt
	staa	sn2mcnt
	staa	sn3mcnt
	staa	sn4mcnt

	ldd	playpos		set initial target for snowman 1
	std	snw1tgt

	clra			initialize game status flags
	oraa	#GMFXMTR
	oraa	#GMFSNW4
	ldab	escpcnt
	cmpb	#$01
	blt	gmfli.1
	oraa	#GMFSNW1
gmfli.1	cmpb	#$02
	blt	gmfli.2
	oraa	#GMFSNW3
gmfli.2	cmpb	#$03
	blt	gmfli.3
	oraa	#GMFSNW2
gmfli.3	staa	gamflgs

vblank	ldab    TCSR		check for timer expiry
	andb    #$40
	bne	vtimer
	jmp	brkchck

vtimer	ldd	TOCR		setup timer for ~1 frame duration
	addd	framcnt
	pshb
	psha
	pulx
	ldab    TCSR
	stx     TOCR

	ldaa	vdgcnfg		restore CSS for BCMO colors
	oraa	#$40
	staa	KVSPRT
	staa	vdgcnfg

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

vdraw	ldaa	#GMFXMTR	check if xmas tree already taken
	bita	gamflgs
	beq	vdraw.1

	ldd	xmstpos
	std	xmsters
	ldx	#xmstree
	jsr	tiledrw

vdraw.1	ldaa	#GMFSNW1	check if snowman 1 is active
	bita	gamflgs
	beq	vdraw.2

	ldd	snw1pos
	std	snw1ers
	ldx	#snowman
	jsr	tiledrw

vdraw.2	ldaa	#GMFSNW2	check if snowman 2 is active
	bita	gamflgs
	beq	vdraw.3

	ldd	snw2pos
	std	snw2ers
	ldx	#snowman
	jsr	tiledrw

vdraw.3	ldaa	#GMFSNW3	check if snowman 3 is active
	bita	gamflgs
	beq	vdraw.4

	ldd	snw3pos
	std	snw3ers
	ldx	#snowman
	jsr	tiledrw

vdraw.4	ldaa	#GMFSNW4	check if snowman 4 is active
	bita	gamflgs
	beq	vdraw.5

	ldd	snw4pos
	std	snw4ers
	ldx	#snowman
	jsr	tiledrw

vdraw.5	ldd	playpos
	std	players
	ldx	#player
	jsr	tiledrw

vcheck	ldx	playpos
	pshx
	ldaa	#GMFSNW1
	bita	gamflgs
	beq	vchck.1
	ldx	#snw1pos	check for player collision w/ snowman 1
	jsr	spcolck
	bcc	vchck.1
	ins
	ins
	jmp	loss
vchck.1	ldaa	#GMFSNW2
	bita	gamflgs
	beq	vchck.2
	ldx	#snw2pos	check for player collision w/ snowman 2
	jsr	spcolck
	bcc	vchck.2
	ins
	ins
	jmp	loss
vchck.2	ldaa	#GMFSNW3
	bita	gamflgs
	beq	vchck.3
	ldx	#snw3pos	check for player collision w/ snowman 3
	jsr	spcolck
	bcc	vchck.3
	ins
	ins
	jmp	loss
vchck.3	ldaa	#GMFSNW4
	bita	gamflgs
	beq	vchck.4
	ldx	#snw4pos	check for player collision w/ snowman 4
	jsr	spcolck
	bcc	vchck.4
	ins
	ins
	jmp	loss
vchck.4	ins
	ins

vcalc	ldaa	#GMFXMTR	check for player escape
	bita	gamflgs
	bne	vcalc.0
	ldaa	playpos+1
	cmpa	#$1e
	blt	vcalc.0

	jmp	win

vcalc.0	jsr	inpread		read player input for next frame

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

	bra	vcalc.8

vcalc.7	pulx			allow movement
	stx	playpos

vcalc.8	jsr	snw1mov		calculate snowman movement targets
	jsr	snw2mov
	jsr	snw3mov
	jsr	snw4mov

vcalc.9	ldx	playpos		check for player collision w/ xmas tree
	pshx
	ldx	#xmstpos
	jsr	spcolck
	bcc	vcalc.a

	ldaa	#GMFXMTR	if so, turn-off game flag for xmas tree
	bita	gamflgs
	beq	vcalc.a
	coma
	anda	gamflgs
	staa	gamflgs

	ldaa	#$40		play short "beep" as audio indicator
	psha
	psha
	tsx
vxmts.1	brn	*		hard-coded delay, approximately 57 cycles
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	nop
vxmts.2	nop			outer loop re-entry, fix-up for lost cycles
	nop
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	dec	,x
	bne	vxmts.1
	ldaa	#$04
	staa	,x
	ldaa	vdgcnfg
	eora	#SQWAVE
	staa	KVSPRT
	staa	vdgcnfg
	dec	1,x
	bne	vxmts.2
	ins
	ins
	tsx

vcalc.a	ins
	ins

brkchck	ldaa	#$fb		check for BREAK
	staa	P1DATA
	ldaa	P2DATA
	anda	#$02
	bne	vloop
brkck.1	ldaa	P2DATA
	anda	#$02
	bne	brkck.2

	ldab	TCSR
	andb	#$40
	beq	brkck.1

	ldd	TOCR
	addd	framcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR
	bra	brkck.1

brkck.2	jmp	loss

vloop	jmp	vblank

win	ldab	TCSR
	andb	#$40
	beq	win

	ldd	TOCR
	addd	framcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR

	ldaa	seizcnt		bump seizure and escape counts
	adda	#$01
	daa
	staa	seizcnt
	ldaa	escpcnt
	adda	#$01
	daa
	staa	escpcnt

win.0	ldaa	#$18		play short "high tone" as audio indicator
	psha
	ldaa	#$10
	psha
	tsx
win.1	brn	*		hard-coded delay, approximately 57 cycles
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	nop
win.2	nop			outer loop re-entry, fix-up for lost cycles
win.3	nop			outer loop re-entry, fix-up for lost cycles
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	dec	,x
	bne	win.1
	ldaa	#$10							2
	staa	,x							4
	ldaa	vdgcnfg							4
	eora	#SQWAVE							2
	staa	KVSPRT							4
	staa	vdgcnfg							4	20

	ldab    TCSR		check for timer expiry			3
	andb    #$40							2
	bne	win.4							3
	jmp	win.3							3	11	31

win.4	ldd	TOCR		setup timer for ~1 frame duration	4
	addd	framcnt							6
	pshb								3
	psha								3
	pulx								5
	ldab    TCSR							3
	stx     TOCR							4	28

	tsx								3
	dec	1,x							6
	beq	win.6							3	12	40 + 31 = 71

	ldaa	#$7f		check for SPACEBAR			2
	staa	P1DATA							4
	ldaa	KVSPRT							4
	anda	#$08							2
	bne	win.2							3	15	71 + 15 = 86 => 57 + 29

win.5	ldaa	KVSPRT
	anda	#$08
	beq	win.5

win.6	ins
	ins

	ldd	#$0100
	pshb
	psha
	jsr	talyscn
	ins
	ins

	bcc	win.7
	jmp	restrt1

win.7	jmp	restart

loss	ldab	TCSR
	andb	#$40
	beq	loss

	ldd	TOCR
	addd	framcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR

	ldaa	#GMFXMTR	bump seizure count, if appropriate
	bita	gamflgs
	bne	loss.0

	ldaa	seizcnt
	adda	#$01
	daa
	staa	seizcnt

loss.0	ldaa	#$18		play short "buzz" as audio indicator
	psha
	clra
	psha
	tsx
loss.1	brn	*		hard-coded delay, approximately 57 cycles
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	nop
loss.2	nop			outer loop re-entry, fix-up for lost cycles
loss.3	nop			outer loop re-entry, fix-up for lost cycles
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	brn	*
	dec	,x
	bne	loss.1
	ldaa	vdgcnfg							4
	eora	#SQWAVE							2
	staa	KVSPRT							4
	staa	vdgcnfg							4	14

	ldab    TCSR		check for timer expiry			3
	andb    #$40							2
	bne	loss.4							3
	jmp	loss.3							3	11	25

loss.4	ldd	TOCR		setup timer for ~1 frame duration	4
	addd	framcnt							6
	pshb								3
	psha								3
	pulx								5
	ldab    TCSR							3
	stx     TOCR							4	28

	tsx								3
	dec	1,x							6
	beq	loss.6							3	12	40 + 25 = 65

	ldaa	#$7f		check for SPACEBAR			2
	staa	P1DATA							4
	ldaa	KVSPRT							4
	anda	#$08							2
	bne	loss.2							3	15	65 + 15 = 80 => 57 + 23

loss.5	ldaa	KVSPRT
	anda	#$08
	beq	loss.5

loss.6	ins
	ins

	ldd	#$0100
	pshb
	psha
	jsr	talyscn
	ins
	ins

	bcc	loss.7
	jmp	restrt1

loss.7	jmp	restart

*
* Move snowman 1
*
snw1mov	dec	sn1mcnt
	beq	snw1m.0
	jmp	snw1mvx

snw1m.0	ldaa	snmdrst
	staa	sn1mcnt

	ldaa	#GMFXMTR
	bita	gamflgs
	bne	snw1m.1

	ldd	playpos
	std	snw1tgt

snw1m.1	ldd	snw1pos
	cmpa	snw1tgt
	blt	snw1m.2
	bgt	snw1m.3

	jsr	lfsrget
	anda	#$1f
	staa	snw1tgt
	ldaa	snw1pos
	bra	snw1m.4

snw1m.2	inca
	bra	snw1m.4

snw1m.3	deca

snw1m.4	pshb
	psha
	jsr	bgcolck
	bcs	snw1m.5

	ldx	#xmstpos
	jsr	spcolck
	bcs	snw1m.5

	tsx

	ldd	snw2pos
	cmpa	,x
	bne	snw1m.6
	cmpb	1,x
	bne	snw1m.6
	bra	snw1m.5

	ldd	snw3pos
	cmpa	,x
	bne	snw1m.6
	cmpb	1,x
	bne	snw1m.6
	bra	snw1m.5

	ldd	snw4pos
	cmpa	,x
	bne	snw1m.6
	cmpb	1,x
	bne	snw1m.6

snw1m.5	ins
	ins
	jsr	lfsrget
	anda	#$1f
	staa	snw1tgt
	ldd	snw1pos
	bra	snw1m.7

snw1m.6	pula
	pulb
	std	snw1pos

snw1m.7	cmpb	snw1tgt+1
	blt	snw1m.8
	bgt	snw1m.9

	jsr	lfsrget
	anda	#$1f
	staa	snw1tgt+1
	ldaa	snw1pos
	bra	snw1m.a

snw1m.8	incb
	bra	snw1m.a

snw1m.9	decb

snw1m.a	pshb
	psha
	jsr	bgcolck
	bcs	snw1m.b

	ldx	#xmstpos
	jsr	spcolck
	bcs	snw1m.b

	tsx

	ldd	snw2pos
	cmpa	,x
	bne	snw1m.c
	cmpb	1,x
	bne	snw1m.c
	bra	snw1m.b

	ldd	snw3pos
	cmpa	,x
	bne	snw1m.c
	cmpb	1,x
	bne	snw1m.c
	bra	snw1m.b

	ldd	snw4pos
	cmpa	,x
	bne	snw1m.c
	cmpb	1,x
	bne	snw1m.c

snw1m.b	ins
	ins
	jsr	lfsrget
	anda	#$1e
	staa	snw1tgt+1
	bra	snw1mvx

snw1m.c	pula
	pulb
	std	snw1pos

snw1mvx	rts

*
* Move snowman 2
*
snw2mov	dec	sn2mcnt
	beq	snw2m.0
	jmp	snw2mvx

snw2m.0	ldaa	snmdrst
	staa	sn2mcnt

	ldd	snw2pos
	cmpa	playpos
	blt	snw2m.1
	bgt	snw2m.2
	bra	snw2m.3

snw2m.1	inca
	bra	snw2m.3

snw2m.2	deca

snw2m.3	pshb
	psha
	jsr	bgcolck
	bcs	snw2m.4

	ldx	#xmstpos
	jsr	spcolck
	bcs	snw2m.4

	tsx

	ldd	snw1pos
	cmpa	,x
	bne	snw2m.5
	cmpb	1,x
	bne	snw2m.5
	bra	snw2m.4

	ldd	snw3pos
	cmpa	,x
	bne	snw2m.5
	cmpb	1,x
	bne	snw2m.5
	bra	snw2m.4

	ldd	snw4pos
	cmpa	,x
	bne	snw2m.5
	cmpb	1,x
	bne	snw2m.5

snw2m.4	ins
	ins
	ldd	snw2pos
	bra	snw2m.6

snw2m.5	pula
	pulb
	std	snw2pos

snw2m.6	cmpb	playpos+1
	blt	snw2m.7
	bgt	snw2m.8
	bra	snw2m.9

snw2m.7	incb
	bra	snw2m.9

snw2m.8	decb

snw2m.9	pshb
	psha
	jsr	bgcolck
	bcs	snw2m.a

	ldx	#xmstpos
	jsr	spcolck
	bcs	snw2m.a

	tsx

	ldd	snw1pos
	cmpa	,x
	bne	snw2m.b
	cmpb	1,x
	bne	snw2m.b
	bra	snw2m.a

	ldd	snw3pos
	cmpa	,x
	bne	snw2m.b
	cmpb	1,x
	bne	snw2m.b
	bra	snw2m.a

	ldd	snw4pos
	cmpa	,x
	bne	snw2m.b
	cmpb	1,x
	bne	snw2m.b

snw2m.a	ins
	ins
	bra	snw2mvx

snw2m.b	pula
	pulb
	std	snw2pos

snw2mvx	rts

*
* Move snowman 3
*
snw3mov	dec	sn3mcnt
	beq	snw3m.0
	jmp	snw3mvx

snw3m.0	ldaa	snmdrst
	staa	sn3mcnt

	ldaa	#GMFXMTR
	bita	gamflgs
	bne	snw3m.1

	ldd	playpos
	std	snw3tgt
	bra	snw3m.2

snw3m.1	ldd	playpos
	suba	xmstpos
	asra
	adda	xmstpos
	subb	xmstpos+1
	asrb
	addb	xmstpos+1
	std	snw3tgt

snw3m.2	ldd	snw3pos
	cmpa	snw3tgt
	blt	snw3m.3
	bgt	snw3m.4
	bra	snw3m.5

snw3m.3	inca
	bra	snw3m.5

snw3m.4	deca

snw3m.5	pshb
	psha
	jsr	bgcolck
	bcs	snw3m.6

	ldx	#xmstpos
	jsr	spcolck
	bcs	snw3m.6

	inx

	ldd	snw1pos
	cmpa	,x
	bne	snw3m.7
	cmpb	1,x
	bne	snw3m.7
	bra	snw3m.6

	ldd	snw2pos
	cmpa	,x
	bne	snw3m.7
	cmpb	1,x
	bne	snw3m.7
	bra	snw3m.6

	ldd	snw4pos
	cmpa	,x
	bne	snw3m.7
	cmpb	1,x
	bne	snw3m.7

snw3m.6	ins
	ins
	ldd	snw3pos
	bra	snw3m.8

snw3m.7	pula
	pulb
	std	snw3pos

snw3m.8	cmpb	snw3tgt+1
	blt	snw3m.9
	bgt	snw3m.a
	bra	snw3m.b

snw3m.9	incb
	bra	snw3m.b

snw3m.a	decb

snw3m.b	pshb
	psha
	jsr	bgcolck
	bcs	snw3m.c

	ldx	#xmstpos
	jsr	spcolck
	bcs	snw3m.c

	inx

	ldd	snw1pos
	cmpa	,x
	bne	snw3m.d
	cmpb	1,x
	bne	snw3m.d
	bra	snw3m.c

	ldd	snw2pos
	cmpa	,x
	bne	snw3m.d
	cmpb	1,x
	bne	snw3m.d
	bra	snw3m.c

	ldd	snw4pos
	cmpa	,x
	bne	snw3m.d
	cmpb	1,x
	bne	snw3m.d

snw3m.c	ins
	ins
	bra	snw3mvx

snw3m.d	pula
	pulb
	std	snw3pos

snw3mvx	rts

*
* Move snowman 4
*
snw4mov	dec	sn4mcnt
	beq	snw4m.0
	jmp	snw4mvx

snw4m.0	ldaa	snmdrst
	staa	sn4mcnt

	ldaa	#GMFXMTR
	bita	gamflgs
	bne	snw4m.1

	ldd	playpos
	cmpb	#$1a
	blt	snw4m.1

	std	snw4tgt

snw4m.1	ldd	snw4pos
	cmpa	snw4tgt
	blt	snw4m.2
	bgt	snw4m.3

	jsr	lfsrget
	anda	#$07
	adda	#$0b
	staa	snw4tgt
	ldaa	snw4pos
	bra	snw4m.4

snw4m.2	inca
	bra	snw4m.4

snw4m.3	deca

snw4m.4	pshb
	psha
	jsr	bgcolck
	bcs	snw4m.5

	ldx	#xmstpos
	jsr	spcolck
	bcs	snw4m.5

	tsx

	ldd	snw1pos
	cmpa	,x
	bne	snw4m.6
	cmpb	1,x
	bne	snw4m.6
	bra	snw4m.5

	ldd	snw2pos
	cmpa	,x
	bne	snw4m.6
	cmpb	1,x
	bne	snw4m.6
	bra	snw4m.5

	ldd	snw3pos
	cmpa	,x
	bne	snw4m.6
	cmpb	1,x
	bne	snw4m.6

snw4m.5	ins
	ins
	jsr	lfsrget
	anda	#$07
	adda	#$0b
	staa	snw4tgt
	ldd	snw4pos
	bra	snw4m.7

snw4m.6	pula
	pulb
	std	snw4pos

snw4m.7	cmpb	snw4tgt+1
	blt	snw4m.8
	bgt	snw4m.9

	jsr	lfsrget
	anda	#$07
	adda	#$17
	staa	snw4tgt+1
	ldaa	snw4pos
	bra	snw4m.a

snw4m.8	incb
	bra	snw4m.a

snw4m.9	decb

snw4m.a	pshb
	psha
	jsr	bgcolck
	bcs	snw4m.b

	ldx	#xmstpos
	jsr	spcolck
	bcs	snw4m.b

	tsx

	ldd	snw1pos
	cmpa	,x
	bne	snw4m.c
	cmpb	1,x
	bne	snw4m.c
	bra	snw4m.b

	ldd	snw2pos
	cmpa	,x
	bne	snw4m.c
	cmpb	1,x
	bne	snw4m.c
	bra	snw4m.b

	ldd	snw3pos
	cmpa	,x
	bne	snw4m.c
	cmpb	1,x
	bne	snw4m.c

snw4m.b	ins
	ins
	jsr	lfsrget
	anda	#$07
	adda	#$17
	staa	snw4tgt+1
	bra	snw4mvx

snw4m.c	pula
	pulb
	std	snw4pos

snw4mvx	rts

*
* Show timer calibration screen
*
timrcal	jsr	txtinit		setup text screen

	jsr	clrtscn		clear text screen

	ldx	#xmrustr
	pshx
	ldx	#XMRBASE
	pshx
	jsr	drawstr
	pulx
	pulx

	ldx	#tmclstr
	pshx
	ldx	#TMCBASE
	pshx
	jsr	drawstr
	pulx
	pulx

	ldx	#udarstr
	pshx
	ldx	#UDABASE
	pshx
	jsr	drawstr
	pulx
	pulx

	ldx	#tomkstr
	pshx
	ldx	#TOMBASE
	pshx
	jsr	drawstr
	pulx
	pulx

	ldx	#cmpgstr
	pshx
	ldx	#CPGBASE
	pshx
	jsr	drawstr
	pulx
	pulx

	ldx	#shftstr
	pshx
	ldx	#SHSBASE
	pshx
	jsr	drawstr
	pulx
	pulx

	ldaa	mvdlrst
	cmpa	#MVDLR60
	bne	timrc.1
	ldx	#tm60str
	bra	timrc.2
timrc.1	ldx	#tm50str
timrc.2	pshx
	ldx	#SHSBASE+22
	pshx
	jsr	drawstr
	pulx
	pulx

	ldx	#sptcstr
	pshx
	ldx	#STCBASE
	pshx
	jsr	drawstr
	pulx
	pulx

	ldx	#rmtxstr
	pshx
	ldx	#RTXBASE
	pshx
	jsr	drawstr
	pulx
	pulx

	ldaa	#$40
	staa	KVSPRT
	staa	vdgcnfg

timrc.3	ldd	TOCR
	addd	vblkcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR
timrc.4	ldab	TCSR
	andb	#$40
	beq	timrc.4

	ldaa	vdgcnfg
	eora	#$40
	staa	>$bfff
	staa	vdgcnfg

	ldd	TOCR
	addd	#VACTCNT
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR

	ldaa	#$7f		check for SHIFT
	staa	P1DATA
	ldaa	P2DATA
	anda	#$02
	bne	timrc.8

	ldaa	mvdlrst
	cmpa	#MVDLR60
	bne	timrc.6

timrc.5	ldd	#FRMCT50	setup 50Hz frame timing count
	std	framcnt
	ldd	#VBLNK50
	std	vblkcnt

	ldaa	#MVDLR50	setup 50Hz movement counts
	staa	mvdlrst
	ldaa	#SNMDR50
	staa	snmdrst

	bra	timrc.7

timrc.6	ldd	#FRMCT60	setup 60Hz frame timing count
	std	framcnt
	ldd	#VBLNK60
	std	vblkcnt

	ldaa	#MVDLR60	setup 60Hz movement counts
	staa	mvdlrst
	ldaa	#SNMDR60
	staa	snmdrst

timrc.7	ldaa	P2DATA
	anda	#$02
	beq	timrc.7

	jmp	timrcal

timrc.8	ldaa	#$7f		check for SPACEBAR
	staa	P1DATA
	ldaa	KVSPRT
	anda	#$08
	beq	timrc.e

	ldaa	#$fb		check for down arrow
	staa	P1DATA
	ldaa	KVSPRT
	anda	#$08
	bne	timrc.9
	ldab	#$39
	bra	timrc.a

timrc.9	ldaa	#$7f		check for up arrow
	staa	P1DATA
	ldaa	KVSPRT
	anda	#$04
	bne	timrc.d
	ldab	#$c7

timrc.a	tstb
	bmi	timrc.b
	clra
	bra	timrc.c

timrc.b	ldaa	#$ff

timrc.c	addd	TOCR
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR

timrc.d	ldab	TCSR
	andb	#$40
	beq	timrc.d

	ldaa	vdgcnfg
	eora	#$40
	staa	>$bfff
	staa	vdgcnfg

	jmp	timrc.3

timrc.e	ldaa	KVSPRT
	anda	#$08
	bne	timrc.f

	ldab	TCSR
	andb	#$40
	beq	timrc.e

	ldd	TOCR
	addd	framcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR
	bra	timrc.e

timrc.f	rts

*
* Show intro screen
*
intro	ldab	TCSR
	andb	#$40
	beq	intro

	ldd	TOCR
	addd	framcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR

	jsr	txtinit		setup text screen

	ldx	#intscrn	write intro screen data to buffer
	pshx
	ldx	#TXTBASE
	pshx
	tsx
	ldx	2,x
intsclp	ldab	TCSR
	andb	#$40
	beq	intsl.1

	ldd	TOCR
	addd	framcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR
	tsx
	ldx	2,x

intsl.1	ldaa	,x
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

inttmst	ldab	TCSR
	andb	#$40
	beq	inttmst
inttimr	ldd	TOCR		setup timer for ~1 frame duration
	addd	framcnt
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

intkyl1	ldaa	#$fe		check for CONTROL
	staa	P1DATA
	ldaa	P2DATA
	anda	#$02
	bne	intkyl2

	clr	atmpcnt		clear results tallies
	clr	seizcnt
	clr	escpcnt

	bra	intkyto

intkyl2	ldaa	#$7f		check for SPACEBAR
	staa	P1DATA
	ldaa	KVSPRT
	anda	#$08
	beq	intkypr

	ldab    TCSR		check for timer expiry
	andb    #$40
	beq     intkylp
	tsx
	dec     ,x
	bne     intkyl3

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

intkyl3	dec	4,x
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
	bne	intkp.1

	ldab	TCSR
	andb	#$40
	beq	intkypr

	ldd	TOCR
	addd	framcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR
	bra	intkypr

intkp.1	sec
intkyex	ins
	rts

*
* Chide player into resetting statistics
*
jokescn	ldab	TCSR
	andb	#$40
	beq	jokescn

	ldd	TOCR
	addd	framcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR

	jsr	txtinit		setup text screen

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

jkstmst	ldab	TCSR
	andb	#$40
	beq	jkstmst
jkstimr	ldd	TOCR		setup timer for ~1 frame duration
	addd	framcnt
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

jkskyl1	ldaa	#$fe		check for CONTROL
	staa	P1DATA
	ldaa	P2DATA
	anda	#$02
	bne	jkskyl2

	clr	atmpcnt		clear results tallies
	clr	seizcnt
	clr	escpcnt

	ins
	rts

jkskyl2	ldaa	#$7f		check for SPACEBAR
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
	bne	jkskx.1

	ldab	TCSR
	andb	#$40
	beq	jkskyex

	ldd	TOCR
	addd	framcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR
	bra	jkskyex

jkskx.1	ins
	rts

*
* Show instruction screen
*
instscn	ldab	TCSR
	andb	#$40
	beq	instscn

	ldd	TOCR
	addd	framcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR

	jsr	txtinit		setup text screen

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
instmst	ldab	TCSR
	andb	#$40
	beq	instmst
instimr	ldd	TOCR		setup timer for ~1 frame duration
	addd	framcnt
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
	bne	inskx.1

	ldab	TCSR
	andb	#$40
	beq	inskyex

	ldd	TOCR
	addd	framcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR
	bra	inskyex

inskx.1	ins
	rts

*
* Show tally screen
*
talyscn	ldab	TCSR
	andb	#$40
	beq	talyscn

	ldd	TOCR
	addd	framcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR

	jsr	txtinit		setup text screen

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
tlytmst	ldab	TCSR
	andb	#$40
	beq	tlytmst
tlytimr	ldd	TOCR		setup timer for ~1 frame duration
	addd	framcnt
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

tlykyl1	ldaa	#$fe		check for CONTROL
	staa	P1DATA
	ldaa	P2DATA
	anda	#$02
	bne	tlykyl2

	clr	atmpcnt		clear results tallies
	clr	seizcnt
	clr	escpcnt

	ins
	jmp	talyscn

tlykyl2	ldaa	#$7f		check for SPACEBAR
	staa	P1DATA
	ldaa	KVSPRT
	anda	#$08
	beq	tlykypr

	ldab    TCSR		check for timer expiry
	andb    #$40
	beq     tlykylp
	tsx
	dec     ,x
	bne     tlykyl3

	tsx			restore counter for 30 more frames
	ldaa    #$20
	staa    ,x

tlykyl3	dec	4,x
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
	bne	tlykp.1

	ldab	TCSR
	andb	#$40
	beq	tlykypr

	ldd	TOCR
	addd	framcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR
	bra	tlykypr

tlykp.1	sec
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
* spcolck -- check for collision w/ player
*
*	2,S -- sprite position data
*	X   -- pointer to object position data
*
*	A,X clobbered
*
spcolck	ldaa	,x
	inx
	pshx
	tsx
	deca
	cmpa	4,x
	bgt	spcolcx
	adda	#$02
	cmpa	4,x
	blt	spcolcx
	ldx	,x
	ldaa	,x
	tsx
	deca
	cmpa	5,x
	bgt	spcolcx
	adda	#$02
	cmpa	5,x
	blt	spcolcx

	ins
	ins
	sec
	rts

spcolcx	ins
	ins
	clc
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

plfloop	ldab	TCSR
	andb	#$40
	beq	plfloo0

	ldd	TOCR
	addd	framcnt
	pshb
	psha
	pulx
	ldab	TCSR
	stx	TOCR

plfloo0	pulx			load next byte of map data
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

instrs2	fcb	$13,$05,$09,$1a,$05,$20,$14,$08,$05,$20,$0c,$01,$13,$14,$20,$18
	fcb	$0d,$01,$13,$20,$14,$12,$05,$05,$2c,$00

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

*
* Timer calibration screen data
*
xmrustr	fcb	$18,$0d,$01,$13,$20,$12,$15,$13,$08,$00

tmclstr	fcb	$14,$09,$0d,$05,$12,$20,$03,$01,$0c,$09,$02,$12,$01,$14,$09,$0f
	fcb	$0e,$00

udarstr	fcb	$15,$13,$05,$20,$15,$10,$20,$01,$0e,$04,$20,$04,$0f,$17,$0e,$20
	fcb	$01,$12,$12,$0f,$17,$13,$00

tomkstr	fcb	$14,$0f,$20,$0d,$01,$0b,$05,$20,$13,$03,$12,$05,$05,$0e,$00

cmpgstr	fcb	$03,$0f,$0d,$10,$0c,$05,$14,$05,$0c,$19,$20,$07,$12,$05,$05,$0e
	fcb	$00

sptcstr	fcb	$53,$50,$41,$43,$45,$42,$41,$52,$20,$14,$0f,$20,$03,$0f,$0e,$14
	fcb	$09,$0e,$15,$05,$00

rmtxstr	fcb	$12,$05,$13,$05,$14,$20,$0d,$03,$2d,$31,$30,$20,$14,$0f,$20,$05
	fcb	$0e,$04,$20,$10,$12,$0f,$07,$12,$01,$0d,$00

shftstr	fcb	$53,$48,$49,$46,$54,$20,$03,$08,$01,$0e,$07,$05,$13,$20,$14,$09
	fcb	$0d,$09,$0e,$07,$3a,$00

tm50str	fcb	$35,$30,$08,$1a,$00
tm60str	fcb	$36,$30,$08,$1a,$00

inpflgs	rmb	1
gamflgs	rmb	1

lfsrdat	rmb	1

mvdlrst	rmb	1
mvdlcnt	rmb	1

framcnt	rmb	2
vblkcnt	rmb	2

bgclmap	rmb	plyfmsz

playpos	rmb	2
xmstpos	rmb	2

snw1tgt	rmb     2
snw3tgt	rmb	2
snw4tgt	rmb	2

snw1pos	rmb     2
snw2pos	rmb	2
snw3pos	rmb	2
snw4pos	rmb	2

snmdrst	rmb	1
sn1mcnt	rmb     1
sn2mcnt	rmb	1
sn3mcnt	rmb	1
sn4mcnt	rmb	1

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
