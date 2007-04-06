/* Memtest86 SPD extension 
 * added by Reto Sonderegger, 2004, reto@swissbit.com
 * 
 * Released under version 2 of the Gnu Puclic License
 */
 
#include "test.h"
#include "io.h"
#include "pci.h"
#include "msr.h"
#include "screen_buffer.h"
#include "ega.h"

#define SMBHSTSTS smbusbase
#define SMBHSTCNT smbusbase + 2
#define SMBHSTCMD smbusbase + 3
#define SMBHSTADD smbusbase + 4
#define SMBHSTDAT smbusbase + 5

extern void wait_keyup();
extern char save[2][SPD_H][SPD_W];

int smbdev, smbfun;
unsigned short smbusbase;
unsigned char spd[256];
char s[] = {'/', 0, '-', 0, '\\', 0, '|', 0};	

void spd_popup()
{
	int i, j;
	
	for (i=SPD_Y; i<SPD_Y + SPD_H; i++) {
		for (j=SPD_X; j<SPD_X + SPD_W; j++) {
			/* Save screen */
		        save[0][i-SPD_Y][j-SPD_X] = get_ega_char(i, j);
			save[1][i-SPD_Y][j-SPD_X] = get_ega_color(i, j);
			/* Change Background to black */
			set_ega_char_color (i, j, ' ', 0x07);
			set_scrn_buf(i, j, ' ');
		}
	}
	tty_print_region(SPD_Y, SPD_X, SPD_Y+SPD_H, SPD_X+SPD_W);
}

void spd_popdown()
{
	int i, j;

	for (i=SPD_Y; i<SPD_Y + SPD_H; i++) {
		for (j=SPD_X; j<SPD_X + SPD_W; j++) {
			/* Restore screen */
		        set_ega_char_color(i, j, save[0][i-SPD_Y][j-SPD_X],
				           save[1][i-SPD_Y][j-SPD_X]);
			set_scrn_buf(i, j, save[0][i-SPD_Y][j-SPD_X]);
		}
	}
	tty_print_region(SPD_Y, SPD_X, SPD_Y+SPD_H, SPD_X+SPD_W);
}

static void ich5_get_smb(void)
{
    unsigned long x;
    int result;
    result = pci_conf_read(0, smbdev, smbfun, 0x20, 2, &x);
    if (result == 0) smbusbase = (unsigned short) x & 0xFFFE;
}

unsigned char ich5_smb_read_byte(unsigned char adr, unsigned char cmd)
{
    int l1, h1, l2, h2;
    unsigned long long t;
    __outb(0x1f, SMBHSTSTS);			// reset SMBus Controller
    __outb(0xff, SMBHSTDAT);
    while(__inb(SMBHSTSTS) & 0x01);		// wait until ready
    __outb(cmd, SMBHSTCMD);
    __outb((adr << 1) | 0x01, SMBHSTADD);
    __outb(0x48, SMBHSTCNT);
    rdtsc(l1, h1);
    cprint(SPD_Y, SPD_X + 16, s + cmd % 8);	// progress bar
    while (!(__inb(SMBHSTSTS) & 0x02)) {	// wait til command finished
	rdtsc(l2, h2);
	t = ((h2 - h1) * 0xffffffff + (l2 - l1)) / v->clks_msec;
	if (t > 10) break;			// break after 10ms
    }
    return __inb(SMBHSTDAT);
}

static int ich5_read_spd(int dimmadr)
{
    int x;
    spd[0] = ich5_smb_read_byte(0x50 + dimmadr, 0);
    if (spd[0] == 0xff)	return -1;		// no spd here
    for (x = 1; x < 256; x++) {
	spd[x] = ich5_smb_read_byte(0x50 + dimmadr, (unsigned char) x);
    }
    return 0;
}
    
struct pci_smbus_controller {
    unsigned vendor;
    unsigned device;
    char *name;
    void (*get_adr)(void);
    int (*read_spd)(int dimmadr);
};

static struct pci_smbus_controller smbcontrollers[] = {
{0x8086, 0x24D3, "Intel ICH5", ich5_get_smb, ich5_read_spd},
{0x8086, 0x266A, "Intel ICH6", ich5_get_smb, ich5_read_spd},
{0x8086, 0x24C3, "Intel ICH4", ich5_get_smb, ich5_read_spd},
{0, 0, "", NULL, NULL}
};

int find_smb_controller(void)
{
    int i = 0;
    unsigned long valuev, valued;
    for (smbdev = 0; smbdev < 32; smbdev++) {
	for (smbfun = 0; smbfun < 8; smbfun++) {
	    pci_conf_read(0, smbdev, smbfun, 0, 2, &valuev);
	    if (valuev != 0xFFFF) {					// if there is something look what's it..
		for (i = 0; smbcontrollers[i].vendor > 0; i++) {	// check if this is a known smbus controller
		    if (valuev == smbcontrollers[i].vendor) {
			pci_conf_read(0, smbdev, smbfun, 2, 2, &valued);	// read the device id
			if (valued == smbcontrollers[i].device) {
			    return i;
			}
		    }
		}
	    }	
	}
    }
    return -1;
}
	    
	    
void show_spd(void)
{
    int index;
    int i, j;
    int flag = 0;
    spd_popup();
    wait_keyup();
    index = find_smb_controller();
    if (index == -1) {
	cprint(SPD_Y, SPD_X+1, "SMBus Controller not known");
	while (!get_key());
	wait_keyup();
	spd_popdown();
	return;
    }
    else cprint(SPD_Y, SPD_X+1, "SPD Data: Slot");    
    smbcontrollers[index].get_adr();
    for (j = 0; j < 16; j++) {
	if (smbcontrollers[index].read_spd(j) == 0) {
	    dprint(SPD_Y, SPD_X + 15, j, 2, 0);		
    	    for (i = 0; i < 256; i++) {
		hprint2(2 + SPD_Y + i / 16, 3 + SPD_X + (i % 16) * 3, spd[i], 2);
	    }
	    flag = 0;
    	    while(!flag) {
		if (get_key()) flag++;
	    }
	    wait_keyup();
	}
    }
    spd_popdown();
}

