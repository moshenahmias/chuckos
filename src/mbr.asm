[BITS 16]
	
    mov ax, 0800h                   ; set stack segment
    mov ss, ax
    mov sp, 4096                    ; set 4k stack
    mov ax, 07C0h					; set data segment
    mov ds, ax

    push ds
    push msg_1
	call print_string

    mov bx, 01beh                   ; set 1st partition entry

check_boot_flag:

    mov al, [bx]
    cmp al, 80h
    je load_vbr
    cmp bx, 01eeh
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
    push 07e0h              ; buffer segment
    push 0                  ; buffer offset   
    push 1                  ; number of sectors to transfer   
    push 0010h              ; always 0 | size of packet

    mov si, sp              ; set address packet structure
  
    push ds
    mov ax, ss
    mov ds, ax

    mov ah, 42h
    int 13h                 ; read vbr sector
    pop ds
    jc load_vbr_failure

    add sp, 16              ; clear address packet structure

    push ds
    push msg_3
	call print_string

    mov ax, 07e0h           ; jump to vbr
    mov ds, ax
    jmp 512

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