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

;Args: DestSegment. DestOffset, DirStructSegment, DirStructOffset
%macro Fat32GetDirOrFileName 4
    push ds
    push si
    push di
    push ax
    push bx
    push cx

    push %3
    push %1
    pop es
    pop ds

    mov si, %4
    mov di, %2

    call FunFat32GetDirOrFileName

    pop cx
    pop bx
    pop ax
    pop di
    pop si
    pop ds

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

; Fat32PopFolderFromPath es, sdsad. ds, asdas
;Args: SrcSeg, SrcString, DestSegment, DestString
%macro Fat32PopFolderFromPath 4
    push ax
    push cx
    push ds
    push es
    push si
    push di

    push %1
    push %3
    pop es
    pop ds

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
    sub sp, 12

    jmp .skip
    .loop:
    add si, 0x20
    .skip:
    cmp byte [ds:si], EndFileInFat
        je .break
    cmp byte [ds:si], NoFileInFat
        je .loop
    Fat32GetDirOrFileName ss, cdecl_var(12), ds, si
    printLn ss, cdecl_var(12)
    jmp .loop
    .break:
    add sp, 12
    cdecl_exit
    ; .TempFileName: times 12  db 0x00


%macro FatCheckMaxFilesInCluster 0
    pusha

    call FunFatCheckMaxFilesInCluster

    popa
%endmacro

FunFatCheckMaxFilesInCluster:
    xor eax, eax
    xor edx, edx
    xor ebx, ebx
    mov ax, word [ds:PartMetaData.ClusterSizeInSector]
    mov bl, byte [ds:PartMetaData.DiskSectorPerPartSector]
    mul ebx
    shl eax, 4
    mov word [ds:PartMetaData.MaxFilesInCluster], ax
    ret

;Args: DestSegment, DestOffset, FolderSegment, FolderOffset, PathSegment, PathOffset
%macro Fat32LoadFolderOrFile 6
    pusha
    push ds
    push es
    push %6
    push %5
    push %4
    push %3
    push %2
    push %1

    call FunFat32LoadFolderOrFile

    add sp, 12
    pop es
    pop ds
    popa
%endmacro


%push
%define TempFileName cdecl_var(18)
%define TempFileName2 cdecl_var(18 + 12)
FunFat32LoadFolderOrFile:
    cdecl_entry
    xchg bx, bx
    sub sp, 18
    sub sp, 12

    xor cx, cx
    mov es, cdecl_param(2)
    mov si, cdecl_param(3)
    xchg bx, bx
    stringtoUpper cdecl_param(4), cdecl_param(5)
    xchg bx, bx
    Fat32PopFolderFromPath cdecl_param(4), cdecl_param(5), ss, TempFileName
    xchg bx, bx
    cmp byte [es:si + FileFat.Atribute], 0x08
     je .NoFoundFolderOrFile
    .loop:
    pop ds
    push START_SECTOR
    pop ds
    cmp ecx, dword [ds:PartMetaData.MaxFilesInCluster]
    pop ds
        je .NoFilesInThisCluster
    Fat32GetDirOrFileName ss, TempFileName2, es, si
    stringCmp ss, TempFileName, ss, TempFileName2
    je .foundFolderOrFile
    jne .NoFoundFolderOrFile
    .back:
    printLn ss, TempFileName
    printLn ss, TempFileName2

    add sp, 12
    add sp, 18
    cdecl_exit

    .foundFolderOrFile:
        ;Wczytać plik.
        ;Jężeli Path ma długość 0 to wyjść z funkcji.
        ;W przeciwnym wypatku uruchomić rekurencyjnie tą funckję.
        jmp .back
    .NoFoundFolderOrFile:
        inc cx
        add si, 0x20
        jmp .loop
    .NoFilesInThisCluster:
        ;Sprawdzic czy jest nstępny klaster.
        ;Jeżeli jest należy go wczytać i kontynułować sprawdzenie.
        ;W przeciwnym wypadku wyjść z funckji z błędem.
        printLn START_SECTOR, .MsgNoFileInThisCluster
        jmp .back


    ; .TempFileName: times 16  db 0x00
    ; .Temp2FileName: times 11  db 0x00
    .MsgNoFileInThisCluster: db "No file in this cluster.", 0x00
%pop

%define ASCII_SPACE 0X20

FunFat32GetDirOrFileName:
    cmp byte [ds:si], EndFileInFat
        je .end
    cmp byte [ds:si], NoFileInFat
        je .end
    xor cx, cx
    .loopName:
    cmp cx, 0x07
     je .readExt
    cmp byte [ds:si], ASCII_SPACE
        je .readExt
    mov al, byte [ds:si]
    mov byte [es:di], al
    inc cx
    inc si
    inc di
    jmp .loopName

    .readExt:
    mov ax, 0x8
    sub ax, cx
    add si, ax
    xor cx, cx

    .loopExt:
    cmp cx, 0x02
     je .end
    cmp byte [ds:si], ASCII_SPACE
        je .end
    mov al, byte [ds:si]
    mov byte [es:di], al
    inc cx
    inc si
    inc di
    jmp .loopExt

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
    .MaxFilesInCluster: dw 0x00000000


PartFat32StartAddress: times 16  db 0x00

