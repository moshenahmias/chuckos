#ifndef KERNEL_PAGING_H
#define KERNEL_PAGING_H

#define F_PRESENT           0x001
#define F_READ_WRITE        0x002
#define F_USER_SUPERVISOR   0x004
#define F_WRITE_THROUGH     0x008
#define F_CACHE_DISABLED    0x010
#define F_ACCESSED          0x020
#define F_PAGE_SIZE         0x080
#define F_GLOBAL            0x100
#define F_DIRTY             0x040

void init_page_tables(unsigned int * pd);
void map_address(unsigned int * pd, void * virtual, void * physical, unsigned int flags);
void map_kernel_space(void * pd);
void load_page_directory(void * pd);
void enable_paging();

#endif /* KERNEL_PAGING_H */