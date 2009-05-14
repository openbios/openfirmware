#include "io.h"

#include "test.h"
#include "defs.h"
#include "config.h"

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
    outb(0,0x92);
    outb(1,0x92);
//    wrmsr(0x51400017, 1, 0);
}
// int query_linuxbios(void)
// {
//     return 1;
// }
int query_pcbios(void)
{
    return 0;
}
// int query_ofw(void)
// {
//     return 1;
// }
