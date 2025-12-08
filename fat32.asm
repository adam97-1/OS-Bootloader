%define FAT32 0x0B
%define FAT32LBA 0x0C
%define HIDFAT32 0x1B
%define HIDFAT32LBA 0x1C

%define NoFileInFat 0xE5
%define EndFileInFat 0x00


;Args: startAddressMBR
%macro FindFAT32InMBR 1
    push bx
    mov bx, %1
    call FunFindFAT32InMBR
    pop bx
%endmacro

FunFindFAT32InMBR:
    lea bx, [bx + Mbr.Part1]
    mov ax, bx
    add ax, 0x40
    .loop:
    cmp byte [bx + MbrPart.PartType], FAT32
        je .FoundFAT32
    cmp byte [bx + MbrPart.PartType], FAT32LBA
        je .FoundFAT32
    cmp byte [bx + MbrPart.PartType], HIDFAT32
        je LoadPartiction
    cmp byte [bx + MbrPart.PartType], HIDFAT32LBA
        je .FoundFAT32
    add bx, 0x10
    cmp bx, ax
        je .NotFoundFAT32
    jmp .loop
    .NotFoundFAT32:
    xor bx, bx
    .FoundFAT32:
    mov ax, bx
    ret

%macro Fat32PrintFoldersAndFiles 2
    pusha
    push ds
    push %1
    pop ds
    mov si, %2
    call FunFat32PrintFoldersAndFiles
    pop ds
    popa
%endmacro

FunFat32PrintFoldersAndFiles:
    jmp .skip
    .loop:
    add si, 0x20
    .skip:
    cmp byte [si], EndFileInFat
        je .break
    cmp byte [si], NoFileInFat
        je .loop
    printLn si, 11
    jmp .loop
    .break:
    ret
;Args: DestSegment, DestSegment, FolderSegment, FolderOffset, PathSegment, PathOffset
%macro Fat32LoadFolderOrFile 6
    pusha

    push $1
    push %2
    push %3
    push $4
    push %5
    push %6
    mov bp, sp
    call FunFat32LoadFolderOrFile

    add sp, 12
    popa
%endmacro


FunFat32LoadFolderOrFile:





;Args: SrcSeg, SrcString, DestSegment, DestString
%macro Fat32PopFolderFromPath 4
    push ax
    push cx
    push ds
    push es
    push si
    push di

    push %1
    pop ds
    push %3
    pop es
    mov si, %2
    mov di, %4

    call FunFat32PopFolderFromPath

    pop di
    pop si
    pop es
    pop ds
    pop cx
    pop ax
%endmacro

FunFat32PopFolderFromPath:
    xor cx, cx
    .loop:
    cmp byte [ds:si], '/'
    je .LeftMovePath

    cmp byte [ds:si], 0x00
        je .lastPopFolder

    mov al, [ds:si]
    mov [es:di], al

    inc si
    inc di
    inc cx

    jmp .loop


    .LeftMovePath:
    mov byte [es:di], 0x00
    mov di, si
    sub di, cx
    inc si
    .loop2:
    cmp byte [ds:si], 0x00
        je .end
    mov al, [ds:si]
    mov [ds:di], al

    inc si
    inc di

    jmp .loop2

    .lastPopFolder:
    sub si, cx
    mov byte [ds:si], 0x00
    .end:
    mov byte [es:di], 0x00
    ret


struc Fat
    .FirstByte resb 3
    .OemId resb 8
    .BytePerSector resb 2
    .SectorPerCluster resb 1
    .ReservedSectors resb 2
    .NumberOfFat resb 1
    .NumOfRootDirEntries resb 2
    .TotalSectorInLV resb 2
    .MediaDescriptorType resb 1
    .SectorPerFat resb 2
    .SectorPerTrack resb 2
    .NumGeadsOrSidesOnMedia resb 2
    .NumHiddenSector resb 4
    .LargeSector resb 4
    .SectorPerFat32 resb 4
    .Flags resb 2
    .FatVersion resb 2
    .ClusterRootDir resb 4
    .SectorOfFsInfo resb 2
    .SectorOfBackupBoot resb 2
    .Reserved resb 12
    .DriveNumber resb 1
    .FlagsWinNT resb 1
    .Signature resb 1
    .VolumeID resb 4
    .Label resb 1
    .IdString resb 8
    .BootCode resb 420
    .End resb 2
endstruc

struc Mbr
    .BootArea resb 446
    .Part1 resb 16
    .Part2 resb 16
    .Part3 resb 16
    .Part4 resb 16
    .BootSig resb 2
endstruc

struc MbrPart
    .StatusDrive resb 1
    .FirstChsSect resb 3
    .PartType resb 1
    .LastChsSect resb 3
    .FirstLbaSect resb 4
    .NumberOfSect resb 4
endstruc

struc FileFat
    .ShortName resb 11
    .Atribute resb 1
    .Res1 resb 1
    .CreateTime resb 2
    .CreateDate resb 2
    .LastAccessDate resb 2
    .FirstClusterHi resb 2
    .WriteTime resb 2
    .WriteData resb 2
    .FirstClusterLo resb 2
    .FileSize resb 4
endstruc



PartMetaData:
    .RootDirSector: dd 0x00000000
    .DiskSectorPerPartSector: db 0x00
    .ClusterSizeInSector: dw 0x0000
    .CurrentDirCluster: dd 0x00000000


PartFat32StartAddress: times 16  db 0x00

