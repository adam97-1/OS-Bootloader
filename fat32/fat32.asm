[BITS 16]
[CPU 386]
%define FAT32_IMPLEMENTATION
%include "./global_define.asmh"
%include "./fat32/fat32.asmh"
%include "./print/print.asmh"
%include "./string/string.asmh"
%include "./disk/disk.asmh"

%define NoFileInFat 0xE5
%define EndFileInFat 0x00

%define ASCII_SPACE 0x20



global FunFat32PopFolderFromPath
FunFat32PopFolderFromPath:
    %push
	%stacksize large
	%arg srcSegString:word, offsetSrcString:word, destSegString:word, offserDestString:word

    push    bp
    mov     bp, sp

    pusha
    push ds
    push es

    mov ds, word [srcSegString]
    mov si, word [offsetSrcString]
    mov es, word [destSegString]
    mov di, word [offserDestString]

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
    mov byte [ds:di], 0x00

    pop es
    pop ds
    popa
	leave
	ret
	%pop


global FunFat32PrintFoldersAndFiles
FunFat32PrintFoldersAndFiles:
    %push
	%stacksize large
	%arg segAddress:word, offsetAddress:word
	%define tempStringOffset 12

    push    bp
    mov     bp, sp

    sub sp, 12

    push ds
    push si
    push bx

    mov ds, word [segAddress]
    mov si, word [offsetAddress]

    cmp word [ds:si + FileFat.FirstClusterHi], word 0x00
        jne .skip
    cmp word [ds:si + FileFat.FirstClusterLo], word 0x00
        jne .skip

    .loop:
    add si, FileFat.structSize
    .skip:
    cmp byte [ds:si], EndFileInFat
        je .break
    cmp byte [ds:si], NoFileInFat
        je .loop
    mov bx, bp
    sub bx, tempStringOffset
    Fat32GetDirOrFileName ds, si, ss, bx
    printStringLn ss, bx
    jmp .loop
    .break:
    pop bx
    pop si
    pop ds
    add sp, 12
	leave
	ret
	%pop


global FunFat32CheckMaxFilesInCluster
FunFat32CheckMaxFilesInCluster:

    pusha

    xor eax, eax
    xor edx, edx
    xor ebx, ebx
    mov ax, word [ds:FAT_BPBAddress + FAT_BPB.BPB_SecPerClus]
    mov bl, byte [ds:FAT_FatMetaDataAddress + Fat_MetaData.DiskSectorPerPartSector]
    mul ebx
    shl eax, 4
    mov word [ds:FAT_FatMetaDataAddress + Fat_MetaData.MaxFilesInCluster], ax

    popa
    ret


