%define FAT_SEGMENT 0x1050

%define FAT32 0x0B
%define FAT32LBA 0x0C
%define HIDFAT32 0x1B
%define HIDFAT32LBA 0x1C
%define SizeDiskSector 0x200

Bootloader:
;Kimunikat o wczytaniu bootloadera do RAM
push ds
push START_SECTOR
pop ds
mov byte [DiskIntex], dl
pop ds
printLn START_SECTOR, MsgLoadBootloader


FindFAT32InMBR Mbr
cmp ax, 0x00
    je PrintErrFindFAT32
jmp LoadPartiction

;Wypisanie komunikatu o braku partycji typu FAT32
PrintErrFindFAT32:
    print START_SECTOR, MsgErrFindFAT32
    jmp $

;Wczytanie pierwszego sektoru partycji FAT32
LoadPartiction:
;Wyświetlenie komunikatu o wczytaniu pierwszego sektora partycji FAT32
printLn START_SECTOR, MsgLoadPart

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
print START_SECTOR, MsgBytePerSector
printWordHexLn gs, word [Fat.BytePerSector]

print START_SECTOR, MsgSectorPerCluster
printByteHexLn gs, byte [Fat.SectorPerCluster]

print START_SECTOR, MsgReservedSectors
printWordHexLn gs, word [Fat.ReservedSectors]

print START_SECTOR, MsgSectorPerFat32
printWordHexLn gs, word [Fat.SectorPerFat32]

print START_SECTOR, MsgClusterRootDir
printWordHexLn gs, word [Fat.ClusterRootDir]

;Obliczenie ile sektorów dysku przypada na sektor partycji
xor eax, eax
xor edx, edx
mov ax, word [gs:Fat.BytePerSector]
mov ebx, SizeDiskSector
div ebx
mov byte [PartMetaData.DiskSectorPerPartSector], al

;Wyświetlenie ile sektorów dysku przypada na sektor partycji
print START_SECTOR, MsgDiskSectorPerPartSector
printByteHexLn START_SECTOR, byte [PartMetaData.DiskSectorPerPartSector]

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
print START_SECTOR, MsgRootDirSector
printWordHexLn START_SECTOR, word [PartMetaData.RootDirSector]


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
print START_SECTOR, MsgClusterSize
printWordHexLn START_SECTOR, word [PartMetaData.ClusterSizeInSector]
FatCheckMaxFilesInCluster
print START_SECTOR, MsgMaxFilesInCluster
printDWordHexLn START_SECTOR, dword [PartMetaData.MaxFilesInCluster]

;Wczytanie Root Directory
loadLBASectors FAT_SEGMENT, 0x0000, dword [PartMetaData.RootDirSector], 1

;Wyświetlenie folderów w Root Directory
newLine
printLn START_SECTOR, MsgFoldersFilesRootDir
xchg bx, bx
Fat32PrintFoldersAndFiles gs, 0x00

newLine
Fat32LoadFolderOrFile FAT_SEGMENT, 0x0000, FAT_SEGMENT, 0x0000, ds, NameUpperTest
jmp $


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
