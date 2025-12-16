;Args: segment, offset, sector, count
%macro loadLBASectors 4
    pusha
    mov si, DAP.address
    mov ebx, %3
    mov dword [si], ebx

    mov si, DAP.count
    mov bx, %4
    mov word [si], bx

    mov si, DAP.offset
    mov bx, %2
    mov word [si], bx

    mov si, DAP.segment
    mov bx, %1
    mov word [DAP.segment], bx



    ;Polecenie wczytania sektorów (LBA)
    mov ah, 0x42
    ;Indeks dsku z którego wczytujemy dane
    mov dl, 0x80

    ;Przekazanie adresu na struktóre z parametrami do wczytania
    mov si, DAP
    int 0x13
        jc PrintErrBootSector
    popa
%endmacro

PrintErrBootSector:
;Wyświetlenie komunikatu o błędzie wczytania danych z dysku
print MsgErrLoadSector, word [SizeMsgErrLoadSector]
;Wyświetlenie kodu błedu
printByteHex ds, ah
jmp $

MsgErrLoadSector: db "Load Sector Error: "
SizeMsgErrLoadSector: dw $ - MsgErrLoadSector

DAP:
    .size: db 0x10
    .null: db 0x00
    .count: dw 0x0001
    .offset: dw 0x0000
    .segment: dw 0x0000
    .address: dq 0x0000000000000000

DiskIntex: db 0x00