global FunFat32LoadFolderOrFile
FunFat32LoadFolderOrFile:
    %push
	%stacksize large
	%arg destSegAddress:word, destOffsetAddress:word, segFolder:word, offsetFolder:word, sizeInSect:dword,  segPath:word, offsetPath:word
	%define tempString1Offset 12 ;  size 12
	%define tempString2Offset  tempString1Offset + 18 ; size 18
    %define readedSizeinSect tempString2Offset + 2
    %define destOffsetAddressTmp readedSizeinSect + 2
    %define destSegAddressTmp destOffsetAddressTmp + 2
    %define nextCluster destSegAddressTmp + 4


    push bp
    mov bp, sp

    sub sp, nextCluster


    pusha
    push ds
    push es
    push gs

    mov ax , word [destOffsetAddress]
    mov word [ss:bp - (destOffsetAddressTmp)], ax
    mov ax , word [destSegAddress]
    mov word [ss:bp - (destSegAddressTmp)], ax
    mov ax , 0x00
    mov word [ss:bp - (readedSizeinSect)], ax
    xor cx, cx
    mov es, word [segFolder]
    mov gs, word [segPath]
    mov bx, word [offsetPath]
    mov si, word [offsetFolder]
    mov di, bp
    sub di, tempString1Offset


    cmp byte [gs:bx], 0x00
        je .back
    stringtoUpper gs, bx
    Fat32PopFolderFromPath gs, bx, ss, di


    cmp byte [es:offsetFolder + FileFat.Atribute], 0x08
        je .NoFoundFolderOrFile

        ;Pomiń gdy pierwszy folder to RootDir
    cmp word [es:si + FileFat.FirstClusterHi], word 0x00
        jne .noSkipFirstFolder
    cmp word [es:si + FileFat.FirstClusterLo], word 0x00
        jne .noSkipFirstFolder

    jmp .NoFoundFolderOrFile

    .noSkipFirstFolder:

    .loop:
    push ds
    push START_SEGMENT
    pop ds
    xor edx, edx
    mov eax, dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.MaxFilesInCluster]
    mul dword [sizeInSect]
    cmp ecx, eax
    pop ds
        je .NoFilesInThisCluster
    ; mov di, bp
    ; sub di, tempString1Offset
    mov ax, bp
    sub ax, tempString2Offset
    Fat32GetDirOrFileName es, si, ss, ax
    stringCmp ss, di, ss, ax

    je .foundFolderOrFile
    jne .NoFoundFolderOrFile
    .back:
    pop gs
    pop es
    pop ds
    popa
    add sp, nextCluster
    leave
	ret

    .foundFolderOrFile:
        ;Wczytać plik.
        ;Jężeli Path ma długość 0 to wyjść z funkcji.
        ;W przeciwnym wypatku uruchomić rekurencyjnie tą funckję.
        printString START_SEGMENT, .MsgFoundFileOrDir
        printStringLn ss, di
        mov ax, word [es:si + FileFat.FirstClusterHi]
        shl eax, 16
        mov ax, word [es:si + FileFat.FirstClusterLo]
        mov dword [ss:bp - (nextCluster)], eax

        ; xor bx, bx
        ; mov bl, byte [ds:FAT_BPBAddress + FAT_BPB.BPB_SecPerClus]
        ; diskLoadLBASectors word [destSegAddress], word [destOffsetAddress], dword 0x00000000, eax, bx
        jmp .fisrtSkip
        .loop2:
        mov ax, word [ss:bp - (destOffsetAddressTmp)]
        add ax, word [ds:FAT_BPBAddress + FAT_BPB.BPB_BytsPerSec]
        cmp ax, 0xFFFF
            jne .noCarrt
        .carry:
        mov word [ss:bp - (destOffsetAddressTmp)], 0x00
        mov ax, word [ss:bp - (destSegAddressTmp)]
        add ax, 0x200

        mov word [ss:bp - (destSegAddressTmp)], ax

        .noCarrt:
        mov word [ss:bp - (destOffsetAddressTmp)], ax
        .skipLine1:
        .fisrtSkip:
        mov ecx, dword [ss:bp - (nextCluster)]
        xor bx, bx
        mov bl, byte [ds:FAT_BPBAddress + FAT_BPB.BPB_SecPerClus]
        Fat32CalcAddressSect  ecx
        diskLoadLBASectors word [ss:bp - (destSegAddressTmp)], word [ss:bp - (destOffsetAddressTmp)], dword 0x00000000, eax, bx
        inc [ss:bp - (readedSizeinSect)]
        Fat32GetNextCluster ecx
        cmp eax, 0x0FFFFFF8
        mov dword [ss:bp - (nextCluster)], eax
            jne .loop2
        Fat32LoadFolderOrFile word [destSegAddress], word [destOffsetAddress], word [destSegAddress], word [destOffsetAddress], dword [ss:bp - (readedSizeinSect)], word [segPath], word [offsetPath]
        jmp .back
    .NoFoundFolderOrFile:
        inc cx
        add si, FileFat.structSize
        jmp .loop
    .NoFilesInThisCluster:
        ;Sprawdzic czy jest nstępny klaster.
        ;Jeżeli jest należy go wczytać i kontynułować sprawdzenie.
        ;W przeciwnym wypadku wyjść z funckji z błędem.
        printStringLn START_SEGMENT, .MsgNoFileInThisCluster
        jmp .back

    .MsgNoFileInThisCluster: db "No file in this cluster.", 0x00
    .MsgFoundFileOrDir: db "Found file or directory: ", 0x00

    %pop

FunFat32GetDirOrFileName:
    %push
	%stacksize large
	%arg segFolder:word, offsetFolder:word, destSegString:word, offserDestString:word

    push    bp
    mov     bp, sp

    pusha
    push ds
    push es

    mov ds, word [segFolder]
    mov si, word [offsetFolder]
    mov es, word [destSegString]
    mov di, word [offserDestString]

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
    
    cmp byte [ds:si], ASCII_SPACE
     jne .addDot
     je  .loopExt
    
    .addDot:
    mov byte [es:di], '.'
    inc di

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

    pop es
    pop ds
    popa
    leave
	ret

