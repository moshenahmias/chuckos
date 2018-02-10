[BITS 16]
org 0x3e                    ; offset inside vbr sector

    push ds
    push msg_1
	call print_string

    ; todo load boot.bin
    ; todo load kernel.bin

    jmp $

        msg_1     db '[vbr] loading kernel ...', 13, 10, 0   

; function  : print_string
; desc      : print string to screen
; param I   : string segment
; param II  : string offset
print_string:
	push bp
	mov bp, sp
    push ds
    mov ax, [bp + 6]    ; string segment
    mov ds, ax
	push si
	mov si, [bp + 4]    ; string offset
	mov ah, 0Eh
.next:
	lodsb
	cmp al, 0
	je .done
	int 10h
	jmp .next
.done:
	pop si
    pop ds
	pop bp
	ret 4