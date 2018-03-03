[BITS 32]

	global keyboard_isr

keyboard_isr:

    push eax
    in al,60h
    mov al,20h
    out 20h,al
    pop eax
    iret
