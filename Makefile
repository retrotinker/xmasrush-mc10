.PHONY: all clean

LOAD=0x4c00
EXEC=0x4c00
#SIZE=0x0800
SIZE=0x0300

AS0=~/Downloads/6800/masm/as1
TAPEIFY=./tapeify
CAS2WAV=/home/linville/coco/cas2wav.pl

CFLAGS=-Wall

TARGETS=xmasrush.cas xmasrush.wav
TOOLS=tapeify

all: $(TOOLS) $(TARGETS)

%.s19: %.asm
	$(AS0) $< -l

%.ram: %.s19
	objcopy -I srec -O binary $< $@

%.cas: %.ram
	$(TAPEIFY) $< $@ $$(echo $< | cut -f1 -d. | tr [:lower:] [:upper:]) \
		$(LOAD) $(EXEC)

%.wav: %.cas
	$(CAS2WAV) $< $@

.c.o:
	gcc -o $@ $<

clean:
	$(RM) $(TARGETS) $(TOOLS)
