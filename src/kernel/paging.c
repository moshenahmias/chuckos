#include "paging.h"

/*

kernel space mapping

virtual -> physical


0x00000000 -> 0x00000000
     16M (4096 pages)       DATA I
0x00ffffff -> 0x00ffffff

0x01000000 -> 0x01000000 
    256M (65536 pages)      DATA II
0x10ffffff -> 0x10ffffff

0x11000000 ->                           0x31000000 to 0xbfffffff
    2288M (‭585728‬ pages)    DATA III
0xdfffffff ->                           0x31000000 to 0xbfffffff

0xe0000000 -> 0x11000000
    256M (65536 pages)      HEAP
0xefffffff -> 0x20ffffff

0xf0000000 -> 0x21000000
    256M (65536 pages)      STACK
0xffffffff -> 0x30ffffff

*/

void init_page_tables(unsigned int * pd)
{
    unsigned int * pt = pd + 1024;

    for (int i = 0; i < 1024; i++)
    {
        pd[i] = ((unsigned int)pt) | F_PAGE_SIZE | F_READ_WRITE | F_PRESENT;
        
        for (int j = 0; j < 1024; j++)
        {
            pt[j] = 0;
        }

        pt += 1024;
    }
}

void map_address(unsigned int * pd, void * virtual, void * physical, unsigned int flags)
{
    unsigned int pde_i = (unsigned int)virtual >> 22;
    unsigned int pte_i = ((unsigned int)virtual >> 12) & 0x03ff;
    unsigned int * pt = (unsigned int *)(pd[pde_i] & 0xfffff000);
    pt[pte_i] = ((unsigned int)physical) | (flags & 0xFFF);
}

void map_kernel_space(void * pd)
{
    init_page_tables(pd);

    // data 1 + 2
    void * physical = 0x00000000;
    for (void * virtual = 0x00000000; virtual <= (void*)0x10fff000; virtual += 0x1000, physical += 0x1000)
    {
        map_address(pd, virtual, physical, F_PRESENT | F_READ_WRITE);
    }

    // todo data 3

    // heap
    physical = (void*)0x11000000;
    for (void * virtual = (void*)0xe0000000; virtual <= (void*)0xeffff000; virtual += 0x1000, physical += 0x1000)
    {
        map_address(pd, virtual, physical, F_PRESENT | F_READ_WRITE);
    }

    // stack
    physical = (void*)0x21000000;
    for (void * virtual = (void*)0xf0000000; virtual <= (void*)0xfffff000 && virtual != 0; virtual += 0x1000, physical += 0x1000)
    {
        map_address(pd, virtual, physical, F_PRESENT | F_READ_WRITE);
    }
}