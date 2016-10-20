; Copyright (c) 2016, Schnusch
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
;     1. Redistributions of source code must retain the above copyright notice,
;     this list of conditions and the following disclaimer.
;
;     2. Redistributions in binary form must reproduce the above copyright
;     notice, this list of conditions and the following disclaimer in the
;     documentation and/or other materials provided with the distribution.
;
;     3. Neither the name of the copyright holder nor the names of its
;     contributors may be used to endorse or promote products derived from this
;     software without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
; POSSIBILITY OF SUCH DAMAGE.

%include "macro.asm"

%define BYTE_DONT_CARE '?'
%define MBR_ADDR  0x7a00
%define PART2_LBA (MBR_ADDR + 446 + 16 + 8)
%macro READ_MARK 2
	dw MBR_ADDR + (%1)
	dw %2
%endmacro
%macro READ_MBR 2
	mov ax, 0x0201 ; read, 1 sector
	mov cx, 0x0001 ; 1st cylinder, 1st sector
	mov dh, 0      ; 1st head
	mov bx, %1
	int 0x13
	jc %2
	cmp al, 1
	jne %2
%endmacro

org 0x7c00

	jmp init
	nop
jmp_end:

times 90 - ($ - $$) db BYTE_DONT_CARE

init_start:

dap:
	db 16, 0
	dw VBR_SIZE / 512 - 1 ; number of sectors
	dw sector2            ; destination offset
	dw 0                  ; destination segment
.lba:
	times 4 db BYTE_DONT_CARE
	times 4 db 0

init:
	; move some code to another sector
	mov si, code_storage
	mov di, moved_code
	mov cx, (moved_code_end + 1 - moved_code) / 2
.mov_code:
	movsw
	loop .mov_code

	READ_MBR MBR_ADDR, error_mbr_read

	; init dap.lba
	mov ax, [PART2_LBA]
	inc ax
	mov [dap.lba], ax
	mov ax, [PART2_LBA + 2]
	jnc .write_lba2
	inc ax
.write_lba2:
	mov [dap.lba + 2], ax

	; read sectors
	mov ax, 0x4200
	mov si, dap
	int 0x13
	jnc sector2.jmp

error_vbr_read:
	mov al, 'V'
	mov [msg_error_read.v], al
error_mbr_read:
	CDECL print, msg_error_read
.loop:
	hlt
	jmp .loop

%ifdef DEBUG
msg_error_read: db "f2rd "
%else
msg_error_read: db "Failed to read "
%endif
.v:             db "MBR", 0x0d, 0x0a, 0

times ($ - $$) % 2 db BYTE_DONT_CARE
code_storage:
times 446 - ($ - $$) db BYTE_DONT_CARE

part_table:
.part1:
	READ_MARK 446 + 32, 8
	times 12 db BYTE_DONT_CARE
.part2:
	READ_MARK 446 + 16, 8
	times 12 db BYTE_DONT_CARE
.part3:
	READ_MARK 446 +  0, 8
	times 12 db BYTE_DONT_CARE
.part4:
	READ_MARK 446 + 48, 8 + 1
	times 12 db BYTE_DONT_CARE
db 0x55, 0xaa

; ======================= SECTOR 2 ======================= ;

sector2:
	READ_MARK 0, 0
.jmp:
%ifdef DEBUG
	CDECL print_hex, 0x7c00, 512
	CDECL print_hex, 0x7e00, 512
	CDECL print_hex, 0x8000, 512
	CDECL print_hex, 0x8200, 512
%endif

	CDECL print, msg_sector2
	CDECL print_partition_table, MBR_ADDR + 446

	; move MBR to 0x7c00
	mov di, 0x7c00
	mov si, MBR_ADDR
	mov cx, 446 / 2
	; move cx words
.mov_mbr:
	movsw
	loop .mov_mbr
	; repeat if read mark with len != 0
	mov si, [di]
	mov cx, [di + 2]
	test cx, cx
	jnz .mov_mbr

	CDECL print, msg_swapped
	CDECL print_partition_table, 0x7c00 + 446

	CDECL print, msg_write
	; write MBR back
	mov ax, 0x0301 ; write, 1 sector
	mov cx, 0x0001 ; 1st cylinder, 1st sector
	mov dh, 0      ; 1st head
	mov bx, 0x7c00
	int 0x13
	jc error_mbr_write
	cmp al, 1
	jne error_mbr_write

	CDECL print, msg_success
wait_keypress:
	mov ax, 0
	int 0x16
	jmp 0x7c00

error_mbr_write:
	CDECL print, msg_error_write
	CDECL print, msg_keypress
	jmp wait_keypress

print_partition_table:
	push bp
	mov bp, sp
	push ax
	push cx

	mov ax, [bp + 4]
	mov cx, 4
.loop:
	push ax ; save ax and pass to print_partition

	mov ax, 0x0e35
	sub al, cl
	int 0x10
	mov al, ':'
	int 0x10
	mov al, ' '
	int 0x10

	call print_partition
	pop ax
	add ax, 16
	loop .loop

	pop cx
	pop ax
	pop bp
	ret

msg_sector2:     db "Extended boot code from the second sector of partition #2 loaded.", 0x0d, 0x0a, 0x0d, 0x0a, "Current partition table:", 0x0d, 0x0a, 0
msg_swapped:     db "Swapped partition table:", 0x0d, 0x0a, 0
msg_write:       db 0x0d, 0x0a, "Writing modified MBR back to disk...", 0x0d, 0x0a, 0
msg_success:     db "MBR written, partitions swapped successfully." ; not terminated so that msg_keypress will also be printed
msg_keypress:    db 0x0d, 0x0a, 0x0d, 0x0a, "Press any key to chainload the MBR or reboot manually...", 0
msg_error_write: db "Failed to write MBR, old partition table is still valid.", 0

times VBR_SIZE - ($ - $$) db 0

moved_code:
%include "print.asm"
moved_code_end:

dw jmp_end - 0x7c00
dw code_storage - 0x7c00
dw part_table   - code_storage
