/* init.c - MemTest-86  Version 3.3
 *
 * Released under version 2 of the Gnu Public License.
 * By Chris Brady
 * ----------------------------------------------------
 * MemTest86+ V1.11 Specific code (GPL V2.0)
 * By Samuel DEMEULEMEESTER, sdemeule@memtest.org
 * http://www.x86-secret.com - http://www.memtest.org
 */

#include "test.h"
#include "defs.h"
#include "config.h"
#include "controller.h"
#include "pci.h"
#include "io.h"
#include "ega.h"

extern short memsz_mode;
extern short firmware;

int l1_cache=0, l2_cache=0;
struct cpu_ident cpu_id;
ulong st_low, st_high;
ulong end_low, end_high;
ulong cal_low, cal_high;
ulong extclock;

ulong memspeed(ulong src, ulong len, int iter, int type);
static void cpu_type(void);
static void cacheable(void);
static int cpuspeed(void);

static void display_init(void)
{
	int i;

	serial_echo_init();
        serial_echo_print("[14;24r"); /* Set scroll area row 7-23 */
        serial_echo_print("[H[2J");   /* Clear Screen */
        serial_echo_print("[37m[44m");
        serial_echo_print("[0m");
        serial_echo_print("[37m[44m");

	ega_init();

	/* Clear screen & set background to blue */
        int j;
        for (i=0; i<24; i++) {
	  for (j=0; j<80; j++) {
	    set_ega_char_color(i, j, ' ', 0x17);
	  }
	}

	/* Make the name background red */
        for (i=0; i<TITLE_WIDTH; i++) {
	  set_ega_color(0, i, 0x47);
	}

	cprint(0, 0, "      Memtest-86 v3.3       ");

	/* Do reverse video for the bottom display line */
	for (i=0; i<80; i++) {
	  set_ega_char_color(24, i, ' ', 0x71);
	}

        serial_echo_print("[0m");
}

/*
 * Initialize test, setup screen and find out how much memory there is.
 */
void init(void)
{
	int i;

	outb(0x8, 0x3f2);  /* Kill Floppy Motor */

	/* Turn on cache */
	set_cache(1);

	/* Setup the display */
	display_init();

	/* Determine the memory map */
	if ((firmware == FIRMWARE_UNKNOWN) && 
		(memsz_mode != SZ_MODE_PROBE)) {
		if (query_linuxbios()) {
			firmware = FIRMWARE_LINUXBIOS;
		}
		else if (query_pcbios()) {
			firmware = FIRMWARE_PCBIOS;
		}
	}

	mem_size();

	/* setup pci */
	pci_init();

	v->test = 0;
	v->testsel = -1;
	v->msg_line = LINE_SCROLL-1;
	v->scroll_start = v->msg_line * 160;

	cprint(LINE_CPU+1, 0, "L1 Cache: Unknown ");
	cprint(LINE_CPU+2, 0, "L2 Cache: Unknown ");
	cprint(LINE_CPU+3, 0, "Memory  : ");
	aprint(LINE_CPU+3, 10, v->test_pages);
	cprint(LINE_CPU+4, 0, "Chipset : ");

	/*
	 * Need to find out CPU type before seting up pci. This is
	 * because AMD Opterons dont have a host bridge on dev 0.
	 */
	cpu_type();

	/* setup pci */
	pci_init();

	/* Find the memory controller */
	find_controller();

	if (v->rdtsc) {
		cacheable();
		cprint(LINE_TIME, COL_TIME+4, ":  :");
	}
	cprint(0, COL_MID,"Pass   %");
	cprint(1, COL_MID,"Test   %");
	cprint(2, COL_MID,"Test #");
	cprint(3, COL_MID,"Testing: ");
	cprint(4, COL_MID,"Pattern: ");
	cprint(LINE_INFO-2, 0, " WallTime   Cached  RsvdMem   MemMap   Cache  ECC  Test  Pass  Errors ECC Errs");
	cprint(LINE_INFO-1, 0, " ---------  ------  -------  --------  -----  ---  ----  ----  ------ --------");
	cprint(LINE_INFO, COL_TST, "Std");
	cprint(LINE_INFO, COL_PASS, "    0");
	cprint(LINE_INFO, COL_ERR, "     0");
	cprint(LINE_INFO+1, 0, " -----------------------------------------------------------------------------");

	for(i=0; i < 5; i++) {
		cprint(i, COL_MID-2, "| ");
	}
	footer();
	v->printmode=PRINTMODE_ADDRESSES;
	v->numpatn=0;
	find_ticks();
}

