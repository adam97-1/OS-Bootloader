all: clean ldr.bin kern.bin

BUILD_DIR := ./build
FILES := ./string/string.asm \
	./fat32/fat32.asm \
	./disk/disk.asm \
	./print/print.asm \
	./bootloader.asm
OBJS := $(FILES:.asm=.o)

%.o: %.asm
	nasm -f elf $< -o $@

OS-bootloader: $(OBJS)
	i386-elf-ld -m elf_i386 -T ./bootloader.ld  -o OS-bootloader $(OBJS)
	i386-elf-objcopy -O binary OS-bootloader OS-bootloader.bin

boot.bin: boot.asm
	nasm -f bin -o boot.bin boot.asm
	nasm -f bin -o kern.ab kern.asm

part.img: kern.ab boot.bin OS-bootloader
	dd if=/dev/zero of=part.img bs=1M count=86
	mkfs.fat -F32 -n "OS" part.img
	mmd -i part.img OS
	mmd -i part.img OS/BOOT
	mcopy -i part.img kern.ab ::OS/BOOT/kern.ab

disk.img: part.img
	dd if=/dev/zero of=disk.img bs=1M count=64
	parted disk.img -s mklabel msdos
	parted disk.img -s mkpart primary fat32 2048s 67583s
	dd if=boot.bin of=disk.img conv=notrunc bs=1 count=444
	dd of=disk.img bs=1 seek=444 conv=notrunc << tmp
	dd if=tmp of=disk.img conv=notrunc bs=1 count=2 oseek=444
	dd if=OS-bootloader.bin of=disk.img conv=notrunc oseek=1
	dd if=part.img of=disk.img bs=512 seek=2048 conv=notrunc

run: clean boot.bin OS-bootloader disk.img
	bochs -f bochs.conf -q

debug: clean disk.img
	bochs -f bochs.conf -q -debugger

clean:
	rm -rf *.bin
	rm -rf *.img
	rm -rf $(OBJS)
