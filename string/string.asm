[BITS 16]
[CPU 386]
%define STRING_IMPLEMENTATION
%include "./string/string.asmh"

global FunStringCmp
FunStringCmp:
    %push
    %stacksize large
    %arg segString1:word, offsetString1:word, segString2:word, offsetString2:word

    push    bp
    mov     bp, sp

    push    cx
    push    si
    push    di
    push    bx
    push    ds
    push    es

    stringLen [segString1], [offsetString1]
    mov     bx, ax
    stringLen [segString2], [offsetString2]
    cmp     ax, bx
        jne .noEqual

    mov     cx, ax
    mov     ds, [segString1]
    mov     si, [offsetString1]
    mov     es, [segString2]
    mov     di, [offsetString2]


    cld
    repe cmpsb
        je .equal

    .noEqual:
    mov     ax, 0
    jmp .end
    .equal:
    mov     ax, 1
    jmp .end
    .end:
    pop es
    pop ds
    pop bx
    pop di
    pop si
    pop cx

    leave
    ret
    %pop

global FunStringLen
FunStringLen:
    %push
    %stacksize large
    %arg segString:word, offsetString:word

    push    bp
    mov     bp, sp

    push    cx
    push    si
    push    ds


    xor     cx, cx
    mov ax, [segString]
    mov ds, ax
    mov ax, [offsetString]
    mov si, ax

    .loop:
    cmp     byte [ds:si], 0x00
        je .break
    inc     cx
    inc     si
    jmp .loop
    .break:
    mov     ax, cx

    pop ds
    pop si
    pop cx

    leave
    ret
    %pop

global FunStringtoUpper
FunStringtoUpper:
    %push
    %stacksize large
    %arg segString:word, offsetString:word

    push    bp
    mov     bp, sp

    pusha
    push ds


    mov ds, [segString]
    mov si, [offsetString]
    jmp .skip
    .loop:
    inc     si
    .skip:
    cmp     byte [ds:si], 0x00
        je .end
    cmp     byte [ds:si], 0x60
        jbe .loop
    cmp     byte [ds:si], 0x7B
        jae .loop
    mov al, byte [ds:si]
    sub al, 0x20
    mov     byte [ds:si], al
    jmp .loop
    .end:

    pop ds
    popa

    leave
    ret
    %pop
