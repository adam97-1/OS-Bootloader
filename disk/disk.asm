[BITS 16]
%define DISK_IMPLEMENTATION
%include "./disk/disk.asmh"

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
    mov dl, DiskIntex
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

global FunDiskGetDiskIntex
FunDiskGetDiskIntex:
    push ds

    mov ax, START_SEGMENT
    mov ds, ax

    mov al, DiskIntex

    pop ds
    ret

global FunDiskSetDiskIntex
FunDiskSetDiskIntex:
    %push
    %stacksize large
    %arg diskIndexArg:byte

    push bp
    mov bp, sp

    push ds
    push ax

    mov ax, START_SEGMENT
    mov ds, ax

    move al, byte [diskIndexArg]
    mov byte [DiskIntex], al

    pop ax
    pop ds
    leave
    ret

DiskIntex: db 0x00
