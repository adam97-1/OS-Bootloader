[BITS 16]
%include "string.asmh"

FunStringCmp:
    %push
    %stacksize large
    %arg segString1:word, offsetString1:word, segString2:word, offsetString2:word
    %assign %$localsize 0

    enter   %$localsize, 0

    pusha
    push    ds
    push    es

    stringLen [segString1], [offsetString1]
    mov     bx, ax
    stringLen [segString2], [offsetString2]
    cmp     ax, bx
        jne end_NoEqual

    mov     ax, [segString2]
    mov     es, ax
    mov     ax, [offsetString2]
    mov     di, ax

    cld
    repe    cmpsb

    end_NoEqual:
    mov     ax, 1
    cmp     ax, 0
    end_Equal:

    pop es
    pop ds
    popa

    leave
    ret
    %pop

FunStringLen:
    %push
    %stacksize large
    %arg segString:word, offsetString:word
    %assign %$localsize 0

    enter   %$localsize, 0

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

FunStringtoUpper:
    %push
    %stacksize large
    %arg segString:word, offsetString:word
    %assign %$localsize 0

    enter   %$localsize, 0

    pusha
    push ds


    mov ax, [segString]
    mov ds, ax
    mov ax, [offsetString]
    mov si, ax

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
    mov     al, byte [ds:si]
    sub al, 0x20
    mov     byte [ds:si], al
    jmp .loop
    .end:

    pop ds
    popa

    leave
    ret
    %pop
