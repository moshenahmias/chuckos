#include "screen.h"
#include "common.h"

static char * const s_vram = (char *)0xb8000;

void disable_cursor()
{
	outb(0x3d4, 0x0a);
	outb(0x3d5, 0x20);
}

void update_cursor(int x, int y)
{
	unsigned short pos = y * SCREEN_WIDTH + x;
 
	outb(0x3d4, 0x0f);
	outb(0x3d5, (unsigned char) (pos & 0xff));
	outb(0x3d4, 0x0e);
	outb(0x3d5, (unsigned char) ((pos >> 8) & 0xff));
}

void clear_screen()
{
    for (int x = 0; x < SCREEN_WIDTH; x++)
    {
        for (int y = 0; y < SCREEN_HEIGHT; y++)
        {
            int pos = (x + (SCREEN_WIDTH * y)) * 2;
            s_vram[pos] = ' ';
            s_vram[pos + 1] = DEFAULT_COLOR;
        }
    }
}

void print_char(int x, int y, char ch, char color)
{
    x = x % SCREEN_WIDTH;
    y = y % SCREEN_HEIGHT;

    int pos = (x + (SCREEN_WIDTH * y)) * 2;

    s_vram[pos] = ch;
    s_vram[pos + 1] = color;
}

void shift_screen_up()
{
    for (int y = 1; y < SCREEN_HEIGHT; y++)
    {
        for (int x = 0; x < SCREEN_WIDTH; x++)
        {
            int posA = (x + (SCREEN_WIDTH * (y - 1))) * 2;
            int posB = (x + (SCREEN_WIDTH * y)) * 2;

            s_vram[posA] = s_vram[posB];
            s_vram[posA + 1] = s_vram[posB + 1];

            if (y == SCREEN_HEIGHT - 1)
            {
                s_vram[posB] = ' ';
                s_vram[posB + 1] = DEFAULT_COLOR;
            }
        }
    }
}

void print_str(int x, int y, char * str, char color)
{
    x = x % SCREEN_WIDTH;
    y = y % SCREEN_HEIGHT;

    while (*str != '\0')
    {
        if (*str == '\r')
        {
            x = 0;
        }
        else if (*str == '\n')
        {
            if (y + 1 == SCREEN_HEIGHT)
            {
                shift_screen_up();
            }
            else
            {
                y++;
            }
        }
        else
        {
            print_char(x, y, *str, color);
            x++;

            if (x == SCREEN_WIDTH)
            {
                x = 0;

                if (y + 1 == SCREEN_HEIGHT)
                {
                    shift_screen_up();
                }
                else
                {
                    y++;
                }
            }
        }

        str++;
    }
}