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
	ld -o OS-bootloader $<

boot.bin: boot.asm
	ld -o boot.bin boot.asm

part.img: kern.bin boot.bin OS-bootloader
	dd if=/dev/zero of=part.img bs=1M count=86
	mkfs.fat -F32 -n "OS" part.img
	mmd -i part.img OS
	mmd -i part.img OS/BOOT
	mcopy -i part.img kern.bin ::OS/BOOT/kern.ab

disk.img: part.img
	dd if=/dev/zero of=disk.img bs=1M count=64
	parted disk.img -s mklabel msdos
	parted disk.img -s mkpart primary fat32 2048s 67583s
	dd if=boot.bin of=disk.img conv=notrunc bs=1 count=446
	dd if=OS-bootloader of=disk.img conv=notrunc iseek=1 oseek=1
	dd if=part.img of=disk.img bs=512 seek=2048 conv=notrunc

run: clean OS-bootloader disk.img
	bochs -f bochs.conf -q

debug: clean disk.img
	bochs -f bochs.conf -q -debugger

clean:
	rm -rf *.bin
	rm -rf *.img
	rm -rf $(OBJS)