#define FLAT 0

static unsigned long mapped_window = 1;
void paging_off(void)
{
	if (!v->pae)
		return;
	mapped_window = 1;
	__asm__ __volatile__ (
		/* Disable paging */
		"movl %%cr0, %%eax\n\t"
		"andl $0x7FFFFFFF, %%eax\n\t"
		"movl %%eax, %%cr0\n\t"
		/* Disable pae  & pse */
		"movl %%cr4, %%eax\n\t"
    		"and $0xCF, %%al\n\t"
    		"movl %%eax, %%cr4\n\t"
		:
		:
		: "ax"
		);
}

static void paging_on(void *pdp)
{
	if (!v->pae)
		return;
	__asm__ __volatile__(
		/* Load the page table address */
		"movl %0, %%cr3\n\t"
		/* Enable pae */
		"movl %%cr4, %%eax\n\t"
		"orl $0x00000020, %%eax\n\t"
		"movl %%eax, %%cr4\n\t"
		/* Enable paging */
		"movl %%cr0, %%eax\n\t"
		"orl $0x80000000, %%eax\n\t"
		"movl %%eax, %%cr0\n\t"
		:
		: "r" (pdp)
		: "ax"
		);
}

int map_page(unsigned long page)
{
	unsigned long i;
	struct pde {
		unsigned long addr_lo;
		unsigned long addr_hi;
	};
	extern unsigned char pdp[];
	extern struct pde pd2[];
	unsigned long window = page >> 19;
	if (FLAT || (window == mapped_window)) {
		return 0;
	}
	if (window == 0) {
		return 0;
	}
	if (!v->pae || (window >= 32)) {
		/* Fail either we don't have pae support
		 * or we want an address that is out of bounds
		 * even for pae.
		 */
		return -1;
	}
	/* Compute the page table entries... */
	for(i = 0; i < 1024; i++) {
		pd2[i].addr_lo = ((window & 1) << 31) + ((i & 0x3ff) << 21) + 0xE3;
		pd2[i].addr_hi = (window >> 1);
	}
	paging_off();
	if (window > 1) {
		paging_on(pdp);
	}
	mapped_window = window;
	return 0;
}

void *mapping(unsigned long page_addr)
{
	void *result;
	if (FLAT || (page_addr < 0x80000)) {
		/* If the address is less that 1GB directly use the address */
		result = (void *)(page_addr << 12);
	}
	else {
		unsigned long alias;
		alias = page_addr & 0x7FFFF;
		alias += 0x80000;
		result = (void *)(alias << 12);
	}
	return result;
}

void *emapping(unsigned long page_addr)
{
	void *result;
	result = mapping(page_addr -1);
	/* The result needs to be 256 byte alinged... */
	result = ((unsigned char *)result) + 0xf00;
	return result;
}

unsigned long page_of(void *addr)
{
	unsigned long page;
	page = ((unsigned long)addr) >> 12;
	if (!FLAT && (page >= 0x80000)) {
		page &= 0x7FFFF;
		page += mapped_window << 19;
	}
#if 0
	cprint(LINE_SCROLL -2, 0, "page_of(        )->            ");
	hprint(LINE_SCROLL -2, 8, ((unsigned long)addr));
	hprint(LINE_SCROLL -2, 20, page);
#endif	
	return page;
}


/*
 * Find CPU type and cache sizes
 */
