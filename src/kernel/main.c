#include "main.h"
#include "common.h"
#include "screen.h"
#include "pic.h"
#include "idt.h"
#include "paging.h"

void kmain()
{
    // kernel page mapping
    void * pd = (void *)0x01000000;

    map_kernel_space(pd);
    load_page_directory(pd);
    enable_paging();

    // set stack pointer at 0xfffffffc
    __asm__ __volatile__(
        "movl $0xfffffffc, %esp\n\t
         movl 4(%ebp), %eax\n\t
         movl %eax, (%esp)");

    kmain_ii();

    while(1);
}

int kmain_ii()
{
    init_idt();
    init_pic();
    irq_clear_mask(IRQ1_KEYBOARD);      // enable keyboard irq
    enable_inerrupts();

    disable_cursor();
    clear_screen();

    int l = 0;

    print_str(0, l++, "     _           _           ", DEFAULT_COLOR);
    print_str(0, l++, " ___| |_ _ _ ___| |_ ___ ___ ", DEFAULT_COLOR);
    print_str(0, l++, "|  _|   | | |  _| '_| . |_ -|", DEFAULT_COLOR);
    print_str(0, l++, "|___|_|_|___|___|_,_|___|___|", DEFAULT_COLOR);
    l++;
    print_str(0, l++, "[002] Welcome to chuckos!", DEFAULT_COLOR);

    return 0;
}
