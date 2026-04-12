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
DiskCopyMBR BOOT_SEGMENT_RAM, DISK_Mbr
DiskFindMBR BOOT_SEGMENT_RAM, DISK_Mbr
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

;Zapisanie offsetu partaycji od począdku dysku.
mov bx, BOOT_SEGMENT_RAM
mov fs, bx
mov bx, START_SEGMENT
mov ds, bx
add ax, DISK_MbrPartData.FirstLbaSect
mov bx, ax

mov eax, dword [fs:bx]
mov dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.PartSectOffset], eax

;Wczytanie pierwszego sektora partcji FAT32
diskLoadLBASectors FAT_SEGMENT, 0x0000, dword 0x0000, dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.PartSectOffset], 0x0001
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

Fat32Init gs, 0x0000
;Wyświetlenie inforamcji pomocniczych
newLine
printString START_SEGMENT, MsgBPB_BytsPerSec
printWordHexLn word [gs:FAT_BPB.BPB_BytsPerSec]

printString START_SEGMENT, MsgBPB_SecPerClus
xor ax, ax
mov al, byte [gs:FAT_BPB.BPB_SecPerClus]
printByteHexLn ax

printString START_SEGMENT, MsgBPB_RsvdSecCnt
printWordHexLn word [gs:FAT_BPB.BPB_RsvdSecCnt]

printString START_SEGMENT, MsgBPB_FATSz32
printDWordHexLn dword [gs:FAT_BPB_FAT32.BPB_FATSz32]

printString START_SEGMENT, MsgBPB_RootClus
printWordHexLn word [gs:FAT_BPB_FAT32.BPB_RootClus]

;Wyświetlenie ile sektorów dysku przypada na sektor partycji
printString START_SEGMENT, MsgDiskSectorPerPartSector
xor ax, ax
mov al, byte [ds:FAT_FatMetaDataAddress + Fat_MetaData.DiskSectorPerPartSector]
printByteHexLn ax


;Wyświetlenie w którm sektorze znajduje się Root Directory
printString START_SEGMENT, MsgRootDirSector
printDWordHexLn dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.RootDirSectors]


;Wyświetlenie ile przpada sektorów dysku na cluster w partycji
printString START_SEGMENT, MsgClusterSize
printWordHexLn word [ds:FAT_FatMetaDataAddress + Fat_MetaData.ClusterSizeInSector]
Fat32CheckMaxFilesInCluster
printString START_SEGMENT, MsgMaxFilesInCluster
printWordHexLn dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.MaxFilesInCluster]

;Wczytanie Root Directory
Fat32CalcAddressSect 2
diskLoadLBASectors FAT_SEGMENT, 0x0000, dword 0x00000000, eax, 1
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

FolderNameTest: times 12 db 0x00
NameUpperTest: db "os/boot/kenr.ab", 0x00

MsgErrFindFAT32: db "Not found FAT32 partitions.", 0x00

MsgLoadBootloader: db "Loaded Bootloader.", 0x00

MsgLoadPart: db "Loaded first serctor of FAT32.", 0x00

MsgBPB_BytsPerSec: db "FAT_BPB.BPB_BytsPerSec: ", 0x00

MsgBPB_FATSz32: db "FAT_BPB_FAT32.BPB_FATSz32: ", 0x00

MsgBPB_RsvdSecCnt: db "FAT_BPB.BPB_RsvdSecCnt: ", 0x00

MsgBPB_SecPerClus: db "FAT_BPB.BPB_SecPerClus: ", 0x00

MsgBPB_RootClus: db "FAT_BPB_FAT32.BPB_RootClus: ", 0x00

MsgDiskSectorPerPartSector: db "DiskSectorPerPartSector: ", 0x00

MsgRootDirSector: db "RootDirSector: ", 0x00

MsgClusterSize: db "ClusterSize: ", 0x00

MsgFoldersFilesRootDir: db "Folders or files in root directory: ", 0x00

MsgMaxFilesInCluster: db "Max Files In Cluster: ", 0x00
