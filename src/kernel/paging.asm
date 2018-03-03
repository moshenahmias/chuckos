[BITS 32]

    global load_page_directory
    global enable_paging

load_page_directory:

    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]
    mov cr3, eax
    pop ebp
    ret 4

enable_paging:

    push ebp
    mov ebp, esp
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax
    pop ebp
    ret