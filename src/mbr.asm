[BITS 16]
	
    mov ax, 0x0800                  ; set stack segment
    mov ss, ax
    mov sp, 4096                    ; set 4k stack
    mov ax, 0x07C0					; set data segment
    mov ds, ax

    push ds
    push msg_1
	call print_string

    mov bx, 0x01be                  ; set 1st partition entry

check_boot_flag:

    mov al, [bx]
    cmp al, 0x80
    je load_vbr
    cmp bx, 0x01ee
    je no_boot_partition
    add bx, 16                      ; set next partition entry
    jmp check_boot_flag

no_boot_partition:

    push ds
	push err_msg_1
	call print_string
    jmp $

load_vbr:

    push ds
    push msg_2
	call print_string

    ; build address packet structure

    push 0                  ; upper 32-bits of 48-bit starting LBAs
    push 0
    mov ax, [bx + 10]       ; lower 32-bits of 48-bit starting LBA
    push ax
    mov ax, [bx + 8]
    push ax
    push 0x07e0             ; buffer segment
    push 0                  ; buffer offset   
    push 1                  ; number of sectors to transfer   
    push 0x0010             ; always 0 | size of packet

    mov si, sp              ; set address packet structure
    push ds
    mov ax, ss
    mov ds, ax

    mov ah, 0x42
    int 0x13                ; read vbr sector
    pop ds
    jc load_vbr_failure

    add sp, 16              ; clear address packet structure

    push ds
    push msg_3
	call print_string

    mov si, bx              ; deliver ds:si to vbr code (partition entry)

    jmp 0x07e0:0x0000       ; jump to vbr

load_vbr_failure:

    ; no need to clear address packet structure as we are going to sleep anyway

    push ds
    push err_msg_2
	call print_string

    jmp $

    msg_1       db '[mbr] searching for boot partition ...', 13, 10, 0
    msg_2       db '[mbr] boot partition found.', 13, 10
                db '[mbr] loading vbr ...', 13, 10, 0
    msg_3       db '[mbr] vbr loaded.', 13, 10, 0
    err_msg_1   db '[mbr] can', 39, 't find a bootable partition.', 13, 10, 0
    err_msg_2   db '[mbr] boot failure (can', 39, 't load vbr).', 13, 10, 0

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