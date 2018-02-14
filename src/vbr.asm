[BITS 16]
org 0x3e                    ; offset inside vbr sector

	mov ax, ds				; es:di = pointer to partition entry
	mov es, ax
	mov di, si

    mov ax, cs         		; set data segment
    mov ds, ax

    push ds
    push msg_1
	call print_string

	mov bp, sp

	; calc fat lba
	mov bx, [14]			; bx = volume reserved sectors (fat offset)
	add bx, [es:di + 8]		; bx = partition lba (lower) + reserved sectors = fat lba (lower)
    push 0
	mov si, sp
	setc [si]
	pop ax	
    add ax, [es:di + 10]	; ax = fat lba (upper)

	push ax					; [bp - 2] = fat lba (upper)
	push bx					; [bp - 4] = fat lba (lower)

	; calc root dir lba
	
	xor ah, ah
	mov al, [16]			; al = number of fat tables
	mov bx, [22]			; bx = number of sectors per fat
	mul bx					; dxax = ax * bx = number of sectors in all fat tables
	add ax, [bp - 4]		; ax = root dir lba (lower)
	push 0
	mov si, sp
	setc [si]
	pop bx	
    add bx, [bp - 2]		; bx = root dir lba (upper)

	push bx					; [bp - 6] = root dir lba (upper)
	push ax					; [bp - 8] = root dir lba (lower)

	; calc data lba

	mov cx, [17]			; cx = number of directory entries
	shr cx, 4				; cx = number of sectors in root dir (cx div 16)
	add ax, cx				; ax = data lba (lower)
	push 0
	mov si, sp
	setc [si]
	pop cx
	add bx, cx				; bx = data lba (upper)

	push bx					; [bp - 10] = data lba (upper)
	push ax					; [bp - 12] = data lba (lower)

	; search for boot.bin

	; load boot bin

	; clear local vars

	; jump

  
    jmp $

        msg_1     db '[vbr] loading kernel ...', 13, 10, 0   



; function  : find_first_cluster
; desc      : finds the first cluster of a file
; param I   : pointer to file name
; param II	: root dir lba upper word
; param III : root dir lba lower word
; param IV	: total sectors in dir
; return	: cluster id in bx
;			  error code in ah (0 == no error)
find_first_cluster:
	push bp
	mov bp, sp

	pop bp
	ret 8

; function  : load_cluster
; desc      : load cluster by its id
; param I   : cluster id
; param II	: sectors per cluster
; param III : data lba upper word
; param IV	: data lba lower word
; param V 	: buffer segment
; param VI	: buffer offset
; return	: error code in ah (0 == no error)
load_cluster:
	push bp
	mov bp, sp
	push bx
	push cx
	push dx
	push si
	push es
	push di

	mov cx, dx
	mov ax, [bp + 14]	; ax = cluster id
	sub ax, 2			; first cluster is cluster 2
	mov bx, [bp + 12]	; bx = sectors per cluster
	mul bx				; dxax = ax * bx
	add ax, [bp + 8]	; ax = ax + data lba lower word
	push 0
	mov si, sp
	setc [si]
	pop bx				; bx = previous add carry
	add dx, [bp + 10]	; dx = dx + data lba upper word
	add dx, bx			; dx = dx + carry
	xchg cx, dx			; cx = dx + carry

						; ax = cluster lba lower
						; cx = cluster lba upper

	mov bx, [bp + 12]	; bx = sectors per cluster
	mov es, [bp + 6]	; es = buffer segment
	mov si, [bp + 4]	; si = buffer offset

.load:

	push cx
	push ax
	push es	
	push si
	call load_sector	; load cluster sector

	cmp ah, 0
	jne .done			; failed to load sector

	dec bx
	jz .done			; finished

	inc ax				; calc next lba
	push 0
	mov di, sp
	setc [di]
	add cx, di

	add si, 512			; inc buffer pointer

	jmp .load			; load next sector

.done:

	pop di
	pop es
	pop si
	pop dx
	pop cx
	pop bx
	pop bp
	ret 12

; function  : next_cluster
; desc      : get the next cluster in chain
; param I   : current cluster id
; param II  : fat lba upper word
; param III : fat lba lower word
; return	: next cluster in bx or the following code:
;			  	>= 0xFFF8 - end of chain
;			  	== 0xFFF7 - bad cluster
;			  error code in ah, 0 means no error
next_cluster:
	push bp
	mov bp, sp
	push cx
	push dx
	push di
	push si
	push es

	mov cx, dx			; cx = drive id
	mov ax, [bp + 8]	; id
	mov dx, 0     
	mov bx, 256
	div bx				; ax = sector offset inside fat
	add dx, dx			; cx = byte offset in sector, dx = drive id
	xchg cx, dx
	
	mov bx, [bp + 4]	; bx = fat lba lower
	add bx, ax			; bx = sector lba (low word)
	
	push 0
	mov si, sp
	setc [si]
	pop ax				
	add ax, [bp + 6]	; ax = sector lba (high word)

	sub sp, 512			; allocate sector space
	mov di, sp			; pointer to allocation (es:di)
	mov si, ss
	mov es, si

	push ax
	push bx
	push es
	push di
	call load_sector	; load next id sector

	cmp ah, 0
	jne .done			; failed to load sector

	add di, cx
	mov bx, [es:di]		; bx = next cluster id

.done:

	add sp, 512
	pop es
	pop si
	pop di
	pop dx
	pop cx
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
    push 0x0010             ; always 0 | size of packet

    mov si, sp              ; set address packet structure
    mov ax, ss
    mov ds, ax

    mov ah, 0x42
    int 0x13                ; read vbr sector (ah -> error code)

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