global FunFat32Init
FunFat32Init:
    %push
    %stacksize large
    %arg segBPB:word, offsetBPB:word

    push bp
    mov bp, sp

    Fat32CopyBPB word [segBPB], word [offsetBPB]
    Fat32CalcRootDirSectors
    Fat32CheckFatType
    Fat32CheckMaxFilesInCluster
    Fat32CalcDiskSectToPartSect
    Fat32CalcFirstDataSector

    leave
    ret
    %pop

global FunFat32CopyBPB
FunFat32CopyBPB:
    %push
    %stacksize large
    %arg segBPB:word, offsetBPB:word

    push bp
    mov bp, sp

    push ax
    push si
    push di
    push ds
    push es

    cld
    mov cx, 512
    mov ax, word [segBPB]
    mov ds, ax
    mov ax, START_SEGMENT
    mov es, ax
    mov si, word [offsetBPB]
    mov di, FAT_BPBAddress
    rep movsb

    pop es
    pop ds
    pop di
    pop si
    pop ax

    leave
    ret
    %pop


global FunFat32CheckFatType
FunFat32CheckFatType:
    %push

    push bp
    mov bp, sp
    push eax
    push edx
    push ebx

    xor eax, eax
    mov ax, word [ds:FAT_BPBAddress + FAT_BPB.BPB_FATSz16]
    cmp ax, 0x00
    jne .skip1
        mov eax, dword [ds:FAT_BPBAddress + FAT_BPB_FAT32.BPB_FATSz32]
    .skip1:
    mov dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.FATSz], eax

    xor eax, eax
    mov ax, word [ds:FAT_BPBAddress + FAT_BPB.BPB_TotSec16]
    cmp ax, 0x00
    je .skip2
        mov eax, dword [ds:FAT_BPBAddress + FAT_BPB.BPB_TotSec32]
    .skip2:
    mov dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.TotSec], eax

    xor edx, edx
    mov eax, dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.FATSz]
    mov bl, byte [ds:FAT_BPBAddress + FAT_BPB.BPB_NumFATs]
    mul ebx

    xor ebx, ebx
    mov bx, word [ds:FAT_BPBAddress + FAT_BPB.BPB_RsvdSecCnt]
    add eax, ebx
    add eax, dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.RootDirSectors]

    mov ebx, dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.TotSec]
    sub ebx, eax

    mov dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.DataSec], ebx

    xor edx, edx
    mov eax, ebx
    xor ebx, ebx
    mov bl, byte [ds:FAT_BPBAddress + FAT_BPB.BPB_SecPerClus]
    div ebx

    cmp eax, 4085
    jb .fat12
    cmp eax, 65525
    jb .fat16
    jmp .fat32

    .fat12:
        mov byte [ds:FAT_FatMetaDataAddress + Fat_MetaData.FatType], FAT12
        jmp .exit
    .fat16:
        mov byte [ds:FAT_FatMetaDataAddress + Fat_MetaData.FatType], FAT16
        jmp .exit
    .fat32:
        mov byte [ds:FAT_FatMetaDataAddress + Fat_MetaData.FatType], FAT32

    .exit:
    pop eax
    pop edx
    pop ebx
    leave
    ret
    %pop

global FunFat32CalcRootDirSectors
FunFat32CalcRootDirSectors:
    %push

    push bp
    mov bp, sp

    push eax
    push ebx
    push edx

    xor ebx, ebx
    xor eax, eax
    xor edx, edx
    mov ax, word [ds:FAT_BPBAddress + FAT_BPB.BPB_RootEntCnt]
    mov bx, 32
    mul ebx
    mov bx, word [ds:FAT_BPBAddress + FAT_BPB.BPB_BytsPerSec]
    add eax, ebx
    sub eax, 1
    xor edx, edx
    div ebx
    mov dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.RootDirSectors], eax

    pop eax
    pop ebx
    pop edx
    leave
    ret
    %pop

global FunFat32CalcDiskSectToPartSect
FunFat32CalcDiskSectToPartSect:
    %push

    push bp
    mov bp, sp

    push eax
    push edx
    push ebx

    xor eax, eax
    xor edx, edx
    mov ax, word [gs:FAT_BPB.BPB_BytsPerSec]
    mov ebx, SizeDiskSector
    div ebx
    mov byte [FAT_FatMetaDataAddress +  Fat_MetaData.DiskSectorPerPartSector], al
    
    pop ebx
    pop edx
    pop eax
    leave
    ret
    %pop

