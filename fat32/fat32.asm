[BITS 16]
[CPU 386]
%define FAT32_IMPLEMENTATION
%include "./global_define.asmh"
%include "./fat32/fat32.asmh"
%include "./print/print.asmh"
%include "./string/string.asmh"

%define FAT32 0x0B
%define FAT32LBA 0x0C
%define HIDFAT32 0x1B
%define HIDFAT32LBA 0x1C

%define NoFileInFat 0xE5
%define EndFileInFat 0x00

%define ASCII_SPACE 0x20



global FunFat32FindMBR
FunFat32FindMBR:
    %push
	%stacksize large
	%arg segAddress:word, offsetAddress:word

    push    bp
    mov     bp, sp

	push bx
    push ds

	mov ds, word [segAddress]
	mov bx, word [offsetAddress]

    lea bx, [bx + Mbr.Part1]
    mov ax, bx
    add ax, 0x40
    .loop:
    cmp byte [bx + MbrPart.PartType], FAT32
        je .FoundFAT32
    cmp byte [bx + MbrPart.PartType], FAT32LBA
        je .FoundFAT32
    cmp byte [bx + MbrPart.PartType], HIDFAT32
        je .FoundFAT32
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

    pop ds
    pop bx
	leave
	ret
	%pop


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
    mov byte [es:di], 0x00

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
	%define tempStringOffset 1

    push    bp
    mov     bp, sp

    sub sp, 12

    push ds
    push si
    push bx

    mov ds, word [segAddress]
    mov si, word [offsetAddress]

    jmp .skip
    .loop:
    add si, 0x20
    .skip:
    cmp byte [ds:si], EndFileInFat
        je .break
    cmp byte [ds:si], NoFileInFat
        je .loop
    mov bx, bp
    add bx, tempStringOffset
    Fat32GetDirOrFileName ss, bx, ds, si
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


global Fun32FatCheckMaxFilesInCluster
Fun32FatCheckMaxFilesInCluster:

    pusha

    xor eax, eax
    xor edx, edx
    xor ebx, ebx
    mov ax, word [ds:Fat32PartMetaDataAddress + Fat32PartMetaData.ClusterSizeInSector]
    mov bl, byte [ds:Fat32PartMetaDataAddress + Fat32PartMetaData.DiskSectorPerPartSector]
    mul ebx
    shl eax, 4
    mov word [ds:Fat32PartMetaDataAddress + Fat32PartMetaData.MaxFilesInCluster], ax

    popa
    ret


global FunFat32LoadFolderOrFile
FunFat32LoadFolderOrFile:
    %push
	%stacksize large
	%arg destSegAddress:word, destOffsetAddress:word, segFolder:word, offsetFolder:word, segPath:word, offsetPath:word
	%define tempString1Offset 1
	%define tempString2Offset 13

    sub sp, 18
    sub sp, 12

    pusha
    push ds
    push es
    xor cx, cx
    mov es, word [destOffsetAddress]
    mov si, word [segFolder]
    mov ax, word [offsetPath]
    mov bx, word [segPath]
    mov di, bp
    add di, tempString1Offset
    stringtoUpper ax, bx
    Fat32PopFolderFromPath ax, bx, ss, di
    cmp byte [es:si + FileFat.Atribute], 0x08
     je .NoFoundFolderOrFile
    .loop:
    pop ds
    push START_SEGMENT
    pop ds
    cmp ecx, dword [ds:Fat32PartMetaDataAddress + Fat32PartMetaData.MaxFilesInCluster]
    pop ds
        je .NoFilesInThisCluster
    mov di, bp
    add di, tempString1Offset
    mov ax, bp
    add ax, tempString2Offset
    Fat32GetDirOrFileName ss, ax, es, si
    stringCmp ss, di, ss, ax
    je .foundFolderOrFile
    jne .NoFoundFolderOrFile
    .back:
    printStringLn ss, di
    printStringLn ss, ax

    pop es
    pop ds
    popa

    add sp, 12
    add sp, 18
    leave
	ret

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
        printStringLn START_SEGMENT, .MsgNoFileInThisCluster
        jmp .back

    .MsgNoFileInThisCluster: db "No file in this cluster.", 0x00
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


global Fat32PartMetaDataAddress
Fat32PartMetaDataAddress: times 13  db 0x00

global Fat32PartStartAddress
Fat32PartStartAddress: times 16  db 0x00

