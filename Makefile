MV       ?= mv
TRUNCATE ?= truncate
YASM     ?= yasm
VBR_SIZE ?= 1536
yflags   := -p nasm -r nasm -f bin -a x86 -m x86 -DDEBUG $(YFLAGS)

wasd.img: mbr.img vbr.img
	cat $^ > $@

run: wasd.img
	qemu-system-i386 "$<" 2> /dev/null

clean:
	$(RM) *.img

mbr.img: mbr_chainload_vbr.asm print.asm
	$(YASM) $(strip $(yflags)) -o "tmp.img" "$<"
	./copy-code.sh "tmp.img" 512
	$(TRUNCATE) -s512 "tmp.img"
	$(MV) "tmp.img" "$@"

vbr.img: vbr.asm print.asm
	$(YASM) $(strip $(yflags)) -DVBR_SIZE=$(VBR_SIZE) -o "tmp.img" "$<"
	./copy-code.sh "tmp.img" $(VBR_SIZE) -2
	./verify-fat-vbr.sh "tmp.img"
	$(TRUNCATE) -s$(VBR_SIZE) "tmp.img"
	$(MV) "tmp.img" "$@"
