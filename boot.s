# Declare constants for the multiboot header.
.set ALIGN,     1<<0               # align loaded modules on page boundaries
.set MEMINFO,   1<<1               # provide memory map
.set FLAGS,     ALIGN | MEMINFO    # this is the Multiboot 'flag' field
.set MAGIC,     0x1BADB002         # magic number lets bootlader find the header
.set CHECKSUM,  -(MAGIC + FLAGS)   # checksum of above to prove we are multiboot

# Declare a multiboot header that arks the program as a kernel. these are magic
# values that are documented in the multiboot standard. The bootloader will
# search for this signature in the first 8 KiB of the kernel file.
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

# the multiboot standard does not define the value of the stack pointer register
# (esp) and it is up to the kernel to provide a stack. 

# We will allocate room for a small stack of 16 KiB and creating a symbol at
# the top and the bottom. Stack grows downwads on x86. The stack is in its own
# section so it can be marked nobits, which means the kernel file is smaller
# because it does not contain an uninitialized stack. the stack on x86 mult be
# 16-byte aligned according to the System V ABI standard and de-facto extensions
# the compiler will assume the stack is properly aligned and failure to align
# the stack will result in undefined behaviour.
.section .bss
.align 16
stack_bottom:
.skip 16384 #16KiB
stack_top:

# the linker script specifies _start as the entry point to the kernel and the
# bootloader willjump to this position once the kernel has been loaded. it
# doesn't make sense to return from this function as the bootloader is gone.
.section .text
.global _start
.type _start, @function
_start:
        # the bootloader loaded us into 32-bit protected mode on x86 machine
        # interrupts are disabled, paging is disabled. the processor state
        # is defined as in the multiboot standard. the kernel has full control
        # of the CPU. kernel can only make use of hardware features and any code
        # it provides as part of itself. no security restrictions, no safeguards
        # no debugging. kernel has absolute power

        # to setup a stack we set the esp register to point to the top of our
        # stack (since it grows downwards on x86). Have to do it in assembly
        # since C cannot function without a stack.
        mov $stack_top, %esp

        # this is a good place to initialize crucial processor state before the
        # high-level kernel is entered. it's best to minimize the early
        # environment where crucial features are offline. note that the 
        # processor is not fully initialized yet: features such as floating 
        # point instructions and instruction set extensions are not initialized
        # yet. the GDT (Global descriptor table) should be loaded here. Paging
        # should be enabled here. C++ features such as global constructors and
        # exceptions will require runtime support to work as well.

        # Enter the high-level kernel. the ABI requires the stack is a 16-byte
        # aligned at the time of the call instruction (which afterwards pushes
        # the return pointer of size 4 Bytes). the stack was originally 16-byte
        # aligned above and we've since pushed a multiple of 16-bytes to the 
        # stack (pushed 0 so far) and thus alignment is preserved and the call
        # is well defined
        call kernel_main

        # if the system has nothing more to do, put the computer into an
        # infinite loop by:
        # 1. disabling interrupts with cli (clear interrupt enable in eflags).
        #    already disabled by the bootloader so unneccessary. unless we 
        #    return from kernel_main with interrupts enabled.
        # 2. Wait for the next interrupt to arrive with hlt (halt instruction)
        #    since they are disabled this will lock up the computer
        # 3. Jump to hlt if it wakes up from non-maskable interrupt or System
        #    management mode.
        cli
1:      hlt
        jmp 1b

# set the size of the _start symbol to the current location '.' minus its start.
# This is useful when debugging or when you imlement call tracing.
.size _start, . - _start
