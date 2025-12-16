%define NULL 0x00

;Args: ds:StringAddressOffset, ds:String2AddressOffset
%macro StringCmp 2
    push ax
    push bx
    push cx
    push es
    stringLen %1
    mov bx, ax
    stringLen %2
    cmp ax, bx
        jne %%end

    mov cx, ax
    mov ax, ds
    mov es, ax

    mov si, %1
    mov di, %2

    call FunStringCmp
    jmp %%end_Equal

    %%end:
    pop es
    pop cx
    pop bx
    pop ax
%endmacro

;Args: segment1, StringAddressOffset, segment2, String2AddressOffset
%macro stringCmp 4
    push ax
    push bx
    push cx
    push ds
    push es
    stringLen %1, %2
    mov bx, ax
    stringLen %3, %4
    cmp ax, bx
        jne %%end_NoEqual

    mov cx, ax
    mov ax, %1
    mov ds, ax
    mov ax, %3
    mov es, ax

    mov si, %2
    mov di, %4

    call FunStringCmp
    jmp %%end_Equal

    %%end_NoEqual:
    mov ax, 1
    cmp ax, 0
    %%end_Equal:
    pop es
    pop ds
    pop cx
    pop bx
    pop ax
%endmacro

FunStringCmp:
    cld
    repe cmpsb
    ret

;Args: ds:StringAddressOffset
%macro stringLen 1
    push si
    mov si, %1
    call FunStringLen
    pop si
%endmacro

;Args: Segment, StringAddressOffset
%macro stringLen 2
    push ds
    push si
    mov ax, %1
    mov ds, ax
    mov si, %2
    call FunStringLen
    pop si
    pop ds
%endmacro

FunStringLen:
    xor cx, cx
    .loop:
    cmp byte [si], NULL
        je .break
    inc cx
    inc si
    jmp .loop
    .break:
    mov ax, cx
    ret

;Args: Segment, StringAddressOffset
%macro stringtoUpper 2
    pusha
    push ds

    push %1
    pop ds
    mov si, %2

    call FunStringtoUpper

    pop ds
    popa
%endmacro

FunStringtoUpper:
    jmp .skip
    .loop:
    inc si
    .skip:
    cmp byte [ds:si], 0x00
        je .end
    cmp  byte [ds:si], 0x60
        jbe .loop
    cmp  byte [ds:si], 0x7B
        jae .loop
    mov al, byte [ds:si]
    sub al, 0x20
    mov byte [ds:si], al
    jmp .loop
    .end:
    ret

