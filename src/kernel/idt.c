#include "idt.h"   

static idt_descriptor_t * s_idt = 0;

extern __attribute__((interrupt)) void keyboard_isr(struct interrupt_frame* frame);

__attribute__((interrupt)) void do_nothing_isr(struct interrupt_frame* frame)
{

}

void init_idt()
{
    for (int i = 0; i < IDT_SIZE; i++)
    {
        set_idt_descriptor(i, do_nothing_isr, 0x0008, 0x8e);
    }

    set_idt_descriptor(0x21, keyboard_isr, 0x0008, 0x8e);
}

void set_idt_descriptor(unsigned char id, void * isr, unsigned short selector, unsigned char attributes)
{
    s_idt[id].offset_low = (unsigned short)((unsigned int)isr & 0x0000ffff);
    s_idt[id].offset_high = (unsigned short)((unsigned int)isr >> 16);
    s_idt[id].selector = selector;
    s_idt[id].unused = 0;
    s_idt[id].attributes = attributes;
}