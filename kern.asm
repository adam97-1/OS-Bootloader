mov ax, 0x1000
mov ds, ax

mov si, MsgKernAB
mov cx, word [SizeMsgKernAB]
mov ah, 0x0E
.loop:
    lodsb
    int 0x10
    loop .loop
jmp $
jmp $

MsgKernAB: db "Hello form Kern.AB file."
SizeMsgKernAB: dw $ - MsgKernAB


times 16384-($-$$) db 0xCC
