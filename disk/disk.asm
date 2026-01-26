[BITS 16]
[CPU 386]
%define DISK_IMPLEMENTATION
%include "./disk/disk.asmh"
%include "global_define.asmh"

;Args: segment, offset, sector, count
global FunDiskLoadLBASectors
FunDiskLoadLBASectors:
    %push
    %stacksize large
    %arg segmentDest:word, offsetDest:word, sector:qword, count:dword
    %define DAP 1

    push bp
    mov bp, sp
    sub sp, ss:DAP_st.structSize

    pusha
    push ds

    mov ebx, dword [sector]
    mov dword [ss:bp + DAP + DAP_st.address], ebx
    mov ebx, dword [sector+4]
    mov dword [ss:bp + DAP + DAP_st.address+4], ebx

    mov bx, [count]
    mov word [ss:bp + DAP + DAP_st.count], bx

    mov bx, [offsetDest]
    mov word [ss:bp + DAP + DAP_st.offset], bx

    mov bx, [segmentDest]
    mov word [ss:bp + DAP + DAP_st.segment], bx



    ;Polecenie wczytania sektorów (LBA)

    mov ax, 0x50
    mov ds, ax
    ;Indeks dsku z którego wczytujemy dane
    mov dl, byte [DiskIntex]
    mov ah, 0x42


    ;Przekazanie adresu na struktóre z parametrami do wczytania
    push ss
    pop ds

    mov si, bp
    add si, DAP
    int 0x13
        ; jc PrintErrBootSector
    .back:
    pop ds
    popa
    leave
    ret
    %pop

; PrintErrBootSector:
;Wyświetlenie komunikatu o błędzie wczytania danych z dysku
; print MsgErrLoadSector, word [SizeMsgErrLoadSector]
; ;Wyświetlenie kodu błedu
; printByteHex ds, ah
; jmp .back

; MsgErrLoadSector: db "Load Sector Error: "
; SizeMsgErrLoadSector: dw $ - MsgErrLoadSector
;

section .text
global DiskIntex
DiskIntex: db 0x00
