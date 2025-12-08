%macro print 2
    pusha
    mov si, %1
    mov cx, %2
    call PrintString
    popa
%endmacro

%macro print 1
    pusha
    mov si, %1
    stringLen si
    mov cx, ax
    call PrintString
    popa
%endmacro

%macro printByteHex 1
    pusha
    mov cl, %1
    call PRINT_BX
    popa
%endmacro

%macro printWordHex 1
    pusha
    mov cx, %1
    call PRINT_WX
    popa
%endmacro

%macro printDWordHex 1
    pusha
    mov ecx, %1
    call PRINT_DX
    popa
%endmacro


%macro newLine 0
    pusha
    mov al, 0x0A
    call PutChar

    mov al, 0x0D
    call PutChar
    popa
%endmacro

%macro printLn 2
    print %1, %2
    newLine
%endmacro

%macro printLn 1
    print %1
    newLine
%endmacro

%macro printByteHexLn 1
    printByteHex %1
    newLine
%endmacro

%macro printWordHexLn 1
    printWordHex %1
    newLine
%endmacro

%macro printDWordHexLn 1
    printByteDWordHex %1
    newLine
%endmacro


PrintString:
	cmp cx, 0x00
		je .break
	mov ah, 0x0E
	.loop:
		lodsb
		int 0x10
		loop .loop
	.break:
	ret

PutChar:
	push ax
	mov ah, 0x0E
	int 0x10
	pop ax
	ret

PRINT_X:
	cmp al, 0x0A
	jae .l
	add al, '0'
	jmp .print

	.l:
	add al, 0x37
	.print:
	int 0x10
	ret

_PRINT_BX:
	mov al, cl
	shr al, 0x04
	call PRINT_X
	mov al, cl
	and al, 0x0F
	call PRINT_X
	ret

PRINT_BX:
	push ax
	mov ax, 0x0E30
	int 0x10
	mov al, 'x'
	int 0x10
	call _PRINT_BX
	pop ax
	ret

_PRINT_WX:
	xchg ch, cl
	call _PRINT_BX
	xchg ch, cl
	call _PRINT_BX
	ret

PRINT_WX:
	push ax
	mov ax, 0x0E30
	int 0x10
	mov al, 'x'
	int 0x10
	call _PRINT_WX
	pop ax
	ret

PRINT_DX:
	push ax
	mov ax, 0x0E30
	int 0x10
	mov al, 'x'
	int 0x10
	ror ecx, 0x10
	call _PRINT_WX
	ror ecx, 0x10
	call _PRINT_WX
	pop ax
	ret
