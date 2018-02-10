[BITS 16]
org 0x3e                    ; offset inside vbr sector

    push ds
    push msg_1
	call print_string

    ; todo load boot.bin
    ; todo load kernel.bin

    jmp $

        msg_1     db '[vbr] loading kernel ...', 13, 10, 0   


; function  : next_cluster
; desc      : 
; param I   : id
; param II  : fat offset (in sectors)
; return	: next cluster in al
next_cluster:
	push bp
	mov bp, sp

	mov ax, [bp + 6]	; id




	pop bp
	ret 4

; function  : load_sector
; desc      : load a single sector
; param I   : lba upper two bytes
; param II  : lba lower two bytes
; param III : buffer segment
; param IV	: buffer offset
; return	: error code in ah (0 == no error)
load_sector:
	push bp
	mov bp, sp
	push ds
	push si

	; build address packet structure

    push 0                  ; upper 32-bits of 48-bit starting LBAs
    push 0
	mov ax, [bp + 10]		; lower 32-bits of 48-bit starting LBA
    push ax
    mov ax, [bp + 8]        
    push ax
	mov ax, [bp + 6]		; buffer segment
	push ax             	
	mov ax, [bp + 4]		; buffer offset
	push ax
	push 1                  ; number of sectors to transfer   
    push 0010h              ; always 0 | size of packet

    mov si, sp              ; set address packet structure
    mov ax, ss
    mov ds, ax

    mov ah, 42h
    int 13h                 ; read vbr sector (ah -> error code)

	add sp, 16              ; clear address packet structure
	pop si
	pop ds
	pop bp

	ret 8

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