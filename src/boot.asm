[BITS 16]
	
    mov ax, 0x7f00                      ; set stack segment
    mov ss, ax
    mov sp, 4096                        ; set 4k stack

	mov ax, ds				            ; es:di = pointer to partition entry
	mov es, ax
	mov di, si

    ; todo - save es:di?

    mov ax, cs         		            ; set data segment
    mov ds, ax

    push ds
    push msg_1
	call print_string

    ; init gdt at 0x0800 (3 entries)

    mov ax, 0
    mov es, ax
    mov di, 0x800

    mov cx, 4                           ; null segment descriptor
    rep stosw

    mov [es:di], word 0xffff            ; code segment descriptor
    mov [es:di + 2], word 0x0000 
    mov [es:di + 4], word 0x9a00
    mov [es:di + 6], word 0x00cf

    add di, 8

    mov [es:di], word 0xffff            ; data segment descriptor
    mov [es:di + 2], word 0x0000 
    mov [es:di + 4], word 0x9200
    mov [es:di + 6], word 0x00cf

    cli                                 ; disable interrupts

    lgdt [gdt_ptr]                      ; set gdtr

    lidt [idt_ptr]                      ; set idtr
    
    mov ax, 0x2401                      ; enable A20
    int 0x15
    
    xchg bx, bx

    call test_a20

    xchg bx, bx

    jmp $

    msg_1       db '[001] boot.bin loaded.', 13, 10
                db '[001] init GDT and IDT ...', 13, 10, 0

    gdt_ptr     dw 23                   ; 3 descriptors
                dd 0x800                ; 0x0:0x800

    idt_ptr     dw 2048                 ; 256 descriptors (currently not initialized)
                dd 0                    ; 0x0:0x0

test_a20:
    push es
    push di

    mov ax, 0
    mov es, ax
    mov di, 0x0500
    mov [es:di], byte 0x00

    mov ax, 0xffff
    mov es, ax
    mov di, 0x0510
    mov [es:di], byte 0xff

    mov ax, 0
    mov es, ax
    mov di, 0x0500
    cmp [es:di], byte 0xff

    je .done

    mov ax, 1

.done:

    pop di
    pop es
    ret

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