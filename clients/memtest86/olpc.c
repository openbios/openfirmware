#include "msr.h"

void poll_errors(void)
{
}
void set_ecc_polling(int val)
{
}
void show_spd(void)
{
}
void get_menu(void)
{
}
void find_controller(void)
{
}
int pci_init(void)
{
    return 0;
}
void warm_start()
{
    wrmsr(0x51400017, 1, 0);
}
int query_linuxbios(void)
{
    return 0;
}
int query_pcbios(void)
{
    return 0;
}
unsigned int lfb_addr()
{
    return 0xfd000000;
}
