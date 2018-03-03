#ifndef KERNEL_IDT_H
#define KERNEL_IDT_H

#define IDT_SIZE 256

typedef struct idt_descriptor
{
    unsigned short offset_low;
    unsigned short selector;
    unsigned char unused;
    unsigned char attributes;
    unsigned short offset_high;
} idt_descriptor_t;

void init_idt();
void set_idt_descriptor(unsigned char id, void * isr, unsigned short selector, unsigned char attributes);

#endif /* KERNEL_IDT_H */