void cpu_type(void)
{
	int i, off=0;
	ulong speed;

	v->rdtsc = 0;
	v->pae = 0;

#ifdef CPUID_DEBUG
	dprint(11,0,cpu_id.type,3,1);
	dprint(12,0,cpu_id.model,3,1);
	dprint(13,0,cpu_id.cpuid,3,1);
#endif

	/* If the CPUID instruction is not supported then this is */
	/* a 386, 486 or one of the early Cyrix CPU's */
	if (cpu_id.cpuid < 1) {
		switch (cpu_id.type) {
		case 2:
			/* This is a Cyrix CPU without CPUID */
			i = getCx86(0xfe);
			i &= 0xf0;
			i >>= 4;
			switch(i) {
			case 0:
			case 1:
				cprint(LINE_CPU, 0, "Cyrix Cx486");
				break;
			case 2:
				cprint(LINE_CPU, 0,"Cyrix 5x86");
				break;
			case 3:
				cprint(LINE_CPU, 0,"Cyrix 6x86");
				break;
			case 4:
				cprint(LINE_CPU, 0,"Cyrix MediaGX");
				break;
			case 5:
				cprint(LINE_CPU, 0,"Cyrix 6x86MX");
				break;
			case 6:
				cprint(LINE_CPU, 0,"Cyrix MII");
				break;
			default:
				cprint(LINE_CPU, 0,"Cyrix ???");
				break;
			}
			break;
		case 3:
			cprint(LINE_CPU, 0, "386");
			break;

		case 4:
			cprint(LINE_CPU, 0, "486");
			l1_cache = 8;
			break;
		}
		return;
	}

	/* We have cpuid so we can see if we have pae support */
	if (cpu_id.capability & (1 << X86_FEATURE_PAE)) {
		v->pae = 1;
	}
	switch(cpu_id.vend_id[0]) {
	/* AMD Processors */
	case 'A':
		switch(cpu_id.type) {
		case 4:
			switch(cpu_id.model) {
			case 3:
				cprint(LINE_CPU, 0, "AMD 486DX2");
				break;
			case 7:
				cprint(LINE_CPU, 0, "AMD 486DX2-WB");
				break;
			case 8:
				cprint(LINE_CPU, 0, "AMD 486DX4");
				break;
			case 9:
				cprint(LINE_CPU, 0, "AMD 486DX4-WB");
				break;
			case 14:
				cprint(LINE_CPU, 0, "AMD 5x86-WT");
				break;
			case 15:
				cprint(LINE_CPU, 0, "AMD 5x86-WB");
				break;
			}
			/* Since we can't get CPU speed or cache info return */
			return;
		case 5:
			switch(cpu_id.model) {
			case 0:
			case 1:
			case 2:
			case 3:
				cprint(LINE_CPU, 0, "AMD K5");
				off = 6;
				break;
			case 6:
			case 7:
				cprint(LINE_CPU, 0, "AMD K6");
				off = 6;
				l1_cache = cpu_id.cache_info[3];
				l1_cache += cpu_id.cache_info[7];
				break;
			case 8:
				cprint(LINE_CPU, 0, "AMD K6-2");
				off = 8;
				l1_cache = cpu_id.cache_info[3];
				l1_cache += cpu_id.cache_info[7];
				break;
			case 9:
				cprint(LINE_CPU, 0, "AMD K6-III");
				off = 10;
				l1_cache = cpu_id.cache_info[3];
				l1_cache += cpu_id.cache_info[7];
				l2_cache = (cpu_id.cache_info[11] << 8);
				l2_cache += cpu_id.cache_info[10];
				break;
			case 13: 
				cprint(LINE_CPU, 0, "AMD K6-III+"); 
				off = 11; 
				l1_cache = cpu_id.cache_info[3]; 
				l1_cache += cpu_id.cache_info[7]; 
				l2_cache = (cpu_id.cache_info[11] << 8); 
				l2_cache += cpu_id.cache_info[10]; 
				break;
			}
			break;
		case 6:
			/* Get L1 & L2 cache sizes */
			l1_cache = cpu_id.cache_info[3];
			l1_cache += cpu_id.cache_info[7];
			l2_cache = (cpu_id.cache_info[11] << 8);
			l2_cache += cpu_id.cache_info[10];

			switch(cpu_id.model) {
			case 1:
				cprint(LINE_CPU, 0, "AMD Athlon (0.25)");
				off = 17;
				break;
			case 2:
			case 4:
				cprint(LINE_CPU, 0, "AMD Athlon (0.18)");
				off = 17;
				break;
			case 6:
				if (l2_cache == 64) {
					cprint(LINE_CPU, 0, "AMD Duron (0.18)");
				} else {
					cprint(LINE_CPU, 0, "Athlon XP (0.18)");
				}
				off = 16;
				break;
			case 8:
			case 10:
				if (l2_cache == 64) {
					cprint(LINE_CPU, 0, "AMD Duron (0.13)");
				} else {
					cprint(LINE_CPU, 0, "Athlon XP (0.13)");
				}
				off = 16;
				break;
			case 3:
			case 7:
				cprint(LINE_CPU, 0, "AMD Duron");
				off = 9;
				/* Duron stepping 0 CPUID for L2 is broken */
				/* (AMD errata T13)*/
				if (cpu_id.step == 0) { /* stepping 0 */
					/* Hard code the right L2 size */
					l2_cache = 64;
				}
				break;
			}
			break;
		case 15:
			/* Get L1 & L2 cache sizes */
			l1_cache = cpu_id.cache_info[3];
			l1_cache += cpu_id.cache_info[7];
			l2_cache = (cpu_id.cache_info[11] << 8);
			l2_cache += cpu_id.cache_info[10];

			switch(cpu_id.model) {
			default:
				cprint(LINE_CPU, 0, "AMD K8");
				off = 6;
				break;
			case 1:
			case 5:
				if (((cpu_id.ext >> 16) & 0xF) != 0) {
					cprint(LINE_CPU, 0, "AMD Opteron (0.09)");				
				} else {
					cprint(LINE_CPU, 0, "AMD Opteron (0.13)");
				}
				off = 18;
				break;
			case 3:
			case 11:
				cprint(LINE_CPU, 0, "Athlon 64 X2");
				off = 12;				
				break;
			case 4:
			case 7:
			case 9:
			case 12:
			case 14:
			case 15:
				if (((cpu_id.ext >> 16) & 0xF) != 0) {
					if (l2_cache > 256) {
						cprint(LINE_CPU, 0, "Athlon 64 (0.09)");
					} else {
						cprint(LINE_CPU, 0, "Sempron (0.09)");						
					}
				} else {
					if (l2_cache > 256) {
						cprint(LINE_CPU, 0, "Athlon 64 (0.13)");
					} else {
						cprint(LINE_CPU, 0, "Sempron (0.13)");						
					}		
				}
				off = 16;
				break;
			}
			break;
		}
		break;

	/* Intel or Transmeta Processors */
	case 'G':
		if ( cpu_id.vend_id[7] == 'T' ) {	/* GenuineTMx86 */
			if (cpu_id.type == 5) {
				cprint(LINE_CPU, 0, "TM 5x00");
				off = 7;
			} else if (cpu_id.type == 15) {
				cprint(LINE_CPU, 0, "TM 8x00");
				off = 7;
			}
			l1_cache = cpu_id.cache_info[3] + cpu_id.cache_info[7];
			l2_cache = (cpu_id.cache_info[11]*256) + cpu_id.cache_info[10];
		} else {				/* GenuineIntel */
			if (cpu_id.type == 4) {
			switch(cpu_id.model) {
			case 0:
			case 1:
				cprint(LINE_CPU, 0, "Intel 486DX");
				off = 11;
				break;
			case 2:
				cprint(LINE_CPU, 0, "Intel 486SX");
				off = 11;
				break;
			case 3:
				cprint(LINE_CPU, 0, "Intel 486DX2");
				off = 12;
				break;
			case 4:
				cprint(LINE_CPU, 0, "Intel 486SL");
				off = 11;
				break;
			case 5:
				cprint(LINE_CPU, 0, "Intel 486SX2");
				off = 12;
				break;
			case 7:
				cprint(LINE_CPU, 0, "Intel 486DX2-WB");
				off = 15;
				break;
			case 8:
				cprint(LINE_CPU, 0, "Intel 486DX4");
				off = 12;
				break;
			case 9:
				cprint(LINE_CPU, 0, "Intel 486DX4-WB");
				off = 15;
				break;
			}
			/* Since we can't get CPU speed or cache info return */
			return;
		}

		/* Get the cache info */
		for (i=0; i<16; i++) {
#ifdef CPUID_DEBUG
			dprint(12,i*3,cpu_id.cache_info[i],2,1);
#endif
			switch(cpu_id.cache_info[i]) {
			case 0x6:
			case 0xa:
			case 0x66:
				l1_cache += 8;
				break;
			case 0x8:
			case 0xc:
			case 0x67:
			case 0x60:
				l1_cache += 16;
				break;
			case 0x68:
			case 0x2c:
			case 0x30:
				l1_cache += 32;
				break;
			case 0x40:
				l2_cache = 0;
				break;
			case 0x41:
			case 0x79:
			case 0x39:
			case 0x3b:
				l2_cache = 128;
				break;
			case 0x42:
			case 0x7a:
			case 0x82:
			case 0x3c:
				l2_cache = 256;
				break;
			case 0x43:
			case 0x7b:
			case 0x83:
			case 0x86:
				l2_cache = 512;
				break;
			case 0x44:
			case 0x7c:
			case 0x84:
			case 0x87:
				l2_cache = 1024;
				break;
			case 0x45:
			case 0x7d:
			case 0x85:
				l2_cache = 2048;
				break;
			}
		}

		switch(cpu_id.type) {
		case 5:
			switch(cpu_id.model) {
			case 0:
			case 1:
			case 2:
			case 3:
			case 7:
				cprint(LINE_CPU, 0, "Pentium");
				if (l1_cache == 0) {
					l1_cache = 8;
				}
				off = 7;
				break;
			case 4:
			case 8:
				cprint(LINE_CPU, 0, "Pentium-MMX");
				if (l1_cache == 0) {
					l1_cache = 16;
				}
				off = 11;
				break;
			}
			break;
		case 6:
			switch(cpu_id.model) {
			case 0:
			case 1:
				cprint(LINE_CPU, 0, "Pentium Pro");
				off = 11;
				break;
			case 3:
			case 4:
				cprint(LINE_CPU, 0, "Pentium II");
				off = 10;
				break;
			case 5:
				if (l2_cache == 0) {
					cprint(LINE_CPU, 0, "Celeron");
					off = 7;
				} else {
					cprint(LINE_CPU, 0, "Pentium II");
					off = 10;
				}
				break;
			case 6:
				if (l2_cache == 128) {
					cprint(LINE_CPU, 0, "Celeron");
					off = 7;
				} else {
				    if (cpu_id.step == 0 || cpu_id.step == 5) {
					cprint(LINE_CPU, 0, "Celeron-A");
					off = 9;
				    } else {
					cprint(LINE_CPU, 0, "Pentium II");
					off = 10;
				    }
				}
				break;
			case 7:
			case 8:
			case 10:
			case 11:
				if (l2_cache == 128) {
					cprint(LINE_CPU, 0, "Celeron");
					off = 7;
				} else {
					cprint(LINE_CPU, 0, "Pentium III");
					off = 11;
				}
				break;
			case 9:
				if (l2_cache == 512) {
					cprint(LINE_CPU, 0, "Celeron M (0.13)");
				} else {
					cprint(LINE_CPU, 0, "Pentium M (0.13)");
				}
				off = 16;
				break;
			case 13:
				if (l2_cache == 1024) {
					cprint(LINE_CPU, 0, "Celeron M (0.09)");
				} else {
					cprint(LINE_CPU, 0, "Pentium M (0.09)");
				}
				off = 16;
				break;
			}
			break;
		case 15:
			switch(cpu_id.model) {
			case 0:
			case 1:			
				if (l2_cache == 128) {
					cprint(LINE_CPU, 0, "Celeron (0.18)");
					off = 14;	
				} else if (cpu_id.pwrcap == 0x0B) {
					cprint(LINE_CPU, 0, "Xeon DP (0.18)");
					off = 14;
				} else if (cpu_id.pwrcap == 0x0C) {
					cprint(LINE_CPU, 0, "Xeon MP (0.18)");
					off = 14;
				} else {
					cprint(LINE_CPU, 0, "Pentium 4 (0.18)");
					off = 16;
				}
				break;
			case 2:
				if (l2_cache == 128) {
					cprint(LINE_CPU, 0, "Celeron (0.13)");
					off = 14;	
				} else if (cpu_id.pwrcap == 0x0B) {
					cprint(LINE_CPU, 0, "Xeon DP (0.13)");
					off = 14;
				} else if (cpu_id.pwrcap == 0x0C) {
					cprint(LINE_CPU, 0, "Xeon MP (0.13)");
					off = 14;
				} else {
					cprint(LINE_CPU, 0, "Pentium 4 (0.13)");
					off = 16;
				}
				break;
			case 3:
				if (l2_cache == 256) {
					cprint(LINE_CPU, 0, "Celeron (0.09)");
					off = 14;	
				} else if (cpu_id.pwrcap == 0x0B) {
					cprint(LINE_CPU, 0, "Xeon DP (0.09)");
					off = 14;
				} else if (cpu_id.pwrcap == 0x0C) {
					cprint(LINE_CPU, 0, "Xeon MP (0.09)");
					off = 14;
				} else {
					cprint(LINE_CPU, 0, "Pentium 4 (0.09)");
					off = 16;
				}
				break;
 			case 4:
				cprint(LINE_CPU, 0, "Pentium D (0.09)");
   				off = 16;		
 				break;
			default:
				cprint(LINE_CPU, 0, "Unknown Intel");
				off = 13;	
 				break;
			}
			break;
		    }

		}
		break;

	/* VIA/Cyrix/Centaur Processors with CPUID */
	case 'C':
		if ( cpu_id.vend_id[1] == 'e' ) {	/* CentaurHauls */
			switch(cpu_id.type){
			case 5:
				cprint(LINE_CPU, 0, "Centaur 5x86");
				off = 12;
				break;
			case 6: // VIA C3
				if (cpu_id.step < 8) {
					cprint(LINE_CPU, 0, "VIA C3 Samuel2");
					off = 14;
				} else {
					cprint(LINE_CPU, 0, "Via C3 Eden");
					off = 11;
				}
				break;
			}
			l1_cache = cpu_id.cache_info[3] + cpu_id.cache_info[7];
			l2_cache = cpu_id.cache_info[11];
		} else {				/* CyrixInstead */
			switch(cpu_id.type) {
			case 5:
				switch(cpu_id.model) {
				case 0:
					cprint(LINE_CPU, 0, "Cyrix 6x86MX/MII");
					off = 16;
					break;
				case 4:
					cprint(LINE_CPU, 0, "Cyrix GXm");
					off = 9;
					break;
				}
				return;

			case 6: // VIA C3
				switch(cpu_id.model) {
				case 6:
					cprint(LINE_CPU, 0, "Cyrix III");
					off = 9;
					break;
				case 7:
					if (cpu_id.step < 8) {
						cprint(LINE_CPU, 0, "VIA C3 Samuel2");
						off = 14;
					} else {
						cprint(LINE_CPU, 0, "VIA C3 Ezra-T");
						off = 13;
					}
					break;
				case 8:
					cprint(LINE_CPU, 0, "VIA C3 Ezra-T");
					off = 13;
					break;
				case 9:
					cprint(LINE_CPU, 0, "VIA C3 Nehemiah");
					off = 15;
					break;
				}
				// L1 = L2 = 64 KB from Cyrix III to Nehemiah
				l1_cache = 64;
				l2_cache = 64;
				break;
			}
		}
		break;

	/* Unknown processor */
	default:
		off = 3;
		/* Make a guess at the family */
		switch(cpu_id.type) {
		case 5:
			cprint(LINE_CPU, 0, "586");
			return;
		case 6:
			cprint(LINE_CPU, 0, "686");
			return;
		}
	}

	/* We are here only if the CPU type supports the rdtsc instruction */

	/* Print CPU speed */
	if ((speed = cpuspeed()) > 0) {
		if (speed < 999500) {
			speed += 50; /* for rounding */
			cprint(LINE_CPU, off, "    . MHz");
			dprint(LINE_CPU, off+1, speed/1000, 3, 1);
			dprint(LINE_CPU, off+5, (speed/100)%10, 1, 0);
		} else {
			speed += 500; /* for rounding */
			cprint(LINE_CPU, off, "      Mhz");
			dprint(LINE_CPU, off, speed/1000, 5, 0);
		}
		extclock = speed;
	}

	/* Print out L1 cache info */
	/* To measure L1 cache speed we use a block size that is 1/4th */
	/* of the total L1 cache size since half of it is for instructions */
	if (l1_cache) {
		cprint(LINE_CPU+1, 0, "L1 Cache:     K  ");
		dprint(LINE_CPU+1, 11, l1_cache, 3, 0);
		if ((speed=memspeed((ulong)mapping(0x100),
				(l1_cache / 4) * 1024, 50, MS_COPY))) {
			cprint(LINE_CPU+1, 16, "       MB/s");
			dprint(LINE_CPU+1, 16, speed, 6, 0);
		}
	}

	/* Print out L2 cache info */
	/* We measure the L2 cache speed by using a block size that is */
	/* the size of the L1 cache.  We have to fudge if the L1 */
	/* cache is bigger than the L2 */
	if (l2_cache) {
		cprint(LINE_CPU+2, 0, "L2 Cache:     K  ");
		dprint(LINE_CPU+2, 10, l2_cache, 4, 0);

		if (l2_cache < l1_cache) {
			i = l1_cache / 4 + l2_cache / 4;
		} else {
			i = l1_cache;
		}
		if ((speed=memspeed((ulong)mapping(0x100), i*1024, 50,
				MS_COPY))) {
			cprint(LINE_CPU+2, 16, "       MB/s");
			dprint(LINE_CPU+2, 16, speed, 6, 0);
		}
	}

	/* Determine memory speed.  To find the memory speed we use */
	/* A block size that is 5x the sum of the L1 and L2 caches */
	i = (l2_cache + l1_cache) * 5;

	/* Make sure that we have enough memory to do the test */
	if ((1 + (i * 2)) > (v->plim_upper << 2)) {
		i = ((v->plim_upper <<2) - 1) / 2;
	}
	if((speed = memspeed((ulong)mapping(0x100), i*1024, 40, MS_COPY))) {
		cprint(LINE_CPU+3, 16, "       MB/s");
		dprint(LINE_CPU+3, 16, speed, 6, 0);
	}

	/* Record the sarting time */
        asm __volatile__ ("rdtsc":"=a" (v->startl),"=d" (v->starth));
        v->snapl = v->startl;
        v->snaph = v->starth;
	v->rdtsc = 1;
	if (l1_cache == 0) { l1_cache = 66; }
	if (l2_cache == 0) { l1_cache = 666; }
}

