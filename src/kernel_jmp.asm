[BITS 32]

	global _start
	extern kmain

_start:

    call kmain          ; start kernel
    nop
    nop
    nop
    jmp _start

