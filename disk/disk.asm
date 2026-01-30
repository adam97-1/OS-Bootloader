[BITS 16]
[CPU 386]
%define DISK_IMPLEMENTATION
%include "./print/print.asmh"
%include "./disk/disk.asmh"
%include "global_define.asmh"

;Args: segment, offset, sector, count
global FunDiskLoadLBASectors
FunDiskLoadLBASectors:
    %push
    %stacksize large
    %arg segmentDest:word, offsetDest:word, sector:qword, count:dword

    push bp
    mov bp, sp
    sub sp, DAP_st.structSize

    push ebx
    push dx
    push ds

    mov bl, 0x10
    mov byte [ss:bp - DAP_st.structSize + DAP_st.size], bl

    mov bl, 0x00
    mov byte [ss:bp - DAP_st.structSize + DAP_st.null], bl

    mov bx, word [count]
    mov word [ss:bp- DAP_st.structSize + DAP_st.count], bx

    mov bx, [offsetDest]
    mov word [ss:bp - DAP_st.structSize + DAP_st.buffer], bx

    mov bx, [segmentDest]
    mov word [ss:bp - DAP_st.structSize + DAP_st.buffer + 2], bx

    mov ebx, dword [sector + 4]
    mov dword [ss:bp - DAP_st.structSize + DAP_st.address], ebx
    mov ebx, dword [sector]
    mov dword [ss:bp - DAP_st.structSize + DAP_st.address + 4], ebx

    ;Polecenie wczytania sektorów (LBA)
        xchg bx, bx

    mov ax, START_SEGMENT
    mov ds, ax
    ;Indeks dsku z którego wczytujemy dane
    mov dl, 0x80
    mov ah, 0x42


    ;Przekazanie adresu na struktóre z parametrami do wczytania
    push ss
    pop ds

    mov si, bp
    sub si, DAP_st.structSize
    xchg bx, bx
    int 0x13
    pop ds
    pop ebx
    pop dx
    add sp, DAP_st.structSize
    leave
    ret
    %pop


global DiskIntex
DiskIntex: db 0x00
