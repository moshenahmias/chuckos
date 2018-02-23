int kmain()
{
    //*((int*)0xb8000)=0x07 69 07 48;

    char * p = 0xb8000;

    p[0] = 0x40;
    p[1] = 0x07;
    p[2] = 0x3c;
    p[3] = 0x08;

    while(1);

    return 0;
}
