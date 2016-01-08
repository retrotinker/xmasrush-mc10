.PHONY: all clean

LOAD=0x4400
EXEC=0x4400
#SIZE=0x0800
SIZE=0x0300

AS0=~/Downloads/6800/masm/as1
TAPEIFY=./tapeify
CAS2WAV=/home/linville/coco/cas2wav.pl

CFLAGS=-Wall

TARGETS=xmasrush.wav
TOOLS=tapeify

all: $(TOOLS) $(TARGETS)

%.obj: %.asm
	$(AS0) $< -b l

%.cas: %.obj
	$(TAPEIFY) $< $$(echo $< | cut -f1 -d. | tr [:lower:] [:upper:]) \
		$(LOAD) $(SIZE) $(EXEC)
	mv $$(echo $< | cut -f1 -d. | tr [:lower:] [:upper:]) $@

%.wav: %.cas
	$(CAS2WAV) $< $@

.c.o:
	gcc -o $@ $<

clean:
	$(RM) $(TARGETS) $(TOOLS)
