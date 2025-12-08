%define SIZE_SECTOR 0x200
%define FIRST_SEGMENT_RAM 0x50
%define BOOT_SEGMENT_RAM 0x07C0

;Ustawienie DS segmentu na początek kodu w RAM
cli
push BOOT_SEGMENT_RAM
pop ds
sti

mov byte [DiskIndexBoot], dl

;Obliczanie długości bootloadera w sektorach AL=SectorPerBootlader
xor dx, dx
mov ax, EndLoadStage2
sub ax, LoadStage2
mov bx, SIZE_SECTOR
div bx
cmp dx, 0x00
setnz cl
add al, cl



; Wczytanie programu do RAM pod adres 0x0500
mov ah, 0x02                    ;Polecenie wczytania sektorów (CHS)
inc al                          ;Wczytane obliczonej ilości sektorów oraz pierwszego sektora
mov ch, 0x00                    ;Cylinder z którego wycztujemy dane
mov cl, 0x01                    ;Sektor z którego wczytujemy dame
mov dh, 0x00                    ;Indeks głowicy z którego wczytujemy dane
mov dl, byte [DiskIndexBoot]    ;Indeks dsku z którego wczytujemy dane
mov bx, 0x00                    ;Offset pod który wczytujemy dane
push FIRST_SEGMENT_RAM          ;Segment pod który wcztujemy dane
pop es
int 13h

    jc PrintErrLoadBootloader
push FIRST_SEGMENT_RAM
pop ds
mov dl, byte [DiskIndexBoot]
jmp FIRST_SEGMENT_RAM:Bootloader

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

LoadStage2:
%include "string.asm"
%include "print.asm"
%include "loadData.asm"
%include "fat32.asm"

%include "bootloader.asm"
EndLoadStage2: db 0x00



times 4096-($-$$) db 0x55


