[BITS 16]
[CPU 386]

%include "./global_define.asmh"
%include "./fat32/fat32.asmh"
%include "./print/print.asmh"
%include "./string/string.asmh"
%include "./disk/disk.asmh"

section .code
global start
start:
;Komunikat o wczytaniu bootloadera do RAM
printStringLn START_SEGMENT, MsgLoadBootloader

mov byte [DiskIntex], dl

;Szuka partycji FAR32 w MBR
DiskFindMBR BOOT_SEGMENT_RAM, Mbr
cmp ax, 0x00
    je PrintErrFindFAT32
jmp LoadPartiction

;Wypisanie komunikatu o braku partycji typu FAT32
PrintErrFindFAT32:
    printString START_SEGMENT, MsgErrFindFAT32
    jmp $

;Wczytanie pierwszego sektoru partycji FAT32
LoadPartiction:
;Wyświetlenie komunikatu o wczytaniu pierwszego sektora partycji FAT32
printStringLn START_SEGMENT, MsgLoadPart

;Kopia danych o partycji FAT32
cld
mov cx, 16
push BOOT_SEGMENT_RAM
pop ds
push START_SEGMENT
pop es
mov si, ax
mov di, Fat32PartStartAddress
rep movsb
push START_SEGMENT
pop ds
push BOOT_SEGMENT_RAM
pop es

;Wczytanie pierwszego sektora partcji FAT32
diskLoadLBASectors FAT_SEGMENT, 0x0000, dword 0x0000, dword [Fat32PartStartAddress + MbrPart.FirstLbaSect], 0x0001
cmp ah, 0x00
    jne .PrintErrBootSector
jmp .AnalysisPartition

.PrintErrBootSector:
; Wyświetlenie komunikatu o błędzie wczytania danych z dysku
printString START_SEGMENT, MsgErrLoadSector
;Wyświetlenie kodu błedu
mov al, ah
xor ah, ah
printByteHexLn ax
jmp $

.AnalysisPartition:
;Przypiasnie segmetu GS do danych w partychi FAT32
mov ax, FAT_SEGMENT
mov gs, ax

;Wyświetlenie inforamcji pomocniczych
newLine
printString START_SEGMENT, MsgBytePerSector
printWordHexLn word [gs:Fat.BytePerSector]

printString START_SEGMENT, MsgSectorPerCluster
xor ax, ax
mov al, byte [gs:Fat.SectorPerCluster]
printByteHexLn ax

printString START_SEGMENT, MsgReservedSectors
printWordHexLn word [gs:Fat.ReservedSectors]

printString START_SEGMENT, MsgSectorPerFat32
printWordHexLn word [gs:Fat.SectorPerFat32]

printString START_SEGMENT, MsgClusterRootDir
printWordHexLn word [gs:Fat.ClusterRootDir]

;Obliczenie ile sektorów dysku przypada na sektor partycji
xor eax, eax
xor edx, edx
mov ax, word [gs:Fat.BytePerSector]
mov ebx, SizeDiskSector
div ebx
mov byte [Fat32PartMetaDataAddress +  Fat32PartMetaData.DiskSectorPerPartSector], al

;Wyświetlenie ile sektorów dysku przypada na sektor partycji
printString START_SEGMENT, MsgDiskSectorPerPartSector
xor ax, ax
mov al, byte [ds:Fat32PartMetaDataAddress + Fat32PartMetaData.DiskSectorPerPartSector]
printByteHexLn ax

;Obliczenie w którm sektorze znajduje się Root Directory
mov eax, dword [gs:Fat.SectorPerFat32]
mov ebx, 0x02
mul ebx
xor ebx, ebx
mov bx,  word [gs:Fat.ReservedSectors]
add eax, ebx
xor ebx, ebx
mov bl, byte [Fat32PartMetaDataAddress + Fat32PartMetaData.DiskSectorPerPartSector]
mul ebx

add eax, dword [Fat32PartStartAddress + MbrPart.FirstLbaSect]
mov dword [Fat32PartMetaDataAddress + Fat32PartMetaData.RootDirSector], eax

;Wyświetlenie w którm sektorze znajduje się Root Directory
printString START_SEGMENT, MsgRootDirSector
printDWordHexLn dword [ds:Fat32PartMetaDataAddress + Fat32PartMetaData.RootDirSector]


;Obliczenie ile przpada sektorów dysku na cluster w partycji
xor bx, bx
mov ax, word [gs:Fat.BytePerSector]
mov bl, byte [gs:Fat.SectorPerCluster]
mul bx
xor bx, bx
mov bl, byte [Fat32PartMetaDataAddress + Fat32PartMetaData.DiskSectorPerPartSector]
mul bx

xor bx, bx
mov bx, SizeDiskSector
div bx
mov word [Fat32PartMetaDataAddress + Fat32PartMetaData.ClusterSizeInSector], ax

;Wyświetlenie ile przpada sektorów dysku na cluster w partycji
printString START_SEGMENT, MsgClusterSize
printWordHexLn word [ds:Fat32PartMetaDataAddress + Fat32PartMetaData.ClusterSizeInSector]
Fat32CheckMaxFilesInCluster
printString START_SEGMENT, MsgMaxFilesInCluster
printWordHexLn dword [ds:Fat32PartMetaDataAddress + Fat32PartMetaData.MaxFilesInCluster]

;Wczytanie Root Directory
diskLoadLBASectors FAT_SEGMENT, 0x0000, dword 0x00000000, dword [Fat32PartMetaDataAddress + Fat32PartMetaData.RootDirSector], 1
cmp ah, 0x00
    jne .PrintErrBootSector

;Wyświetlenie folderów w Root Directory
newLine
printStringLn START_SEGMENT, MsgFoldersFilesRootDir

Fat32PrintFoldersAndFiles gs, 0x00

newLine
Fat32LoadFolderOrFile FAT_SEGMENT, 0x0000, FAT_SEGMENT, 0x0000, ds, NameUpperTest
jmp $


MsgErrLoadSector: db "Load Sector Error: ", 0x00

FolderNameTest: db " "
NameUpperTest: db "os/boot/kenr.ab", 0x00

MsgErrFindFAT32: db "Not found FAT32 partitions.", 0x00

MsgLoadBootloader: db "Loaded Bootloader.", 0x00

MsgLoadPart: db "Loaded first serctor of FAT32.", 0x00

MsgBytePerSector: db "Fat.BytePerSector: ", 0x00

MsgSectorPerFat32: db "Fat.SectorPerFat32: ", 0x00

MsgReservedSectors: db "Fat.ReservedSectors: ", 0x00

MsgSectorPerCluster: db "Fat.SectorPerCluster: ", 0x00

MsgClusterRootDir: db "Fat.ClusterRootDir: ", 0x00

MsgDiskSectorPerPartSector: db "DiskSectorPerPartSector: ", 0x00

MsgRootDirSector: db "RootDirSector: ", 0x00

MsgClusterSize: db "ClusterSize: ", 0x00

MsgFoldersFilesRootDir: db "Folders or files in root directory: ", 0x00

MsgMaxFilesInCluster: db "Max Files In Cluster: ", 0x00
