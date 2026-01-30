[BITS 16]
[CPU 386]
%define PRINT_IMPLEMENTATION

%include "./print/print.asmh"
%include "./string/string.asmh"

global FunPrintString
FunPrintString:
	%push
	%stacksize large
	%arg segString:word, offsetString:word

    push    bp
    mov     bp, sp

    pusha
    push ds

    stringLen word [segString], word [offsetString]
	mov cx, ax

	cmp cx, 0x00
		je .break
	mov ah, 0x0E
	push word [segString]
	pop ds
	mov si, word [offsetString]
	cld
	.loop:
		lodsb
		int 0x10
		loop .loop
	.break:
	pop ds
	popa
	leave
	ret
	%pop

global FunPrintChar
FunPrintChar:
	%push
	%stacksize large
	%arg char:byte

	push    bp
    mov     bp, sp

	push ax

	mov ah, 0x0E
	mov al, byte [char]
	int 0x10

	pop ax
	leave
	ret
	%pop

_FunPrintHexFromBcd:
	mov ah, 0x0E
	cmp al, 0x0A
	jae .l
	add al, '0'
	jmp .print

	.l:
	add al, 0x37
	.print:
	int 0x10
	ret

_FunPrintByteHex:
	mov al, cl
	shr al, 0x04
	call _FunPrintHexFromBcd
	mov al, cl
	and al, 0x0F
	call _FunPrintHexFromBcd
	ret

global FunPrintByteHex
FunPrintByteHex:
	%push
	%stacksize large
	%arg num:word

	push    bp
    mov     bp, sp

	pusha

	printChar '0'
	printChar 'x'

	mov cx, word [num]
	call _FunPrintByteHex

	popa
	leave
	ret
	%pop


_FunPrintWordHex:
	xchg ch, cl
	call _FunPrintByteHex
	xchg ch, cl
	call _FunPrintByteHex
	ret

global FunPrintWordHex
FunPrintWordHex:
	%push
	%stacksize large
	%arg num:word

	push    bp
    mov     bp, sp

	pusha

	printChar '0'
	printChar 'x'

	mov cx, word [num]
	call _FunPrintWordHex

	popa
	leave
	ret
	%pop

global FunPrintDWordHex
FunPrintDWordHex:
	%push
	%stacksize large
	%arg num:dword

	push    bp
    mov     bp, sp

	pusha
	printChar '0'
	printChar 'x'

	mov ecx, dword [num]
	call _FunPrintWordHex
	ror ecx, 0x10
	call _FunPrintWordHex

	popa
	leave
	ret
	%pop
