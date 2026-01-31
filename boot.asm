[BITS 16]
[CPU 386]
%include "./global_define.asmh"

;Ustawienie DS segmentu na początek kodu w RAM
cli
push BOOT_SEGMENT_RAM
pop ds
sti

mov byte [DiskIndexBoot], dl
;Obliczanie długości bootloadera w sektorach AL=SectorPerBootlader
xor dx, dx
xor cx, cx
mov ax, word [444]
mov bx, SIZE_SECTOR
div bx
cmp dx, 0x00
setnz cl
add al, cl

; Wczytanie programu do RAM pod adres 0x0500
mov ah, 0x02                    ;Polecenie wczytania sektorów (CHS)
mov ch, 0x00                    ;Cylinder z którego wycztujemy dane
mov cl, 0x02                    ;Sektor z którego wczytujemy dame
mov dh, 0x00                    ;Indeks głowicy z którego wczytujemy dane
mov dl, byte [DiskIndexBoot]    ;Indeks dsku z którego wczytujemy dane
mov bx, 0x00                    ;Offset pod który wczytujemy dane
push START_SEGMENT              ;Segment pod który wcztujemy dane
pop es
int 13h
    jc PrintErrLoadBootloader

mov dl, byte [DiskIndexBoot]
mov ax, START_SEGMENT
mov ds, ax
jmp START_SEGMENT:0x00

PrintErrLoadBootloader:
;Wyświetlenie komunikatu o błędzie wczytania danych z dysku
mov si, MsgErrLoadBootloader
mov cx, word [SizeMsgErrLoadBootloader]
mov ah, 0x0E
.loop:
    lodsb
    int 0x10
    loop .loop
jmp $


DiskIndexBoot: db 0x00
MsgErrLoadBootloader: db "Load bootloader error"
SizeMsgErrLoadBootloader: dw $ - MsgErrLoadBootloader

times 512-($-$$) db 0xAA

