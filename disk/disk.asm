[BITS 16]
[CPU 386]
%define DISK_IMPLEMENTATION
%include "./print/print.asmh"
%include "./disk/disk.asmh"
%include "global_define.asmh"

%define FAT32 0x0B
%define FAT32LBA 0x0C
%define HIDFAT32 0x1B
%define HIDFAT32LBA 0x1C

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
    mov ax, START_SEGMENT
    mov ds, ax
    ;Indeks dsku z którego wczytujemy dane
    mov dl, byte [DiskIntex]
    mov ah, 0x42


    ;Przekazanie adresu na struktóre z parametrami do wczytania
    push ss
    pop ds

    mov si, bp
    sub si, DAP_st.structSize
    int 0x13
    pop ds
    pop ebx
    pop dx
    add sp, DAP_st.structSize
    leave
    ret
    %pop

global FunDiskFindMBR
FunDiskFindMBR:
    %push
	%stacksize large
	%arg segAddress:word, offsetAddress:word

    push    bp
    mov     bp, sp

	push bx
    push ds

	mov ds, word [segAddress]
	mov bx, word [offsetAddress]

    lea bx, [bx + Mbr.Part1]
    mov ax, bx
    add ax, 0x40
    .loop:
    cmp byte [bx + MbrPart.PartType], FAT32
        je .FoundFAT32
    cmp byte [bx + MbrPart.PartType], FAT32LBA
        je .FoundFAT32
    cmp byte [bx + MbrPart.PartType], HIDFAT32
        je .FoundFAT32
    cmp byte [bx + MbrPart.PartType], HIDFAT32LBA
        je .FoundFAT32
    add bx, 0x10
    cmp bx, ax
        je .NotFoundFAT32
    jmp .loop
    .NotFoundFAT32:
    xor bx, bx
    .FoundFAT32:
    mov ax, bx

    pop ds
    pop bx
	leave
	ret
	%pop



global DiskIntex
DiskIntex: db 0x00
