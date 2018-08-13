echo "Uncomment the 9th line of this file to create a properly sized disk image"
echo "Uncomment lines 14-15 for disassembly"

nasm -f bin -o boot.bin bootloader.asm
nasm -f bin -o stage2.bin stage2.asm
nasm -f bin -o staticindex.bin staticindex.asm

#dd if=LilakOS.img of=/dev/zero bs=512 count=‭4194304‬
dd if=boot.bin of=LilakOS.img bs=512 seek=0 conv=notrunc
dd if=stage2.bin of=LilakOS.img bs=512 seek=1 conv=notrunc
dd if=staticindex.bin of=LilakOS.img bs=512 seek=2097151 conv=notrunc

#ndisasm boot.bin>bootloader.dis
#ndisasm stage2>stage2.dis

echo "Done!"
