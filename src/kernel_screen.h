#ifndef KERNEL_SCREEN_H
#define KERNEL_SCREEN_H

#define SCREEN_HEIGHT       25
#define SCREEN_WIDTH        80
#define DEFAULT_COLOR       0x07

void clear_screen();
void print_char(int x, int y, char ch, char color);
void shift_screen_up();
void print_str(int x, int y, char * str, char color);

#endif /* KERNEL_SCREEN_H */