global FunFat32CalcFirstDataSector:
FunFat32CalcFirstDataSector:
    push bp
    mov bp, sp

    push eax
    push ebx
    push edx

    xor eax, eax
    xor edx, edx
    mov al, byte [ds:FAT_BPBAddress + FAT_BPB.BPB_NumFATs]
    mov ebx, dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.FATSz]
    mul ebx
    xor ebx, ebx
    mov bx, word [ds:FAT_BPBAddress + FAT_BPB.BPB_RsvdSecCnt]
    add eax, ebx
    mov ebx, dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.RootDirSectors]
    add eax, ebx
    mov  dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.FirstDataSector], eax

    pop edx
    pop ebx
    pop eax
    leave
    ret
    %pop

global FunFat32CalcAddressSect
FunFat32CalcAddressSect:
    %push
    %stacksize large
    %arg numSect:dword

    push bp
    mov bp, sp

    push ebx
    push edx

    xor eax, eax
    xor edx, edx
    xor ebx, ebx
    mov al, byte [ds:FAT_BPBAddress + FAT_BPB.BPB_SecPerClus]
    mov ebx, [numSect]
    sub ebx, 2
    mul ebx
    mov ebx, dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.FirstDataSector]
    add eax, ebx
    xor edx, edx
    xor ebx, ebx
    mov bl, byte [ds:FAT_FatMetaDataAddress + Fat_MetaData.DiskSectorPerPartSector]
    mul ebx
    add eax, dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.PartSectOffset]

    pop edx
    pop ebx
    leave
    ret
    %pop

