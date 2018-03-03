#ifndef KERNEL_COMMON_H
#define KERNEL_COMMON_H

#define BOCHS_MAGIC_BREAKPOINT __asm__ __volatile__("xchg %bx, %bx");

static inline void set_stack_pointer(void * p)
{
     __asm__ __volatile__( "movl %0, %%esp" : : "a"(p) );
}

static inline unsigned char inb(unsigned short port)
{
    unsigned char value;

    __asm__ __volatile__( "inb %1, %0" : "=a"(value) : "Nd"(port) );
    
    return value;
}

static inline void outb(unsigned short port, unsigned char value)
{
     __asm__ __volatile__( "outb %0, %1" : : "a"(value), "Nd"(port) );
}

static inline void disable_inerrupts()
{
    __asm__ __volatile__("cli");
}

static inline void enable_inerrupts()
{
    __asm__ __volatile__("sti");
}


#endif /* KERNEL_COMMON_H */