/* Find cache-able memory size */
static void cacheable(void)
{
	ulong speed, pspeed;
	ulong paddr, mem_top, cached;

	mem_top = v->pmap[v->msegs - 1].end;
	cached = v->test_pages;
	pspeed = 0;
	for (paddr=0x200; paddr <= mem_top - 64; paddr+=0x400) {
		int i;
		int found;
		/* See if the paddr is at a testable location */
		found = 0;
		for(i = 0; i < v->msegs; i++) {
			if ((v->pmap[i].start >= paddr)  &&
				(v->pmap[i].end <= (paddr + 32))) {
				found = 1;
				break;
			}
		}
		if (!found) {
			continue;
		}
		/* Map the range and perform the test */
		map_page(paddr);
		speed = memspeed((ulong)mapping(paddr), 32*4096, 1, MS_COPY);
		if (pspeed) {
			if (speed < pspeed) {
				cached -= 32;
			}
			pspeed = (ulong)((float)speed * 0.7);
		}
	}
	aprint(LINE_INFO, COL_CACHE_TOP, cached);
	/* Ensure the default set of pages are mapped */
	map_page(0);
	map_page(0x80000);
}


/* #define TICKS 5 * 11832 (count = 6376)*/
/* #define TICKS (65536 - 12752) */
#define TICKS 59659	/* 50 ms */

