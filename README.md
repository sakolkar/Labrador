# Labrador
### Minimal Kernel
#### i686-elf Bare Bones OS using GRUB for bootloader

Tutorial Kernel from [OSDev](http://wiki.osdev.org/Bare_Bones)

This uses a multiboot standard header to load in the kernel program.

Requires cross-compiler for ix86 in order to build. Follow the instructions on
[Building GCC Cross-Compiler](http://wiki.osdev.org/GCC_Cross-Compiler). The
kernel was built on Arch Linux 4.2.1 with the following versions or required
programs:
- gcc-6.2.0 (cross-compiler version)
- binutils-2.27 (for assembler)
- GNU Make 4.2.1
- GNU Bison 3.0.4
- Flex 2.6.1
- gmp-6.1.1-1
- mpfr-3.1.5-1
- mpc-0.28-1
- texinfo-6.3-1
- xorriso 1.4.6 (to run grub-mkrescue)
- GNU mtools 4.0.18 (for grub-mkrescue)

#Instructions to build:
1. Assemble `boot.s`.
```shell
i686-elf-as boot.s -o boot.o
```

2. Cross-Compile `kernel.c`
```shell
i686-elf-gcc -c kernel.c -o kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
```

3. Use `gcc` to link files
```shell
i686-elf-gcc -T linker.ld -o myos.bin -ffreestanding -O2 -nostdlib boot.o kernel.o -lgcc
```

4. Create ISO file bundling kernel with GRUB to run with QEMU
```shell
cp myos.bin isodir/boot/myos.bin
grub-mkrescue -o myos.iso isodir
```

5. Run With QEMU
```shell
qemu-system-i386 -cdrom myos.iso
```
