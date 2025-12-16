all: clean ldr.bin kern.bin


%.bin: %.asm
	nasm $< -o $@


part.img: kern.bin
	dd if=/dev/zero of=part.img bs=1M count=86
	mkfs.fat -F32 -n "OS" part.img
	mmd -i part.img OS
	mmd -i part.img OS/BOOT
	mcopy -i part.img kern.bin ::OS/BOOT/kern.ab

disk.img: part.img ldr.bin
	dd if=/dev/zero of=disk.img bs=1M count=64
	parted disk.img -s mklabel msdos
	parted disk.img -s mkpart primary fat32 2048s 67583s
	dd if=ldr.bin of=disk.img conv=notrunc bs=1 count=446
	dd if=ldr.bin of=disk.img conv=notrunc iseek=1 oseek=1
	dd if=part.img of=disk.img bs=512 seek=2048 conv=notrunc

run: clean disk.img
	bochs -f bochs.conf -q

debug: clean disk.img
	bochs -f bochs.conf -q -debugger

clean:
	rm -rf *.bin
	rm -rf *.img
