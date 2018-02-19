[BITS 16]
	
    mov ax, 0x7f00          ; set stack segment
    mov ss, ax
    mov sp, 4096            ; set 4k stack

	mov ax, ds				; es:di = pointer to partition entry
	mov es, ax
	mov di, si

    mov ax, cs         		; set data segment
    mov ds, ax

    push ds
    push msg_1
	call print_string

    jmp $

    msg_1       db '[001] boot.bin loaded.', 13, 10
                db '[002] switching to protected mode ...', 13, 10, 0

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
	mov ah, 0x0E
.next:
	lodsb
	cmp al, 0
	je .done
	int 0x10
	jmp .next
.done:
	pop si
    pop ds
	pop bp
	ret 4