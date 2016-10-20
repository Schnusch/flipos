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
; POSSIBILITY OF SUCH DAMAGE. */

%macro CDECL 2
	push %2
	call %1
	add sp, 2
%endmacro
%macro CDECL 3
	push %3
	push %2
	call %1
	add sp, 4
%endmacro

%macro PRINT_SPACE 0
	mov ax, 0x0e20
	int 0x10
%endmacro

ax_to_hex:
	sar ah, 4
	and ax, 0x0f0f
	or ax, 0x3030
	cmp ah, 0x3a
	jl .nohex_hi
	add ah, 0x27
.nohex_hi:
	cmp al, 0x3a
	jl .nohex_lo
	add al, 0x27
.nohex_lo:
	ret

print_hex_ax:
	push ax
	mov al, ah
	call .byte
	pop ax
.lobyte:
	mov ah, al
.byte: ; 7f
	call ax_to_hex
	push ax
	mov al, ah
	call .nibble
	pop ax
.nibble: ; 89
	mov ah, 0x0e
	int 0x10
	ret

print_crlf:
	push ax
	mov ax, 0xe0d
	int 0x10
	mov al, 0xa
	int 0x10
	pop ax
	ret

%ifdef DEBUG
print_hex:
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	mov bx, [bp + 4]
	mov cx, [bp + 6]
	mov dx, 0

.loop:
	mov ax, [bx]
	xchg ah, al ; little endian -> big endian
	call print_hex_ax
	add bx, 2
	sub cx, 2

	inc dx
	test dx, 16
	jnz .newline
	; print space
	mov ax, 0x0e20
	jmp .loop_cond
.newline:
	; print newline
	mov dx, 0
	mov ax, 0x0e0d
	int 0x10
	mov al, 0x0a
.loop_cond:
	int 0x10
	test cx, cx
	jne .loop

	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret
%endif

print:
	push bp
	mov bp, sp
	push ax
	push bx
	mov bx, [bp + 4]
	mov ah, 0x0e

.loop:
	mov al, [bx]
	test al, al
	je .break
	int 0x10
	inc bx
	jmp .loop

.break:
	pop bx
	pop ax
	pop bp
	ret
