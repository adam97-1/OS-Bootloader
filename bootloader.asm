%define FAT_SEGMENT 0x1050

%define FAT32 0x0B
%define FAT32LBA 0x0C
%define HIDFAT32 0x1B
%define HIDFAT32LBA 0x1C
%define SizeDiskSector 0x200

Bootloader:
;Kimunikat o wczytaniu bootloadera do RAM
mov byte [DiskIntex], dl
printLn MsgLoadBootloader, word [SizeMsgLoadBootloader]


FindFAT32InMBR Mbr
cmp ax, 0x00
    je PrintErrFindFAT32
jmp LoadPartiction

;Wypisanie komunikatu o braku partycji typu FAT32
PrintErrFindFAT32:
    print MsgErrFindFAT32, word [SizeMsgErrFindFAT32]
    jmp $

;Wczytanie pierwszego sektoru partycji FAT32
LoadPartiction:
;Wyświetlenie komunikatu o wczytaniu pierwszego sektora partycji FAT32
printLn MsgLoadPart, word [SizeMsgLoadPart]

;Kopia danych o partycji FAT32
cld
mov cx, 16
push ds
pop es
mov si, ax
mov di, PartFat32StartAddress
rep movsb
;Wczytanie pierwszego sektora partcji FAT32
loadLBASectors FAT_SEGMENT, 0x0000, dword [PartFat32StartAddress + MbrPart.FirstLbaSect], 1

;Przypiasnie segmetu GS do danych w partychi FAT32
push FAT_SEGMENT
pop gs

;Wyświetlenie inforamcji pomocniczych
newLine
print MsgBytePerSector, word [SizeMsgBytePerSector]
printWordHexLn word [gs:Fat.BytePerSector]

print MsgSectorPerCluster, word [SizeMsgSectorPerCluster]
printByteHexLn gs:Fat.SectorPerCluster

print MsgReservedSectors, word [SizeMsgReservedSectors]
printWordHexLn word [gs:Fat.ReservedSectors]

print MsgSectorPerFat32, word [SizeMsgSectorPerFat32]
printWordHexLn word [gs:Fat.SectorPerFat32]

print MsgClusterRootDir, word [SizeMsgClusterRootDir]
printWordHexLn word [gs:Fat.ClusterRootDir]

;Obliczenie ile sektorów dysku przypada na sektor partycji
xor eax, eax
mov ax, word [gs:Fat.BytePerSector]
mov ebx, SizeDiskSector
div ebx
mov byte [PartMetaData.DiskSectorPerPartSector], al

;Wyświetlenie ile sektorów dysku przypada na sektor partycji
print MsgDiskSectorPerPartSector, word [SizeMsgDiskSectorPerPartSector]
printByteHexLn [PartMetaData.DiskSectorPerPartSector]

;Obliczenie w którm sektorze znajduje się Root Directory
mov eax, dword [gs:Fat.SectorPerFat32]
mov ebx, 0x02
mul ebx
xor ebx, ebx
mov bx,  word [gs:Fat.ReservedSectors]
add eax, ebx
xor ebx, ebx
mov bl, byte [PartMetaData.DiskSectorPerPartSector]
mul ebx

add eax, dword [PartFat32StartAddress + MbrPart.FirstLbaSect]
mov dword [PartMetaData.RootDirSector], eax

;Wyświetlenie w którm sektorze znajduje się Root Directory
print MsgRootDirSector, word [SizeMsgRootDirSector]
printWordHexLn word [PartMetaData.RootDirSector]

;Obliczenie ile przpada sektorów dysku na cluster w partycji
xor bx, bx
mov ax, word [gs:Fat.BytePerSector]
mov bl, byte [gs:Fat.SectorPerCluster]
mul bx
xor bx, bx
mov bl, byte [PartMetaData.DiskSectorPerPartSector]
mul bx

xor bx, bx
mov bx, SizeDiskSector
div bx
mov word [PartMetaData.ClusterSizeInSector], ax

;Wyświetlenie ile przpada sektorów dysku na cluster w partycji
print MsgClusterSize, word [SizeMsgClusterSize]
printWordHexLn word [PartMetaData.ClusterSizeInSector]

;Wczytanie Root Directory
loadLBASectors FAT_SEGMENT, 0x0000, dword [PartMetaData.RootDirSector], 1

;Wyświetlenie folderów w Root Directory
newLine
printLn MsgFoldersFilesRootDir, word [SizeMsgFoldersFilesRootDir]
Fat32PrintFoldersAndFiles gs, 0x00

jmp $


MsgErrFindFAT32: db "Not found FAT32 partitions."
SizeMsgErrFindFAT32: dw $ - MsgErrFindFAT32

MsgLoadBootloader: db "Loaded Bootloader."
SizeMsgLoadBootloader: dw $ - MsgLoadBootloader

MsgLoadPart: db "Loaded first serctor of FAT32."
SizeMsgLoadPart: dw $ - MsgLoadPart

MsgBytePerSector: db "Fat.BytePerSector: "
SizeMsgBytePerSector: dw $ - MsgBytePerSector

MsgSectorPerFat32: db "Fat.SectorPerFat32: "
SizeMsgSectorPerFat32: dw $ - MsgSectorPerFat32

MsgReservedSectors: db "Fat.ReservedSectors: "
SizeMsgReservedSectors: dw $ - MsgReservedSectors

MsgSectorPerCluster: db "Fat.SectorPerCluster: "
SizeMsgSectorPerCluster: dw $ - MsgSectorPerCluster

MsgClusterRootDir: db "Fat.ClusterRootDir: "
SizeMsgClusterRootDir: dw $ - MsgClusterRootDir

MsgDiskSectorPerPartSector: db "DiskSectorPerPartSector: "
SizeMsgDiskSectorPerPartSector: dw $ - MsgDiskSectorPerPartSector

MsgRootDirSector: db "RootDirSector: "
SizeMsgRootDirSector: dw $ - MsgRootDirSector

MsgClusterSize: db "ClusterSize: "
SizeMsgClusterSize: dw $ - MsgClusterSize

MsgFoldersFilesRootDir: db "Folders or files in root directory: "
SizeMsgFoldersFilesRootDir: dw $ - MsgFoldersFilesRootDir
