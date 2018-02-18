[BITS 16]

	jmp short 0x003c
	nop

	times 62-($-$$) db 0	; BPB area (59 bytes)

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
	push dx
	xor ah, ah
	mov al, [16]			; al = number of fat tables
	mov bx, [22]			; bx = number of sectors per fat
	mul bx					; dxax = ax * bx = number of sectors in all fat tables
	add ax, [bp - 4]		; ax = root dir lba (lower)
	push 0
	mov si, sp
	setc [si]
	pop bx	
    add bx, dx
	add bx, [bp - 2]		; bx = root dir lba (upper)
	pop dx

	push bx					; [bp - 6] = root dir lba (upper)
	push ax					; [bp - 8] = root dir lba (lower)

	; calc data lba

	mov cx, [17]			; cx = number of directory entries
	shr cx, 4				; cx = number of sectors in root dir (cx div 16)
	
	push cx					; [bp - 10] = number of sectors in root dir
	
	add ax, cx				; ax = data lba (lower)
	push 0
	mov si, sp
	setc [si]
	pop cx
	add bx, cx				; bx = data lba (upper)

	push bx					; [bp - 12] = data lba (upper)
	push ax					; [bp - 14] = data lba (lower)

	; calc vbr part 2 lba
	mov bx, 1
	add bx, [es:di + 8]		; bx = vbr part 2 lba (lower)
    push 0
	mov si, sp
	setc [si]
	pop ax
    add ax, [es:di + 10]	; ax = vbr part 2 lba (upper)
	
	; load next boot sector
	push ax
	push bx
	push ds
	push 0x0200
	call load_sector

	cmp ah, 0
	je vbr_part_2

    push ds
    push err_msg_1
	call print_string

	jmp $

	msg_1     	db '[vbr] loading part II ...', 13, 10, 0  
	err_msg_1   db '[vbr] failed loading part II', 13, 10, 0

; function  : load_cluster
; desc      : load cluster by its id
; param I   : cluster id
; param II	: sectors per cluster
; param III : data lba upper word
; param IV	: data lba lower word
; param V 	: buffer segment
; param VI	: buffer offset
; return	: es:di = last loaded sector
;			  error code in ah (0 == no error)
load_cluster:
	push bp
	mov bp, sp
	push bx
	push cx
	push si

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
	mov di, [bp + 4]	; di = buffer offset

.load:

	push cx
	push ax
	push es	
	push di
	call load_sector	; load cluster sector

	cmp ah, 0
	jne .done			; failed to load sector

	dec bx
	jz .done			; finished

	inc ax				; calc next lba
	push 0
	mov si, sp
	setc [si]
	pop si
	add cx, si

	add di, 512			; inc buffer pointer

	jnc .load			; no overflow

	mov si, es
	add si, 0x1000
	mov es, si			; next segment

	jmp .load			; load next sector

.done:

	pop si
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
	ret 6

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
    mov ax, [bp + 6]   		; string segment
    mov ds, ax
	push si
	mov si, [bp + 4]  		; string offset
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

	times 510-($-$$) db 0
	dw 0xaa55				; boot signature

vbr_part_2:

    push ds
    push msg_2
	call print_string

	; load boot.bin

	push ds					; file name segment
	push boot_file			; file name offset
	mov ax, [bp - 2]		
	push ax					; fat lba upper word
	mov ax, [bp - 4]
	push ax					; fat lba lower word
	mov ax, [bp - 6]
	push ax					; root dir lba upper word
	mov ax, [bp - 8]
	push ax					; root dir lba lower word
	mov ax, [bp - 10]
	push ax					; total sectors in dir
	mov ax, [bp - 12]
	push ax					; data lba upper word
	mov ax, [bp - 14]
	push ax					; data lba lower word
	
	xor ax, ax
	mov al, [13]
	push ax					; sectors per cluster

	push 0x0820				; buffer segment
	push 0					; buffer offset
	call load_file

	add sp, 14				; clear saved lba offsets and other data from stack
	
	jmp $

    msg_2     	db '[vbr] part II loaded.', 13, 10
 	     		db '[vbr] loading boot.bin ...', 13, 10, 0  
	boot_file  	db 'IMDISK~1EXE' 



; function   : load_file
; desc       : load a file from root directory
; param I    : file name segment
; param II   : file name offset
; param III  : fat lba upper word
; param IV 	 : fat lba lower word
; param V	 : root dir lba upper word
; param VI	 : root dir lba lower word
; param VII	 : total sectors in dir
; param VIII : data lba upper word
; param IX	 : data lba lower word
; param X	 : sectors per cluster
; param XI   : buffer segment
; param XII	 : buffer offset
; return	 : error code in ah (0 == no error)
load_file:
	push bp
	mov bp, sp
	push bx
	push cx
	push es
	push di

	push dx

	; seach for first cluster
	mov ax, [bp + 26]
	push ax
	mov ax, [bp + 24]
	push ax
	mov ax, [bp + 18]
	push ax
	mov ax, [bp + 16]
	push ax
	mov ax, [bp + 14]
	push ax
	call get_file_data	

	pop dx

	mov es, [bp + 6]		; es:di = pointer to buffer
	mov di, [bp + 4]

