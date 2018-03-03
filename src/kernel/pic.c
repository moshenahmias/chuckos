#include "pic.h"
#include "common.h"

void init_pic()
{
    outb(PIC_1_CTRL, 0x11);
    outb(PIC_2_CTRL, 0x11);
 
    // ICW2
    outb(PIC_1_DATA, 0x20);
    outb(PIC_2_DATA, 0x28);

    // ICW3
    outb(PIC_1_DATA, 0x04);
    outb(PIC_2_DATA, 0x02);

    // ICW4
    outb(PIC_1_DATA, ICW4_8086);

    // disable
    outb(PIC_1_DATA, 0xff);
    outb(PIC_2_DATA, 0xff);
}

void irq_set_mask(unsigned char irq)
{
    unsigned short port;

    if (irq < 8)
    {
        port = PIC_1_DATA;
    }
    else
    {
        port = PIC_2_DATA;
        irq -= 8;
    }

    unsigned char value = inb(port) | (1 << irq);

    outb(port, value);        
}
 
void irq_clear_mask(unsigned char irq)
{
    unsigned short port;

    if (irq < 8)
    {
        port = PIC_1_DATA;
    }
    else
    {
        port = PIC_2_DATA;
        irq -= 8;
    }

    unsigned char value = inb(port) & ~(1 << irq);
    
    outb(port, value); 
}