global FunFat32GetNextCluster
FunFat32GetNextCluster:
    %push
    %stacksize large
    %arg cluster:dword
    %define ThisFATSecNum 4 ;  size 4
	%define ThisFATEntOffset  ThisFATSecNum + 2 ; size 2
    %define FATOffset  ThisFATEntOffset + 4 ; size 4

    push bp
    mov bp, sp

    sub sp, FATOffset

    push ebx
    push si
    push edx

    cmp byte [ds:FAT_FatMetaDataAddress + Fat_MetaData.FatType], FAT12
        je .fat12
    cmp byte [ds:FAT_FatMetaDataAddress + Fat_MetaData.FatType], FAT16
        je .fat16
    jmp .fat32


    .exit:
    pop edx
    pop si
    pop ebx
    add sp, FATOffset
    leave
    ret

    .fat12:
    mov eax, dword [cluster]
    mov ebx, 2
    div ebx
    add eax, dword [cluster]
    mov si, bp
    sub si, FATOffset
    mov dword [si], ebx

    xor ebx, ebx
    mov bx, word [ds:FAT_BPBAddress + FAT_BPB.BPB_BytsPerSec]
    div ebx
    add ax, word [ds:FAT_BPBAddress + FAT_BPB.BPB_RsvdSecCnt]
    mov si, bp
    sub si, ThisFATSecNum
    mov dword [ss:si], eax
    mov si, bp
    sub si, ThisFATEntOffset
    mov word [ss:si], dx

    xor ebx, ebx
    xor edx, edx
    mov bx, word [ds:FAT_BPBAddress + FAT_BPB.BPB_BytsPerSec]
    div ebx
    add ax, word [ds:FAT_BPBAddress + FAT_BPB.BPB_RsvdSecCnt]
    mov si, bp
    sub si, ThisFATSecNum
    mov dword [ss:si], eax
    mov si, bp
    sub si, ThisFATEntOffset
    mov word [ss:si], dx

    add eax, dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.PartSectOffset]
    diskLoadLBASectors FAT_SEGMENT, word 0x00, dword 0x00, eax, 1
    mov ax, FAT_SEGMENT
    mov gs, ax
    mov bx, dx
    mov eax, dword [cluster]
    and eax, 0x01
    cmp eax, 0x01
        je .odd
    jmp .even
    .backFat12:
    jmp .exit

    .odd:
        xor eax, eax
        mov ax, word [gs:bx]
        shr ax, 0x04
        mov bx, ax
        sub bx, 0x0FF8
        cmp bx, 7          ; zakres 0–7 oznacza EOF (0xF8, F9, FA, FB, FC, FD, FE, FF)
            jge .backFat12   
        mov eax, 0x0FFFFFF8
        jmp .backFat12
    .even:
        xor eax, eax
        mov ax, word [gs:bx]
        and ax, 0x0FFF
        mov bx, ax
        sub bx, 0x0FF8
        cmp bx, 7          ; zakres 0–7 oznacza EOF (0xF8, F9, FA, FB, FC, FD, FE, FF)
            jge .backFat12   
        mov eax, 0x0FFFFFF8
        jmp .backFat12

    .fat16:
    mov eax, dword [cluster]
    mov ebx, 2
    mul ebx
    mov si, bp
    sub si, FATOffset
    mov dword [si], ebx

    xor ebx, ebx
    mov bx, word [ds:FAT_BPBAddress + FAT_BPB.BPB_BytsPerSec]
    div ebx
    add ax, word [ds:FAT_BPBAddress + FAT_BPB.BPB_RsvdSecCnt]
    mov si, bp
    sub si, ThisFATSecNum
    mov dword [ss:si], eax
    mov si, bp
    sub si, ThisFATEntOffset
    mov word [ss:si], dx

    xor ebx, ebx
    xor edx, edx
    mov bx, word [ds:FAT_BPBAddress + FAT_BPB.BPB_BytsPerSec]
    div ebx
    add ax, word [ds:FAT_BPBAddress + FAT_BPB.BPB_RsvdSecCnt]
    mov si, bp
    sub si, ThisFATSecNum
    mov dword [ss:si], eax
    mov si, bp
    sub si, ThisFATEntOffset
    mov word [ss:si], dx

    add eax, dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.PartSectOffset]
    diskLoadLBASectors FAT_SEGMENT, word 0x00, dword 0x00, eax, 1
    mov ax, FAT_SEGMENT
    mov gs, ax
    mov bx, dx
    xor eax, eax
    mov ax, word [gs:bx]
    mov bx, ax
    sub bx, 0x0FF8
    cmp bx, 7          ; zakres 0–7 oznacza EOF (0xF8, F9, FA, FB, FC, FD, FE, FF)
        jge .exit   
    mov eax, 0x0FFFFFF8

    jmp .exit

    .fat32:
    mov eax, dword [cluster]
    mov ebx, 4
    mul ebx
    mov si, bp
    sub si, FATOffset
    mov dword [ss:si], ebx

    xor ebx, ebx
    xor edx, edx
    mov bx, word [ds:FAT_BPBAddress + FAT_BPB.BPB_BytsPerSec]
    div ebx
    add ax, word [ds:FAT_BPBAddress + FAT_BPB.BPB_RsvdSecCnt]
    mov si, bp
    sub si, ThisFATSecNum
    mov dword [ss:si], eax
    mov si, bp
    sub si, ThisFATEntOffset
    mov word [ss:si], dx

    add eax, dword [ds:FAT_FatMetaDataAddress + Fat_MetaData.PartSectOffset]
    diskLoadLBASectors FAT_SEGMENT, word 0x00, dword 0x00, eax, 1
    mov ax, FAT_SEGMENT
    mov gs, ax
    mov bx, dx
    mov eax, dword [gs:bx]
    and eax, 0x0FFFFFFF
    mov ebx, eax
    sub ebx, 0x0FFFFFF8
    cmp ebx, 7          ; zakres 0–7 oznacza EOF (0xF8, F9, FA, FB, FC, FD, FE, FF)
        jbe .is_eof32          ; jump if below or equal (unsigned)
    jmp .exit
    
    .is_eof32:
    mov eax, 0x0FFFFFF8
    jmp .exit

    %pop

global FunFat32LoadRootDir
FunFat32LoadRootDir:
    %push
    %stacksize large
    %arg segmentDest:word, offserDest:word
    %define readedSizeinSect 2
    push bp
    mov bp, sp

    push eax
    push bx
    push dx
    mov [ss:bp - readedSizeinSect], 0x0000

    mov dx, word [offserDest]
   
    xor bx, bx
    mov bl, byte [ds:FAT_BPBAddress + FAT_BPB.BPB_SecPerClus]
   
    mov ecx, 2
    jmp .skipFirst
    .loop:
    mov ecx, eax
    add dx, word [ds:FAT_BPBAddress + FAT_BPB.BPB_BytsPerSec]
    .skipFirst:
    Fat32CalcAddressSect  ecx
    diskLoadLBASectors word [segmentDest], dx, dword 0x00000000, eax, bx
    inc [ss:bp - readedSizeinSect]
    Fat32GetNextCluster ecx
    cmp eax, 0x0FFFFFF8
        jne .loop

    mov ecx, [ss:bp - readedSizeinSect]
    pop dx
    pop bx
    pop eax

    leave
    ret
    %pop

global FAT_FatMetaDataAddress
FAT_FatMetaDataAddress: times Fat_MetaData.StructSize  db 0x00

global FAT_BPBAddress
FAT_BPBAddress: times 512  db 0x00


