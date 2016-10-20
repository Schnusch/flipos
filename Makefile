MV       ?= mv
TRUNCATE ?= truncate
YASM     ?= yasm
yflags   := -p nasm -r nasm -f bin -a x86 -m x86 -DDEBUG $(YFLAGS)

mbr.img: mbr_chainload_vbr.asm
	$(YASM) $(strip $(yflags)) -o "tmp.img" "$<"
	./copy-code.sh "tmp.img" 512
	$(TRUNCATE) -s512 "tmp.img"
	$(MV) "tmp.img" "$@"

clean:
	$(RM) *.img