.next:

	cmp ah, 0
	jne .done

	cmp bx, 0xfff8
	jae .done				; end of chain

	cmp bx, 0xfff7
	je .bad_cluster			; bad cluster found

	cmp bx, 2
	jb .invalid_cluster_id	; invalid id (< 2)

	; load cluster # bx to es:di

	push bx
	mov ax, [bp + 8]
	push ax
	mov ax, [bp + 12]
	push ax
	mov ax, [bp + 10]
	push ax
	push es
	push di
	call load_cluster		; es:di = last loaded sector

	cmp ah, 0
	jne .done

	; get the next cluster in chain

	push bx
	mov ax, [bp + 22]
	push ax
	mov ax, [bp + 20]
	push ax
	call next_cluster

	add di, 512

	jnc .next			; no overflow

	mov cx, es
	add cx, 0x1000
	mov es, cx			; next segment

	jmp .next

.invalid_cluster_id:

	mov ah, 0xdd

.bad_cluster:

	mov ah, 0xee

.done:

	pop di
	pop es
	pop cx
	pop bx
	pop bp
	ret 24

; function  : get_file_data
; desc      : finds data about the file
; param I   : file name segment
; param II  : file name offset
; param III	: root dir lba upper word
; param VI	: root dir lba lower word
; param V	: total sectors in dir
; return	: bx = cluster id (0 < bx < 2 means file cannot be found at root dir)
;			  cxdx = file size
;			  al = attributes
;			  error code in ah (0 == no error)
get_file_data:
	push bp
	mov bp, sp
	sub sp, 512				; allocate sector space at (bp - 512)
	push si
	push es
	push di

	mov cx, [bp + 4]		; cx = total sectors in dir

.search_sector:

	mov ax, [bp + 8]		; ax = sector upper
	mov bx, [bp + 6]		; bx = sector lower

	push ax					; push load sector parameters
	push bx
	push ss
	mov ax, bp
	sub ax, 512
	push ax
	
	inc bx				; calc next sector (for next iteration)			
	push 0
	mov si, sp
	setc [si]
	pop si
    add ax, si
	mov [bp + 8], ax	; [bp + 8] = next sector upper
	mov [bp + 6], bx	; [bp + 6] = next sector lower

	call load_sector	; load

	cmp ah, 0
	jne .done				; failed to load sector

	; sector loaded

	; iterate sector entries
	mov si, bp
	sub si, 512				; si = first entry offset
	mov bl, 16				; bl = number of entries in sector

.scan_entry:

	mov ah, [ss:si]			; check if empty
	cmp ah, 0
	jz .not_found			; no more entries

	mov al, [ss:si + 11]	; al = file attribues
	cmp al, 0x0f			; check if long file name entry
	je .next_entry			; skip long file name entry
	test al, 0x18			; check if dir or volume
	jnz .next_entry			; skip dir or volume entry

	; compare file name
	mov ax, [bp + 12]
	push ax
	mov ax, [bp + 10]
	push ax
	push ss
	push si
	push 11
	call compare_bytes

	cmp ax, 0
	jne .next_entry			; if ax = 0 the file was found

.found:

	xor ah, ah				; ah = no error
	mov al, [ss:si + 11]	; al = attributes
	mov bx, [ss:si + 26]	; bx = first cluster id
	mov dx, [ss:si + 28]	; dx = size of file (lower)
	mov cx, [ss:si + 30]	; cx = size of file (upper)

	jmp .done

.next_entry:

	add si, 32				; si = next entry offset
	dec bl
	jnz .scan_entry

	; scanned last entry

	dec cx
	jnz .search_sector

.not_found:

	xor ah, ah
	xor bx, bx

.done:

	pop di
	pop es
	pop si
	add sp, 512			; clear allocated sector space
	pop bp
	ret 10


; function  : compare_bytes
; desc      : compare two byte arrays
; param I   : 1st array segment
; param II  : 1st array offset
; param III	: 2st array segment
; param VI	: 2st array offset
; param V	: bytes count
; return	: ax = 0 iff equal
compare_bytes:
	push bp
	mov bp, sp
	push ds
	push es
	push di
	push si
	push cx

 	mov es, [bp + 12]		; es = 1st array segment
	mov di, [bp + 10]		; di = 1st array offset
	mov ds, [bp + 8]		; ds = 2st array segment
	mov si, [bp + 6]		; si = 2st array offset
	mov cx, [bp + 4]		; cx = bytes count

.next_char:

	cmp cx, 0
	je .done				; all chars are equal

	mov al, [es:di]			; get chars
	mov ah, [ds:si]

	cmp al, ah				; compare chars
	jne .done				; not equal

	inc di					; next char
	inc si
	dec cx
	jmp .next_char

.done:

	mov ax, cx

	pop cx
	pop si
	pop di
	pop es
	pop ds
	pop bp
	ret 10

	times 1024-($-$$) db 0