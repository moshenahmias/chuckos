#include "kernel_screen.h"

int kmain()
{
    // __asm__ __volatile__("xchg %bx, %bx");

    clear_screen();

    int l = 0;

    print_str(0, l++, "     _           _           ", DEFAULT_COLOR);
    print_str(0, l++, " ___| |_ _ _ ___| |_ ___ ___ ", DEFAULT_COLOR);
    print_str(0, l++, "|  _|   | | |  _| '_| . |_ -|", DEFAULT_COLOR);
    print_str(0, l++, "|___|_|_|___|___|_,_|___|___|", DEFAULT_COLOR);
    l++;
    print_str(0, l++, "[002] Welcome to chuckos!", DEFAULT_COLOR);

    while(1);

    return 0;
}
