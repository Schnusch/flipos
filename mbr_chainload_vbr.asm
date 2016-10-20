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

org 0x7c00

	mov si, code_storage
	mov di, moved_code
	mov cx, (moved_code_end + 1 - moved_code) / 2
mov_loop:
	movsw
	loop mov_loop
	jmp moved_code

%ifdef DEBUG
pre_code:
	push msg_success
	call ax
	add sp, 2
	times ($ - $$) % 2 nop
.end:
%endif

times ($ - $$) % 2 db 0
code_storage:
times 446 - ($ - $$) db 0

part_table:
times 16 db 0x11
part2:
times 8 db 0
.lba:
dw 1
times 6 db 0
times 16 db 0x33
times 16 db 0x44
db 0x55, 0xaa

moved_code:
%ifdef DEBUG
	; move message before 0x7c00
	mov si, pre_code
	mov di, 0x7c00 - (pre_code.end - pre_code)
	mov cx, (pre_code.end - pre_code + 1) / 2
.move_pre_code:
	movsw
	loop .move_pre_code
%endif

	CDECL print, msg_motd

	; find VBR
	mov si, part2.lba
	mov di, dap.lba
	movsw
	movsw

	; read VBR
	mov ax, 0x4200
	mov si, dap
	int 0x13
%ifdef DEBUG
	pushf

	; dump VBR
	CDECL print_hex, 0x7c00, 512

	; jump to message on successful read
	popf
	mov ax, print
	jnc 0x7c00 - (pre_code.end - pre_code)
%else
	jnc 0x7c00
%endif

	CDECL print, msg_vbr_error
.end:
	hlt
	jmp .end

%include "print.asm"

%ifdef DEBUG
msg_motd:      db "Code moved to 0x7e00, loading partition 2's VBR...", 0x0d, 0x0a, 0
msg_success:   db "VBR loaded jumping to 0x7c00", 0x0d, 0x0a, 0
%else
msg_motd:      db "Chainloading 2nd VBR...", 0x0d, 0x0a, 0
%endif
msg_vbr_error: db "Failed to read VBR",      0x0d, 0x0a, 0

dap:
	db 16, 0
	dw 1      ; 1 sector
	dw 0x7c00 ; destination offset
	dw 0      ; destination segment
.lba:
	times 4 db 0xff
	times 4 db 0

moved_code_end:

dw code_storage - 0x7c00
dw part_table   - code_storage