/* Returns CPU clock in khz */
static int cpuspeed(void)
{
	int loops;

	/* Setup timer */
	outb((inb(0x61) & ~0x02) | 0x01, 0x61);
	outb(0xb0, 0x43); 
	outb(TICKS & 0xff, 0x42);
	outb(TICKS >> 8, 0x42);

	asm __volatile__ ("rdtsc":"=a" (st_low),"=d" (st_high));

	loops = 0;
	do {
		loops++;
	} while ((inb(0x61) & 0x20) == 0);

	asm __volatile__ (
		"rdtsc\n\t" \
		"subl st_low,%%eax\n\t" \
		"sbbl st_high,%%edx\n\t" \
		:"=a" (end_low), "=d" (end_high)
	);

	/* Make sure we have a credible result */
	if (loops < 4 || end_low < 50000) {
		return(-1);
	}
	v->clks_msec = end_low/50;
	return(v->clks_msec);
}

/* Measure cache/memory speed by copying a block of memory. */
/* Returned value is kbytes/second */
ulong memspeed(ulong src, ulong len, int iter, int type)
{
	ulong dst;
	ulong wlen;
	int i;

	dst = src + len;
	wlen = len / 4;  /* Length is bytes */

	/* Calibrate the overhead with a zero word copy */
	asm __volatile__ ("rdtsc":"=a" (st_low),"=d" (st_high));
	for (i=0; i<iter; i++) {
		asm __volatile__ (
			"movl %0,%%esi\n\t" \
       		 	"movl %1,%%edi\n\t" \
       		 	"movl %2,%%ecx\n\t" \
       		 	"cld\n\t" \
       		 	"rep\n\t" \
       		 	"movsl\n\t" \
				:: "g" (src), "g" (dst), "g" (0)
			: "esi", "edi", "ecx"
		);
	}
	asm __volatile__ ("rdtsc":"=a" (cal_low),"=d" (cal_high));

	/* Compute the overhead time */
	asm __volatile__ (
		"subl %2,%0\n\t"
		"sbbl %3,%1"
		:"=a" (cal_low), "=d" (cal_high)
		:"g" (st_low), "g" (st_high),
		"0" (cal_low), "1" (cal_high)
	);


	/* Now measure the speed */
	switch (type) {
	case MS_COPY:
		/* Do the first copy to prime the cache */
		asm __volatile__ (
			"movl %0,%%esi\n\t" \
			"movl %1,%%edi\n\t" \
       		 	"movl %2,%%ecx\n\t" \
       		 	"cld\n\t" \
       		 	"rep\n\t" \
       		 	"movsl\n\t" \
			:: "g" (src), "g" (dst), "g" (wlen)
			: "esi", "edi", "ecx"
		);
		asm __volatile__ ("rdtsc":"=a" (st_low),"=d" (st_high));
		for (i=0; i<iter; i++) {
		        asm __volatile__ (
				"movl %0,%%esi\n\t" \
				"movl %1,%%edi\n\t" \
       			 	"movl %2,%%ecx\n\t" \
       			 	"cld\n\t" \
       			 	"rep\n\t" \
       			 	"movsl\n\t" \
				:: "g" (src), "g" (dst), "g" (wlen)
				: "esi", "edi", "ecx"
			);
		}
		asm __volatile__ ("rdtsc":"=a" (end_low),"=d" (end_high));
		break;
	case MS_WRITE:
		asm __volatile__ ("rdtsc":"=a" (st_low),"=d" (st_high));
		for (i=0; i<iter; i++) {
			asm __volatile__ (
       			 	"movl %0,%%ecx\n\t" \
				"movl %1,%%edi\n\t" \
       			 	"movl %2,%%eax\n\t" \
                                "rep\n\t" \
                                "stosl\n\t"
                                :: "g" (wlen), "g" (dst), "g" (0)
				: "edi", "ecx", "eax"
                        );
		}
		asm __volatile__ ("rdtsc":"=a" (end_low),"=d" (end_high));
		break;
	case MS_READ:
		asm __volatile__ (
			"movl %0,%%esi\n\t" \
			"movl %1,%%ecx\n\t" \
       	 		"cld\n\t" \
       	 		"L1:\n\t" \
			"lodsl\n\t" \
       	 		"loop L1\n\t" \
			:: "g" (src), "g" (wlen)
			: "esi", "ecx"
		);
		asm __volatile__ ("rdtsc":"=a" (st_low),"=d" (st_high));
		for (i=0; i<iter; i++) {
		        asm __volatile__ (
				"movl %0,%%esi\n\t" \
				"movl %1,%%ecx\n\t" \
       		 		"cld\n\t" \
       		 		"L2:\n\t" \
				"lodsl\n\t" \
       		 		"loop L2\n\t" \
				:: "g" (src), "g" (wlen)
				: "esi", "ecx"
			);
		}
		asm __volatile__ ("rdtsc":"=a" (end_low),"=d" (end_high));
		break;
	}

	/* Compute the elapsed time */
	asm __volatile__ (
		"subl %2,%0\n\t"
		"sbbl %3,%1"
		:"=a" (end_low), "=d" (end_high)
		:"g" (st_low), "g" (st_high),
		"0" (end_low), "1" (end_high)
	);
	/* Subtract the overhead time */
	asm __volatile__ (
		"subl %2,%0\n\t"
		"sbbl %3,%1"
		:"=a" (end_low), "=d" (end_high)
		:"g" (cal_low), "g" (cal_high),
		"0" (end_low), "1" (end_high)
	);

	/* Make sure that the result fits in 32 bits */
	if (end_high) {
		return(0);
	}

	/* If this was a copy adjust the time */
	if (type == MS_COPY) {
		end_low /= 2;
	}

	/* Convert to clocks/KB */
	end_low /= len;
	end_low *= 1024;
	end_low /= iter;
	if (end_low == 0) {
		return(0);
	}

	/* Convert to kbytes/sec */
	return((v->clks_msec)/end_low);
}
