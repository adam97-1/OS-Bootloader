%include "disk.asmh"

;Args: segment, offset, sector, count
FunLoadLBASectors:
    %push
    %stacksize large
    %arg segmentDest:word, offsetDest:word, sector:qword, count:dword
    %assign %$localsize 0
    %define DAP bp+1

    push bp
    mov bp, sp
    sub sp, ss:DAP_st.structSize

    pusha
    push ds
    mov si, ss:DAP + DAP_st.address
    mov ebx, dword [sector]
    mov dword [ss:si], ebx
    mov ebx, dword [sector+4]
    mov dword [ss:si+4], ebx

    mov si, ss:DAP + DAP_st.count
    mov bx, [count]
    mov word [ss:si], bx

    mov si, ss:DAP + DAP_st.offset
    mov bx, [offsetDest]
    mov word [ss:si], bx

    mov si, ss:DAP + DAP_st.segment
    mov bx, [segmentDest]
    mov word [ss:si], bx



    ;Polecenie wczytania sektorów (LBA)
    mov ah, 0x42
    ;Indeks dsku z którego wczytujemy dane
    mov dl, 0x80

    ;Przekazanie adresu na struktóre z parametrami do wczytania
    push ss
    pop ds
    mov si, bp
    inc si
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


struc DAP_st
    .size resb 1
    .null resb 1
    .count resd 1
    .offset resd 1
    .segment resd 1
    .address resq 1
    .structSize resb 0

endstruc

DiskIntex: db 0x00
