/* controller.c - MemTest-86  Version 3.3
 *
 * Released under version 2 of the Gnu Public License.
 * By Chris Brady, cbrady@sgi.com
 * ----------------------------------------------------
 * MemTest86+ V1.55 Specific code (GPL V2.0)
 * By Samuel DEMEULEMEESTER, sdemeule@memtest.org
 * http://www.x86-secret.com - http://www.memtest.org
 */

#include "defs.h"
#include "config.h"
#include "test.h"
#include "pci.h"
#include "controller.h"

int col, col2;

extern ulong extclock;
extern struct cpu_ident cpu_id;

#define rdmsr(msr,val1,val2) \
	__asm__ __volatile__("rdmsr" \
			  : "=a" (val1), "=d" (val2) \
			  : "c" (msr))

#define wrmsr(msr,val1,val2) \
	__asm__ __volatile__("wrmsr" \
			  : /* no outputs */ \
			  : "c" (msr), "a" (val1), "d" (val2))


/* controller ECC capabilities and mode */
#define __ECC_UNEXPECTED 1      /* Unknown ECC capability present */
#define __ECC_DETECT     2	/* Can detect ECC errors */
#define __ECC_CORRECT    4	/* Can correct some ECC errors */
#define __ECC_SCRUB      8	/* Can scrub corrected ECC errors */
#define __ECC_CHIPKILL  16	/* Can corrected multi-errors */

#define ECC_UNKNOWN      (~0UL)    /* Unknown error correcting ability/status */
#define ECC_NONE         0       /* Doesnt support ECC (or is BIOS disabled) */
#define ECC_RESERVED     __ECC_UNEXPECTED  /* Reserved ECC type */
#define ECC_DETECT       __ECC_DETECT
#define ECC_CORRECT      (__ECC_DETECT | __ECC_CORRECT)
#define ECC_CHIPKILL	 (__ECC_DETECT | __ECC_CORRECT | __ECC_CHIPKILL)
#define ECC_SCRUB        (__ECC_DETECT | __ECC_CORRECT | __ECC_SCRUB)


static struct ecc_info {
	int index;
	int poll;
	unsigned bus;
	unsigned dev;
	unsigned fn;
	unsigned cap;
	unsigned mode;
} ctrl =
{
	.index = 0,
	/* I know of no case where the memory controller is not on the
	 * host bridge, and the host bridge is not on bus 0  device 0
	 * fn 0.  But just in case leave these as variables.
	 */
	.bus = 0,
	.dev = 0,
	.fn = 0,
	/* Properties of the current memory controller */
	.cap = ECC_UNKNOWN,
	.mode = ECC_UNKNOWN,
};

struct pci_memory_controller {
	unsigned vendor;
	unsigned device;
	char *name;
	int tested;
	void (*poll_fsb)(void);
	void (*poll_timings)(void);
	void (*setup_ecc)(void);
	void (*poll_errors)(void);
};

void print_timings_info(float cas, int rcd, int rp, int ras) {

	/* Now, we could print some additionnals timings infos) */
	cprint(LINE_CPU+5, col2 +1, "/ CAS : ");
	col2 += 9;

	// CAS Latency (tCAS)
	if (cas == 1.5) {
		cprint(LINE_CPU+5, col2, "1.5"); col2 += 3;
	} else if (cas == 2.5) {
		cprint(LINE_CPU+5, col2, "2.5"); col2 += 3;
	} else {
		dprint(LINE_CPU+5, col2, cas, 1, 0); col2 += 1;
	}
	cprint(LINE_CPU+5, col2, "-"); col2 += 1;

	// RAS-To-CAS (tRCD)
	dprint(LINE_CPU+5, col2, rcd, 1, 0);
	cprint(LINE_CPU+5, col2+1, "-");
	col2 +=2;

	// RAS Precharge (tRP)
	dprint(LINE_CPU+5, col2, rp, 1, 0);
	cprint(LINE_CPU+5, col2+1, "-");
	col2 +=2;

	// RAS Active to precharge (tRAS)
	if (ras < 9) {
		dprint(LINE_CPU+5, col2, ras, 1, 0);
		col2 += 2;
	} else {
		dprint(LINE_CPU+5, col2, ras, 2, 0);
		col2 += 3;
	}

}


void print_fsb_info(float val, const char *text_fsb) {

	cprint(LINE_CPU+5, col2, "Settings: ");
	col2 += 10;
	cprint(LINE_CPU+5, col2, text_fsb);
	col2 += 6;
	dprint(LINE_CPU+5, col2, val ,3 ,0);
	col2 += 3;
	cprint(LINE_CPU+5, col2 +1, "MHz ");
	col2 += 5;
	cprint(LINE_CPU+5, col2, "(DDR");
	col2 += 4;
	dprint(LINE_CPU+5, col2, val*2 ,3 ,0);
	col2 += 3;
	cprint(LINE_CPU+5, col2, ")");
	col2 += 1;
}

static void poll_fsb_nothing(void)
{
/* Code to run for no specific fsb detection */
	return;
}

static void poll_timings_nothing(void)
{
/* Code to run for no specific timings detection */
	return;
}


static void setup_nothing(void)
{
	ctrl.cap = ECC_NONE;
	ctrl.mode = ECC_NONE;
}

static void poll_nothing(void)
{
/* Code to run when we don't know how, or can't ask the memory
 * controller about memory errors.
 */
	return;
}

static void setup_amd64(void)
{

	static const int ddim[] = { ECC_NONE, ECC_CORRECT, ECC_RESERVED, ECC_CHIPKILL };
	unsigned long nbxcfg;
	unsigned int mcgsrl;
	unsigned int mcgsth;
	unsigned long mcanb;
	unsigned long dramcl;

	/* All AMD64 support Chipkill */
	ctrl.cap = ECC_CHIPKILL;

	/* Check First if ECC DRAM Modules are used */
	pci_conf_read(0, 24, 2, 0x90, 4, &dramcl);

	if ((dramcl >> 17)&1){
		/* Fill in the correct memory capabilites */
		pci_conf_read(0, 24, 3, 0x44, 4, &nbxcfg);
		ctrl.mode = ddim[(nbxcfg >> 22)&3];
	} else {
		ctrl.mode = ECC_NONE;
	}
	/* Enable NB ECC Logging by MSR Write */
	rdmsr(0x017B, mcgsrl, mcgsth);
	wrmsr(0x017B, 0x10, mcgsth);

	/* Clear any previous error */
	pci_conf_read(0, 24, 3, 0x4C, 4, &mcanb);
	pci_conf_write(0, 24, 3, 0x4C, 4, mcanb & 0x7F801EFC );

}

static void poll_amd64(void)
{

	unsigned long mcanb;
	unsigned long page, offset;
	unsigned long celog_syndrome;
	unsigned long mcanb_add;

	pci_conf_read(0, 24, 3, 0x4C, 4, &mcanb);

	if (((mcanb >> 31)&1) && ((mcanb >> 14)&1)) {
		/* Find out about the first correctable error */
		/* Syndrome code -> bits use a complex matrix. Will add this later */
		/* Read the error location */
		pci_conf_read(0, 24, 3, 0x50, 4, &mcanb_add);

		/* Read the syndrome */
		celog_syndrome = (mcanb >> 15)&0xFF;

		/* Parse the error location */
		page = (mcanb_add >> 12);
		offset = (mcanb_add >> 3) & 0xFFF;

		/* Report the error */
		print_ecc_err(page, offset, 1, celog_syndrome, 0);

		/* Clear the error registers */
		pci_conf_write(0, 24, 3, 0x4C, 4, mcanb & 0x7F801EFC );
	}
	if (((mcanb >> 31)&1) && ((mcanb >> 13)&1)) {
		/* Found out about the first uncorrectable error */
		/* Read the error location */
		pci_conf_read(0, 24, 3, 0x50, 4, &mcanb_add);

		/* Parse the error location */
		page = (mcanb_add >> 12);
		offset = (mcanb_add >> 3) & 0xFFF;

		/* Report the error */
		print_ecc_err(page, offset, 0, 0, 0);

		/* Clear the error registers */
		pci_conf_write(0, 24, 3, 0x4C, 4, mcanb & 0x7F801EFC );

	}

}

static void setup_amd751(void)
{
	unsigned long dram_status;

	/* Fill in the correct memory capabilites */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x5a, 2, &dram_status);
	ctrl.cap = ECC_CORRECT;
	ctrl.mode = (dram_status & (1 << 2))?ECC_CORRECT: ECC_NONE;
}

static void poll_amd751(void)
{
	unsigned long ecc_status;
	unsigned long bank_addr;
	unsigned long bank_info;
	unsigned long page;
	int bits;
	int i;

	/* Read the error status */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x58, 2, &ecc_status);
	if (ecc_status & (3 << 8)) {
		for(i = 0; i < 6; i++) {
			if (!(ecc_status & (1 << i))) {
				continue;
			}
			/* Find the bank the error occured on */
			bank_addr = 0x40 + (i << 1);

			/* Now get the information on the erroring bank */
			pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, bank_addr, 2, &bank_info);

			/* Parse the error location and error type */
			page = (bank_info & 0xFF80) << 4;
			bits = (((ecc_status >> 8) &3) == 2)?1:2;

			/* Report the error */
			print_ecc_err(page, 0, bits==1?1:0, 0, 0);

		}

		/* Clear the error status */
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn, 0x58, 2, 0);
	}
}

/* Still waiting for the CORRECT intel datasheet
static void setup_i85x(void)
{
	unsigned long drc;
	ctrl.cap = ECC_CORRECT;

	pci_conf_read(ctrl.bus, ctrl.dev, 1, 0x70, 4, &drc);
	ctrl.mode = ((drc>>20)&1)?ECC_CORRECT:ECC_NONE;

}
*/

static void setup_amd76x(void)
{
	static const int ddim[] = { ECC_NONE, ECC_DETECT, ECC_CORRECT, ECC_CORRECT };
	unsigned long ecc_mode_status;

	/* Fill in the correct memory capabilites */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x48, 4, &ecc_mode_status);
	ctrl.cap = ECC_CORRECT;
	ctrl.mode = ddim[(ecc_mode_status >> 10)&3];
}

static void poll_amd76x(void)
{
	unsigned long ecc_mode_status;
	unsigned long bank_addr;
	unsigned long bank_info;
	unsigned long page;

	/* Read the error status */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x48, 4, &ecc_mode_status);
	/* Multibit error */
	if (ecc_mode_status & (1 << 9)) {
		/* Find the bank the error occured on */
		bank_addr = 0xC0 + (((ecc_mode_status >> 4) & 0xf) << 2);

		/* Now get the information on the erroring bank */
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, bank_addr, 4, &bank_info);

		/* Parse the error location and error type */
		page = (bank_info & 0xFF800000) >> 12;

		/* Report the error */
		print_ecc_err(page, 0, 1, 0, 0);

	}
	/* Singlebit error */
	if (ecc_mode_status & (1 << 8)) {
		/* Find the bank the error occured on */
		bank_addr = 0xC0 + (((ecc_mode_status >> 0) & 0xf) << 2);

		/* Now get the information on the erroring bank */
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, bank_addr, 4, &bank_info);

		/* Parse the error location and error type */
		page = (bank_info & 0xFF800000) >> 12;

		/* Report the error */
		print_ecc_err(page, 0, 0, 0, 0);

	}
	/* Clear the error status */
	if (ecc_mode_status & (3 << 8)) {
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn, 0x48, 4, ecc_mode_status);
	}
}

static void setup_cnb20(void)
{
	/* Fill in the correct memory capabilites */
	ctrl.cap = ECC_CORRECT;

	/* FIXME add ECC error polling.  I don't have the documentation
	 * do it right now.
	 */
}

static void setup_iE7xxx(void)
{
	unsigned long mchcfgns;
	unsigned long drc;
	unsigned long device;
	unsigned long dvnp;

	/* Read the hardare capabilities */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x52, 2, &mchcfgns);
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x7C, 4, &drc);

	/* This is a check for E7205 */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x02, 2, &device);

	/* Fill in the correct memory capabilities */
	ctrl.mode = 0;
	ctrl.cap = ECC_CORRECT;

	/* checking and correcting enabled */
	if (((drc >> 20) & 3) == 2) {
		ctrl.mode |= ECC_CORRECT;
	}

	/* E7205 doesn't support scrubbing */
	if (device != 0x255d) {
		/* scrub enabled */
		/* For E7501, valid SCRUB operations is bit 0 / D0:F0:R70-73 */
		ctrl.cap = ECC_SCRUB;
		if (mchcfgns & 1) {
			ctrl.mode |= __ECC_SCRUB;
		}

		/* Now, we can active Dev1/Fun1 */
		/* Thanks to Tyan for providing us the board to solve this */
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xE0, 2, &dvnp);
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn , 0xE0, 2, (dvnp & 0xFE));

		/* Clear any routing of ECC errors to interrupts that the BIOS might have set up */
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x88, 1, 0x0);
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x8A, 1, 0x0);
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x8C, 1, 0x0);
	

	}

	/* Clear any prexisting error reports */
	pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x80, 1, 3);
	pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x82, 1, 3);


}

static void setup_iE7520(void)
{
	unsigned long mchscrb;
	unsigned long drc;
	unsigned long dvnp1;

	/* Read the hardare capabilities */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x52, 2, &mchscrb);
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x7C, 4, &drc);

	/* Fill in the correct memory capabilities */
	ctrl.mode = 0;
	ctrl.cap = ECC_CORRECT;

	/* Checking and correcting enabled */
	if (((drc >> 20) & 3) != 0) {
		ctrl.mode |= ECC_CORRECT;
	}

	/* scrub enabled */
	ctrl.cap = ECC_SCRUB;
	if ((mchscrb & 3) == 2) {
		ctrl.mode |= __ECC_SCRUB;
	}

	/* Now, we can activate Fun1 */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xF4, 1, &dvnp1);
	pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn , 0xF4, 1, (dvnp1 | 0x20));

	/* Clear any prexisting error reports */
	pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x80, 2, 0x4747);
	pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x82, 2, 0x4747);
}

static void poll_iE7xxx(void)
{
	unsigned long ferr;
	unsigned long nerr;

	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x80, 1, &ferr);
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x82, 1, &nerr);

	if (ferr & 1) {
		/* Find out about the first correctable error */
		unsigned long celog_add;
		unsigned long celog_syndrome;
		unsigned long page;

		/* Read the error location */
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn +1, 0xA0, 4, &celog_add);
		/* Read the syndrome */
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn +1, 0xD0, 2, &celog_syndrome);

		/* Parse the error location */
		page = (celog_add & 0x0FFFFFC0) >> 6;

		/* Report the error */
		print_ecc_err(page, 0, 1, celog_syndrome, 0);

		/* Clear Bit */
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x80, 1, ferr & 3);
	}

	if (ferr & 2) {
		/* Found out about the first uncorrectable error */
		unsigned long uccelog_add;
		unsigned long page;

		/* Read the error location */
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn +1, 0xB0, 4, &uccelog_add);

		/* Parse the error location */
		page = (uccelog_add & 0x0FFFFFC0) >> 6;

		/* Report the error */
		print_ecc_err(page, 0, 0, 0, 0);

		/* Clear Bit */
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x80, 1, ferr & 3);
	}

	/* Check if DRAM_NERR contains data */
	if (nerr & 3) {
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x82, 1, nerr & 3);
	}

}

static void setup_i440gx(void)
{
	static const int ddim[] = { ECC_NONE, ECC_DETECT, ECC_CORRECT, ECC_CORRECT };
	unsigned long nbxcfg;

	/* Fill in the correct memory capabilites */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x50, 4, &nbxcfg);
	ctrl.cap = ECC_CORRECT;
	ctrl.mode = ddim[(nbxcfg >> 7)&3];
}

static void poll_i440gx(void)
{
	unsigned long errsts;
	unsigned long page;
	int bits;
	/* Read the error status */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x91, 2, &errsts);
	if (errsts & 0x11) {
		unsigned long eap;
		/* Read the error location */
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x80, 4, &eap);

		/* Parse the error location and error type */
		page = (eap & 0xFFFFF000) >> 12;
		bits = 0;
		if (eap &3) {
			bits = ((eap & 3) == 1)?1:2;
		}

		if (bits) {
			/* Report the error */
			print_ecc_err(page, 0, bits==1?1:0, 0, 0);
		}

		/* Clear the error status */
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn, 0x91, 2, 0x11);
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn, 0x80, 4, 3);
	}

}
static void setup_i840(void)
{
	static const int ddim[] = { ECC_NONE, ECC_RESERVED, ECC_CORRECT, ECC_CORRECT };
	unsigned long mchcfg;

	/* Fill in the correct memory capabilites */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x50, 2, &mchcfg);
	ctrl.cap = ECC_CORRECT;
	ctrl.mode = ddim[(mchcfg >> 7)&3];
}

static void poll_i840(void)
{
	unsigned long errsts;
	unsigned long page;
	unsigned long syndrome;
	int channel;
	int bits;
	/* Read the error status */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, &errsts);
	if (errsts & 3) {
		unsigned long eap;
		unsigned long derrctl_sts;
		/* Read the error location */
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xE4, 4, &eap);
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xE2, 2, &derrctl_sts);

		/* Parse the error location and error type */
		page = (eap & 0xFFFFF800) >> 11;
		channel = eap & 1;
		syndrome = derrctl_sts & 0xFF;
		bits = ((errsts & 3) == 1)?1:2;

		/* Report the error */
		print_ecc_err(page, 0, bits==1?1:0, syndrome, channel);

		/* Clear the error status */
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn, 0xE2, 2, 3 << 10);
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, 3);
	}
}
static void setup_i875(void)
{

	long *ptr;
	ulong dev0, dev6 ;

	/* Fill in the correct memory capabilites */

	ctrl.cap = ECC_CORRECT;
	ctrl.mode = ECC_NONE;

	/* From my article : http://www.x86-secret.com/articles/tweak/pat/patsecrets-2.htm */
	/* Activate Device 6 */
	pci_conf_read( 0, 0, 0, 0xF4, 1, &dev0);
	pci_conf_write( 0, 0, 0, 0xF4, 1, (dev0 | 0x2));

	/* Activate Device 6 MMR */
	pci_conf_read( 0, 6, 0, 0x04, 2, &dev6);
	pci_conf_write( 0, 6, 0, 0x04, 2, (dev6 | 0x2));

	/* Read the MMR Base Address & Define the pointer*/
	pci_conf_read( 0, 6, 0, 0x10, 4, &dev6);
	ptr=(long*)(dev6+0x68);

	if (((*ptr >> 18)&1) == 1) { ctrl.mode = ECC_CORRECT; }

	/* Reseting state */
	pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2,  0x81);

}


static void setup_i925(void)
{

	// Activate MMR I/O
	ulong dev0, drc;
	long tolm;
	long *ptr;

	pci_conf_read( 0, 0, 0, 0x54, 4, &dev0);
	dev0 = dev0 | 0x10000000;
	pci_conf_write( 0, 0, 0, 0x54, 4, dev0);
	
	// CDH start
	pci_conf_read( 0, 0, 0, 0x44, 4, &dev0);
	if (!(dev0 & 0xFFFFC000)) {
		pci_conf_read( 0, 0, 0, 0x9C, 1, &tolm);
		pci_conf_write( 0, 0, 0, 0x47, 1, tolm & 0xF8);
	}
	// CDH end

	// ECC Checking
	ctrl.cap = ECC_CORRECT;

	dev0 &= 0xFFFFC000;
	ptr=(long*)(dev0+0x120);
	drc = *ptr & 0xFFFFFFFF;
	
	if (((drc >> 20) & 3) == 2) { 
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, 3);
		ctrl.mode = ECC_CORRECT; 
	} else { 
		ctrl.mode = ECC_NONE; 
	}

}


static void poll_i875(void)
{
	unsigned long errsts;
	unsigned long page;
	unsigned long des;
	unsigned long syndrome;
	int channel;
	int bits;
	/* Read the error status */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, &errsts);
	if (errsts & 0x81)  {
		unsigned long eap;
		unsigned long derrsyn;
		/* Read the error location, syndrome and channel */
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x58, 4, &eap);
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x5C, 1, &derrsyn);
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x5D, 1, &des);

		/* Parse the error location and error type */
		page = (eap & 0xFFFFF000) >> 12;
		syndrome = derrsyn;
		channel = des & 1;
		bits = (errsts & 0x80)?0:1;

		/* Report the error */
		print_ecc_err(page, 0, bits, syndrome, channel);

		/* Clear the error status */
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2,  0x81);
	}
}

static void setup_i845(void)
{
	static const int ddim[] = { ECC_NONE, ECC_RESERVED, ECC_CORRECT, ECC_RESERVED };
	unsigned long drc;

	/* Fill in the correct memory capabilites */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x7C, 4, &drc);
	ctrl.cap = ECC_CORRECT;
	ctrl.mode = ddim[(drc >> 20)&3];
}

static void poll_i845(void)
{
	unsigned long errsts;
	unsigned long page, offset;
	unsigned long syndrome;
	int bits;
	/* Read the error status */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, &errsts);
	if (errsts & 3) {
		unsigned long eap;
		unsigned long derrsyn;
		/* Read the error location */
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x8C, 4, &eap);
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x86, 1, &derrsyn);

		/* Parse the error location and error type */
		offset = (eap & 0xFE) << 4;
		page = (eap & 0x3FFFFFFE) >> 8;
		syndrome = derrsyn;
		bits = ((errsts & 3) == 1)?1:2;

		/* Report the error */
		print_ecc_err(page, offset, bits==1?1:0, syndrome, 0);

		/* Clear the error status */
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, 3);
	}
}
static void setup_i820(void)
{
	static const int ddim[] = { ECC_NONE, ECC_RESERVED, ECC_CORRECT, ECC_CORRECT };
	unsigned long mchcfg;

	/* Fill in the correct memory capabilites */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xbe, 2, &mchcfg);
	ctrl.cap = ECC_CORRECT;
	ctrl.mode = ddim[(mchcfg >> 7)&3];
}

static void poll_i820(void)
{
	unsigned long errsts;
	unsigned long page;
	unsigned long syndrome;
	int bits;
	/* Read the error status */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, &errsts);
	if (errsts & 3) {
		unsigned long eap;
		/* Read the error location */
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xc4, 4, &eap);

		/* Parse the error location and error type */
		page = (eap & 0xFFFFF000) >> 4;
		syndrome = eap & 0xFF;
		bits = ((errsts & 3) == 1)?1:2;

		/* Report the error */
		print_ecc_err(page, 0, bits==1?1:0, syndrome, 0);

		/* Clear the error status */
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, 3);
	}
}

static void setup_i850(void)
{
	static const int ddim[] = { ECC_NONE, ECC_RESERVED, ECC_CORRECT, ECC_RESERVED };
	unsigned long mchcfg;

	/* Fill in the correct memory capabilites */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x50, 2, &mchcfg);
	ctrl.cap = ECC_CORRECT;
	ctrl.mode = ddim[(mchcfg >> 7)&3];
}

static void poll_i850(void)
{
	unsigned long errsts;
	unsigned long page;
	unsigned long syndrome;
	int channel;
	int bits;
	/* Read the error status */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, &errsts);
	if (errsts & 3) {
		unsigned long eap;
		unsigned long derrctl_sts;
		/* Read the error location */
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xE4, 4, &eap);
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xE2, 2, &derrctl_sts);

		/* Parse the error location and error type */
		page = (eap & 0xFFFFF800) >> 11;
		channel = eap & 1;
		syndrome = derrctl_sts & 0xFF;
		bits = ((errsts & 3) == 1)?1:2;

		/* Report the error */
		print_ecc_err(page, 0, bits==1?1:0, syndrome, channel);

		/* Clear the error status */
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, errsts & 3);
	}
}

static void setup_i860(void)
{
	static const int ddim[] = { ECC_NONE, ECC_RESERVED, ECC_CORRECT, ECC_RESERVED };
	unsigned long mchcfg;
	unsigned long errsts;

	/* Fill in the correct memory capabilites */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x50, 2, &mchcfg);
	ctrl.cap = ECC_CORRECT;
	ctrl.mode = ddim[(mchcfg >> 7)&3];

	/* Clear any prexisting error reports */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, &errsts);
	pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, errsts & 3);
}

static void poll_i860(void)
{
	unsigned long errsts;
	unsigned long page;
	unsigned char syndrome;
	int channel;
	int bits;
	/* Read the error status */
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, &errsts);
	if (errsts & 3) {
		unsigned long eap;
		unsigned long derrctl_sts;
		/* Read the error location */
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xE4, 4, &eap);
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xE2, 2, &derrctl_sts);

		/* Parse the error location and error type */
		page = (eap & 0xFFFFFE00) >> 9;
		channel = eap & 1;
		syndrome = derrctl_sts & 0xFF;
		bits = ((errsts & 3) == 1)?1:2;

		/* Report the error */
		print_ecc_err(page, 0, bits==1?1:0, syndrome, channel);

		/* Clear the error status */
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, errsts & 3);
	}
}

static void poll_iE7221(void)
{
	unsigned long errsts;
	unsigned long page;
	unsigned char syndrome;
	int channel;
	int bits;
	int errocc;
	
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, &errsts);
	
	errocc = errsts & 3;
	
	if ((errocc == 1) || (errocc == 2)) {
		unsigned long eap, offset;
		unsigned long derrctl_sts;		
		
		/* Read the error location */
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x58, 4, &eap);
		pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, 0x5C, 1, &derrctl_sts);		
		
		/* Parse the error location and error type */
		channel = eap & 1;
		eap = eap & 0xFFFFFF80;
		page = eap >> 12;
		offset = eap & 0xFFF;
		syndrome = derrctl_sts & 0xFF;		
		bits = errocc & 1;

		/* Report the error */
		print_ecc_err(page, offset, bits, syndrome, channel);

		/* Clear the error status */
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, errsts & 3);
	} 
	
	else if (errocc == 3) {
	
		pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn, 0xC8, 2, errsts & 3);	
	
	}
}

static void poll_iE7520(void)
{
	unsigned long ferr;
	unsigned long nerr;

	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x80, 2, &ferr);
	pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x82, 2, &nerr);

	if (ferr & 0x0101) {
			/* Find out about the first correctable error */
			unsigned long celog_add;
			unsigned long celog_syndrome;
			unsigned long page;

			/* Read the error location */
			pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn +1, 0xA0, 4,&celog_add);
			/* Read the syndrome */
			pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn +1, 0xC4, 2, &celog_syndrome);

			/* Parse the error location */
			page = (celog_add & 0x7FFFFFFC) >> 2;

			/* Report the error */
			print_ecc_err(page, 0, 1, celog_syndrome, 0);

			/* Clear Bit */
			pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x80, 2, ferr& 0x0101);
	}

	if (ferr & 0x4646) {
			/* Found out about the first uncorrectable error */
			unsigned long uccelog_add;
			unsigned long page;

			/* Read the error location */
			pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn +1, 0xA4, 4, &uccelog_add);

			/* Parse the error location */
			page = (uccelog_add & 0x7FFFFFFC) >> 2;

			/* Report the error */
			print_ecc_err(page, 0, 0, 0, 0);

			/* Clear Bit */
			pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x80, 2, ferr & 0x4646);
	}

	/* Check if DRAM_NERR contains data */
	if (nerr & 0x4747) {
			 pci_conf_write(ctrl.bus, ctrl.dev, ctrl.fn +1, 0x82, 2, nerr & 0x4747);
	}
}


/* ------------------ Here the code for FSB detection ------------------ */
/* --------------------------------------------------------------------- */

static float athloncoef[] = {11, 11.5, 12.0, 12.5, 5.0, 5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0, 10.5};
static float athloncoef2[] = {12, 19.0, 12.0, 20.0, 13.0, 13.5, 14.0, 21.0, 15.0, 22, 16.0, 16.5, 17.0, 18.0, 23.0, 24.0};
static int p4model1ratios[] = {16, 17, 18, 19, 20, 21, 22, 23, 8, 9, 10, 11, 12, 13, 14, 15};

static int getP4PMmultiplier(void)
{
	unsigned int msr_lo, msr_hi;
	int coef;
	/* Find multiplier (by MSR) */

	if (cpu_id.type == 6) {
		rdmsr(0x2A, msr_lo, msr_hi);
		coef = (msr_lo >> 22) & 0x1F;
	}
	else
	{
		if (cpu_id.model < 2)
		{
			rdmsr(0x2A, msr_lo, msr_hi);
			coef = (msr_lo >> 8) & 0xF;
			coef = p4model1ratios[coef];
		}
		else
		{
			rdmsr(0x2C, msr_lo, msr_hi);
			coef = (msr_lo >> 24) & 0x1F;
		}
	}
	return coef;
}

static void poll_fsb_amd64(void) {

	unsigned int mcgsrl;
	unsigned int mcgsth;
	unsigned long fid, temp2;
	unsigned long dramchr;
	float clockratio;
	double dramclock;

	float coef;
	coef = 10;

	/* First, got the FID by MSR */
	/* First look if Cool 'n Quiet is supported to choose the best msr */
	if (((cpu_id.pwrcap >> 1) & 1) == 1) {
		rdmsr(0xc0010042, mcgsrl, mcgsth);
		fid = (mcgsrl & 0x3F);
	} else {
		rdmsr(0xc0010015, mcgsrl, mcgsth);
		fid = ((mcgsrl >> 24)& 0x3F);
	}
	
	/* Extreme simplification. */
	coef = ( fid / 2 ) + 4.0;

	/* Support for .5 coef */
	if ((fid & 1) == 1) { coef = coef + 0.5; }

	/* Next, we need the clock ratio */
	pci_conf_read(0, 24, 2, 0x94, 4, &dramchr);
	temp2 = (dramchr >> 20) & 0x7;
	clockratio = coef;

	switch (temp2) {
		case 0x0:
			clockratio = (int)(coef * 2.0f);
			break;
		case 0x2:
			clockratio = (int)((coef * 3.0f/2.0f) + 0.81f);
			break;
		case 0x4:
			clockratio = (int)((coef * 4.0f/3.0f) + 0.81f);
			break;
		case 0x5:
			clockratio = (int)((coef * 6.0f/5.0f) + 0.81f);
			break;
		case 0x6:
			clockratio = (int)((coef * 10.0f/9.0f) + 0.81f);
			break;
		case 0x7:
			clockratio = (int)(coef + 0.81f);
			break;
		}

	/* Compute the final DRAM Clock */
	dramclock = (extclock /1000) / clockratio;

	/* ...and print */
	print_fsb_info(dramclock, "RAM : ");

}

static void poll_fsb_i925(void) {

	double dramclock, dramratio, fsb;
	unsigned long mchcfg, mchcfg2, dev0, drc, idetect;
	int coef = getP4PMmultiplier();
	long *ptr;
	
	pci_conf_read( 0, 0, 0, 0x02, 2, &idetect);
	
	/* Find dramratio */
	pci_conf_read( 0, 0, 0, 0x44, 4, &dev0);
	dev0 = dev0 & 0xFFFFC000;
	ptr=(long*)(dev0+0xC00);
	mchcfg = *ptr & 0xFFFF;
	ptr=(long*)(dev0+0x120);
	drc = *ptr & 0xFFFF;
	dramratio = 1;

	mchcfg2 = (mchcfg >> 4)&3;
	
	if ((drc&3) != 2) {
		// We are in DDR1 Mode
		if (mchcfg2 == 1) { dramratio = 0.8; } else { dramratio = 1; }
	} else {
		// We are in DDR2 Mode
		if ((mchcfg >> 2)&1) {
			// We are in FSB1066 Mode
			if (mchcfg2 == 2) { dramratio = 0.75; } else { dramratio = 1; }
		} else {
			switch (mchcfg2) {
				case 1:
					dramratio = 0.66667;
					break;
				case 2:
					if (idetect != 0x2590) { dramratio = 1; } else { dramratio = 1.5; }
					break;
				case 3:
						// Checking for FSB533 Mode & Alviso
						if ((mchcfg & 1) == 0) { dramratio = 1.33334; }
						else if (idetect == 0x2590) { dramratio = 2; }
						else { dramratio = 1.5; }
			}
		}
	}
	// Compute RAM Frequency 
	fsb = ((extclock / 1000) / coef);
	dramclock = fsb * dramratio;

	// Print DRAM Freq 
	print_fsb_info(dramclock, "RAM : "); 
	
	/* Print FSB (only if ECC is not enabled) */
	cprint(LINE_CPU+4, col +1, "- FSB : ");
	col += 9;
	dprint(LINE_CPU+4, col, fsb, 3,0);
	col += 3;
	cprint(LINE_CPU+4, col +1, "MHz");
	col += 4;
	
}

static void poll_fsb_i945(void) {

	double dramclock, dramratio, fsb;
	unsigned long mchcfg, dev0;
	int coef = getP4PMmultiplier();
	long *ptr;

	/* Find dramratio */
	pci_conf_read( 0, 0, 0, 0x44, 4, &dev0);
	dev0 &= 0xFFFFC000;
	ptr=(long*)(dev0+0xC00);
	mchcfg = *ptr & 0xFFFF;
	dramratio = 1;

	switch ((mchcfg >> 4)&7) {
		case 1:
			dramratio = 1.0;
			break;
		case 2:
			dramratio = 1.33334;
			break;
		case 3:
			dramratio = 1.66667;
			break;
		case 4:
			dramratio = 2.0;
			break;
	}

	// Compute RAM Frequency
	fsb = ((extclock / 1000) / coef);
	dramclock = fsb * dramratio;

	// Print DRAM Freq
	print_fsb_info(dramclock, "RAM : ");

	/* Print FSB (only if ECC is not enabled) */
	cprint(LINE_CPU+4, col +1, "- FSB : ");
	col += 9;
	dprint(LINE_CPU+4, col, fsb, 3,0);
	col += 3;
	cprint(LINE_CPU+4, col +1, "MHz");
	col += 4;

}

static void poll_fsb_nf4ie(void) {

	double dramclock, dramratio, fsb;
	float mratio, nratio;
	unsigned long reg74, reg60;
	int coef = getP4PMmultiplier();
	
	/* Find dramratio */
	pci_conf_read(0, 0, 2, 0x74, 2, &reg74);
	pci_conf_read(0, 0, 2, 0x60, 4, &reg60);
	mratio = reg74 & 0xF;
	nratio = (reg74 >> 4) & 0xF;

	// If M or N = 0, then M or N = 16
	if (mratio == 0) { mratio = 16; }
	if (nratio == 0) { nratio = 16; }
	
	// Check if synchro or pseudo-synchro mode
	if((reg60 >> 22) & 1) {
		dramratio = 1;
	} else {
		dramratio = nratio / mratio;
	}

	/* Compute RAM Frequency */
	fsb = ((extclock /1000) / coef);
	dramclock = fsb * dramratio;

	/* Print DRAM Freq */
	print_fsb_info(dramclock, "RAM : ");

	/* Print FSB  */
	cprint(LINE_CPU+4, col, "- FSB : ");
	col += 9;
	dprint(LINE_CPU+4, col, fsb, 3,0);
	col += 3;
	cprint(LINE_CPU+4, col +1, "MHz");
	col += 4;
	
}

static void poll_fsb_i875(void) {

	double dramclock, dramratio, fsb;
	unsigned long mchcfg, smfs;
	int coef = getP4PMmultiplier();

	/* Find dramratio */
	pci_conf_read(0, 0, 0, 0xC6, 2, &mchcfg);
	smfs = (mchcfg >> 10)&3;
	dramratio = 1;

	if ((mchcfg&3) == 3) { dramratio = 1; }
	if ((mchcfg&3) == 2) {
		if (smfs == 2) { dramratio = 1; }
		if (smfs == 1) { dramratio = 1.25; }
		if (smfs == 0) { dramratio = 1.5; }
	}
	if ((mchcfg&3) == 1) {
		if (smfs == 2) { dramratio = 0.6666666666; }
		if (smfs == 1) { dramratio = 0.8; }
		if (smfs == 0) { dramratio = 1; }
	}
	if ((mchcfg&3) == 0) { dramratio = 0.75; }


	/* Compute RAM Frequency */
	dramclock = ((extclock /1000) / coef) / dramratio;
	fsb = ((extclock /1000) / coef);

	/* Print DRAM Freq */
	print_fsb_info(dramclock, "RAM : ");

	/* Print FSB (only if ECC is not enabled) */
	if ( ctrl.mode == ECC_NONE ) {
		cprint(LINE_CPU+4, col +1, "- FSB : ");
		col += 9;
		dprint(LINE_CPU+4, col, fsb, 3,0);
		col += 3;
		cprint(LINE_CPU+4, col +1, "MHz");
		col += 4;
	}
}

static void poll_fsb_p4(void) {

	ulong fsb, idetect;
	int coef = getP4PMmultiplier();

	fsb = ((extclock /1000) / coef);

	/* Print FSB */
	cprint(LINE_CPU+4, col +1, "/ FSB : ");
	col += 9;
	dprint(LINE_CPU+4, col, fsb, 3,0);
	col += 3;
	cprint(LINE_CPU+4, col +1, "MHz");
	col += 4;

	/* For synchro only chipsets */
	pci_conf_read( 0, 0, 0, 0x02, 2, &idetect);
	if (idetect == 0x2540 || idetect == 0x254C) {
		print_fsb_info(fsb, "RAM : ");
	}
}

static void poll_fsb_i855(void) {


	double dramclock, dramratio, fsb ;
	unsigned int msr_lo, msr_hi;
	ulong mchcfg, centri, idetect;
	int coef;

	pci_conf_read( 0, 0, 0, 0x02, 2, &idetect);

	/* Find multiplier (by MSR) */

	/* Is it a Pentium M ? */
	if (cpu_id.type == 6) {
		rdmsr(0x2A, msr_lo, msr_hi);
		coef = (msr_lo >> 22) & 0x1F;

		/* Is it an i855GM or PM ? */
		if (idetect == 0x3580) {
			cprint(LINE_CPU+4, col-1, "i855GM/GME ");
			col += 10;
		}
	} else {
		rdmsr(0x2C, msr_lo, msr_hi);
		coef = (msr_lo >> 24) & 0x1F;
		cprint(LINE_CPU+4, col-1, "i852PM/GM ");
		col += 9;
	}

	fsb = ((extclock /1000) / coef);

	/* Print FSB */
	cprint(LINE_CPU+4, col, "/ FSB : ");	col += 8;
	dprint(LINE_CPU+4, col, fsb, 3,0);	col += 3;
	cprint(LINE_CPU+4, col +1, "MHz");	col += 4;

	/* Is it a Centrino platform or only an i855 platform ? */
	pci_conf_read( 2, 2, 0, 0x02, 2, &centri);
	if (centri == 0x1043) {	cprint(LINE_CPU+4, col +1, "/ Centrino Mobile Platform"); }
	else { cprint(LINE_CPU+4, col +1, "/ Mobile Platform"); }

	/* Compute DRAM Clock */

	dramratio = 1;
	if (idetect == 0x3580) {
		pci_conf_read( 0, 0, 3, 0xC0, 2, &mchcfg);
		mchcfg = mchcfg & 0x7;

		if (mchcfg == 1 || mchcfg == 2 || mchcfg == 4 || mchcfg == 5) {	dramratio = 1; }
		if (mchcfg == 0 || mchcfg == 3) { dramratio = 1.333333333; }
		if (mchcfg == 6) { dramratio = 1.25; }
		if (mchcfg == 7) { dramratio = 1.666666667; }

	} else {
		pci_conf_read( 0, 0, 0, 0xC6, 2, &mchcfg);
		if (((mchcfg >> 10)&3) == 0) { dramratio = 1; }
		else if (((mchcfg >> 10)&3) == 1) { dramratio = 1.666667; }
		else { dramratio = 1.333333333; }
	}


	dramclock = fsb * dramratio;

	/* ...and print */
	print_fsb_info(dramclock, "RAM : ");

}

static void poll_fsb_amd32(void) {

	unsigned int mcgsrl;
	unsigned int mcgsth;
	unsigned long temp;
	double dramclock;
	double coef2;

	/* First, got the FID */
	rdmsr(0x0c0010015, mcgsrl, mcgsth);
	temp = (mcgsrl >> 24)&0x0F;

	if ((mcgsrl >> 19)&1) { coef2 = athloncoef2[temp]; }
	else { coef2 = athloncoef[temp]; }

	if (coef2 == 0) { coef2 = 1; };

	/* Compute the final FSB Clock */
	dramclock = (extclock /1000) / coef2;

	/* ...and print */
	print_fsb_info(dramclock, "FSB : ");

}

static void poll_fsb_nf2(void) {

	unsigned int mcgsrl;
	unsigned int mcgsth;
	unsigned long temp, mempll;
	double dramclock, fsb;
	double mem_m, mem_n;
	float coef;
	coef = 10;

	/* First, got the FID */
	rdmsr(0x0c0010015, mcgsrl, mcgsth);
	temp = (mcgsrl >> 24)&0x0F;

	if ((mcgsrl >> 19)&1) { coef = athloncoef2[temp]; }
	else { coef = athloncoef[temp]; }

	/* Get the coef (COEF = N/M) - Here is for Crush17 */
	pci_conf_read(0, 0, 3, 0x70, 4, &mempll);
	mem_m = (mempll&0x0F);
	mem_n = ((mempll >> 4) & 0x0F);

	/* If something goes wrong, the chipset is probably a Crush18 */
	if ( mem_m == 0 || mem_n == 0 ) {
		pci_conf_read(0, 0, 3, 0x7C, 4, &mempll);
		mem_m = (mempll&0x0F);
		mem_n = ((mempll >> 4) & 0x0F);
	}

	/* Compute the final FSB Clock */
	dramclock = ((extclock /1000) / coef) * (mem_n/mem_m);
	fsb = ((extclock /1000) / coef);

	/* ...and print */

	cprint(LINE_CPU+4, col, "/ FSB : ");
	col += 8;
	dprint(LINE_CPU+4, col, fsb, 3,0);
	col += 3;
	cprint(LINE_CPU+4, col +1, "MHz");

	print_fsb_info(dramclock, "RAM : ");

}

/* ------------------ Here the code for Timings detection ------------------ */
/* ------------------------------------------------------------------------- */

static void poll_timings_nf4ie(void) {


	ulong regd0, reg8c, reg9c, reg80;
	int cas, rcd, rp, ras;

	cprint(LINE_CPU+4, col +1, "- Type : DDR-II");

	//Now, read Registers
	pci_conf_read( 0, 1, 1, 0xD0, 4, &regd0);
	pci_conf_read( 0, 1, 1, 0x80, 1, &reg80);
	pci_conf_read( 0, 1, 0, 0x8C, 4, &reg8c);
	pci_conf_read( 0, 1, 0, 0x9C, 4, &reg9c);

	// Then, detect timings
	cas = (regd0 >> 4) & 0x7;
	rcd = (reg8c >> 24) & 0xF;
	rp = (reg9c >> 8) & 0xF;
	ras = (reg8c >> 16) & 0x3F;
	
	print_timings_info(cas, rcd, rp, ras);
	
	if (reg80 & 0x3) {
		cprint(LINE_CPU+5, col2, "/ Dual Channel (128 bits)");
	} else {
		cprint(LINE_CPU+5, col2, "/ Single Channel (64 bits)");
	}

}

static void poll_timings_i925(void) {

	// Thanks for CDH optis
	ulong dev0, drt, drc, dcc, idetect, temp;
	long *ptr;

	//Now, read MMR Base Address
	pci_conf_read( 0, 0, 0, 0x44, 4, &dev0);
	pci_conf_read( 0, 0, 0, 0x02, 2, &idetect);
	dev0 &= 0xFFFFC000;

	//Set pointer for DRT
	ptr=(long*)(dev0+0x114);
	drt = *ptr & 0xFFFFFFFF;

	//Set pointer for DRC
	ptr=(long*)(dev0+0x120);
	drc = *ptr & 0xFFFFFFFF;

	//Set pointer for DCC
	ptr=(long*)(dev0+0x200);
	dcc = *ptr & 0xFFFFFFFF;

	//Determine DDR or DDR-II
	if ((drc & 3) == 2) {
		cprint(LINE_CPU+4, col +1, "- Type : DDR-II");
	} else {
		cprint(LINE_CPU+4, col +1, "- Type : DDR-I");
	}

	// Now, detect timings
	cprint(LINE_CPU+5, col2 +1, "/ CAS : ");
	col2 += 9;

	// CAS Latency (tCAS)
	temp = ((drt >> 8)& 0x3);

	if ((drc & 3) == 2){
		// Timings DDR-II
		if      (temp == 0x0) { cprint(LINE_CPU+5, col2, "5-"); }
		else if (temp == 0x1) { cprint(LINE_CPU+5, col2, "4-"); }
		else		      { cprint(LINE_CPU+5, col2, "3-"); }
	} else {
		// Timings DDR-I
		if      (temp == 0x0) { cprint(LINE_CPU+5, col2, "3-"); }
		else if (temp == 0x1) { cprint(LINE_CPU+5, col2, "2.5-"); col2 +=2;}
		else		      { cprint(LINE_CPU+5, col2, "2-"); }
	}
	col2 +=2;

	// RAS-To-CAS (tRCD)
	dprint(LINE_CPU+5, col2, ((drt >> 4)& 0x3)+2, 1 ,0);
	cprint(LINE_CPU+5, col2+1, "-");
	col2 +=2;

	// RAS Precharge (tRP)
	dprint(LINE_CPU+5, col2, (drt&0x3)+2, 1 ,0);
	cprint(LINE_CPU+5, col2+1, "-");
	col2 +=2;

	// RAS Active to precharge (tRAS)
	// If Lakeport, than change tRAS computation (Thanks to CDH, again)
	if (idetect == 0x2770)
		temp = ((drt >> 19)& 0x1F);
	else
		temp = ((drt >> 20)& 0x0F);

	dprint(LINE_CPU+5, col2, temp , 1 ,0);
	(temp < 10)?(col2 += 1):(col2 += 2);

	cprint(LINE_CPU+5, col2+1, "/"); col2 +=2;

	temp = (dcc&0x3);
	if      (temp == 1) { cprint(LINE_CPU+5, col2, " Dual Channel (Asymmetric)"); }
	else if (temp == 2) { cprint(LINE_CPU+5, col2, " Dual Channel (Interleaved)"); }
	else		    { cprint(LINE_CPU+5, col2, " Single Channel (64 bits)"); }

}

static void poll_timings_i875(void) {

	ulong dev6, dev62;
	ulong temp;
	float cas;
	int rcd, rp, ras;
	long *ptr, *ptr2;

	/* Read the MMR Base Address & Define the pointer */
	pci_conf_read( 0, 6, 0, 0x10, 4, &dev6);

	/* Now, the PAT ritual ! (Kant and Luciano will love this) */
	pci_conf_read( 0, 6, 0, 0x40, 4, &dev62);
	ptr2=(long*)(dev6+0x68);

	if ((dev62&0x3) == 0 && ((*ptr2 >> 14)&1) == 1) {
		cprint(LINE_CPU+4, col +1, "- PAT : Enabled");
	} else {
		cprint(LINE_CPU+4, col +1, "- PAT : Disabled");
	}

	/* Now, we could check some additionnals timings infos) */

	ptr=(long*)(dev6+0x60);
	// CAS Latency (tCAS)
	temp = ((*ptr >> 5)& 0x3);
	if (temp == 0x0) { cas = 2.5; } else if (temp == 0x1) { cas = 2; } else { cas = 3; }

	// RAS-To-CAS (tRCD)
	temp = ((*ptr >> 2)& 0x3);
	if (temp == 0x0) { rcd = 4; } else if (temp == 0x1) { rcd = 3; } else { rcd = 2; }

	// RAS Precharge (tRP)
	temp = (*ptr&0x3);
	if (temp == 0x0) { rp = 4; } else if (temp == 0x1) { rp = 3; } else { rp = 2; }

	// RAS Active to precharge (tRAS)
	temp = ((*ptr >> 7)& 0x7);
	ras = 10 - temp;

	// Print timings
	print_timings_info(cas, rcd, rp, ras);

	// Print 64 or 128 bits mode
	if (((*ptr2 >> 21)&3) > 0) { 
		cprint(LINE_CPU+5, col2, "/ Dual Channel (128 bits)");
	} else {
		cprint(LINE_CPU+5, col2, "/ Single Channel (64 bits)");
	}
}

static void poll_timings_E7520(void) {

	ulong drt, ddrcsr;
	float cas;
	int rcd, rp, ras;

	pci_conf_read( 0, 0, 0, 0x78, 4, &drt);
	pci_conf_read( 0, 0, 0, 0x9A, 2, &ddrcsr);

	cas = ((drt >> 2) & 3) + 2;
	rcd = ((drt >> 10) & 1) + 3;
	rp = ((drt >> 9) & 1) + 3;
	ras = ((drt >> 14) & 3) + 11;

	print_timings_info(cas, rcd, rp, ras);
	
	if ((ddrcsr & 0xF) >= 0xC) {
		cprint(LINE_CPU+5, col2, "/ Dual Channel (128 bits)");
	} else {
		cprint(LINE_CPU+5, col2, "/ Single Channel (64 bits)");
	}
}


static void poll_timings_i855(void) {

	ulong drt, temp;

	pci_conf_read( 0, 0, 0, 0x78, 4, &drt);

	/* Now, we could print some additionnals timings infos) */
	cprint(LINE_CPU+5, col2 +1, "/ CAS : ");
	col2 += 9;

	// CAS Latency (tCAS)
	temp = ((drt >> 4)&0x1);
	if (temp == 0x0) { cprint(LINE_CPU+5, col2, "2.5-"); col2 += 4;  }
	else { cprint(LINE_CPU+5, col2, "2-"); col2 +=2; }

	// RAS-To-CAS (tRCD)
	temp = ((drt >> 2)& 0x1);
	if (temp == 0x0) { cprint(LINE_CPU+5, col2, "3-"); }
	else { cprint(LINE_CPU+5, col2, "2-"); }
	col2 +=2;

	// RAS Precharge (tRP)
	temp = (drt&0x1);
	if (temp == 0x0) { cprint(LINE_CPU+5, col2, "3-"); }
	else { cprint(LINE_CPU+5, col2, "2-"); }
	col2 +=2;

	// RAS Active to precharge (tRAS)
	temp = 7-((drt >> 9)& 0x3);
	if (temp == 0x0) { cprint(LINE_CPU+5, col2, "7"); }
	if (temp == 0x1) { cprint(LINE_CPU+5, col2, "6"); }
	if (temp == 0x2) { cprint(LINE_CPU+5, col2, "5"); }
	col2 +=1;

}

static void poll_timings_E750x(void) {

	ulong drt, drc, temp;
	float cas;
	int rcd, rp, ras;

	pci_conf_read( 0, 0, 0, 0x78, 4, &drt);
	pci_conf_read( 0, 0, 0, 0x7C, 4, &drc);

	if ((drt >> 4) & 1) { cas = 2; } else { cas = 2.5; };
	if ((drt >> 1) & 1) { rcd = 2; } else { rcd = 3; };
	if (drt & 1) { rp = 2; } else { rp = 3; };

	temp = ((drt >> 9) & 3);
	if (temp == 2) { ras = 5; } else if (temp == 1) { ras = 6; } else { ras = 7; }

	print_timings_info(cas, rcd, rp, ras);

	if (((drc >> 22)&1) == 1) {
		cprint(LINE_CPU+5, col2, "/ Dual Channel (128 bits)");
	} else {
		cprint(LINE_CPU+5, col2, "/ Single Channel (64 bits)");
	}

}

static void poll_timings_i852(void) {

	ulong drt, temp;

	pci_conf_read( 0, 0, 1, 0x60, 4, &drt);

	/* Now, we could print some additionnals timings infos) */
	cprint(LINE_CPU+5, col2 +1, "/ CAS : ");
	col2 += 9;

	// CAS Latency (tCAS)
	temp = ((drt >> 5)&0x1);
	if (temp == 0x0) { cprint(LINE_CPU+5, col2, "2.5-"); col2 += 4;  }
	else { cprint(LINE_CPU+5, col2, "2-"); col2 +=2; }

	// RAS-To-CAS (tRCD)
	temp = ((drt >> 2)& 0x3);
	if (temp == 0x0) { cprint(LINE_CPU+5, col2, "4-"); }
	if (temp == 0x1) { cprint(LINE_CPU+5, col2, "3-"); }
	else { cprint(LINE_CPU+5, col2, "2-"); }
	col2 +=2;

	// RAS Precharge (tRP)
	temp = (drt&0x3);
	if (temp == 0x0) { cprint(LINE_CPU+5, col2, "4-"); }
	if (temp == 0x1) { cprint(LINE_CPU+5, col2, "3-"); }
	else { cprint(LINE_CPU+5, col2, "2-"); }
	col2 +=2;

	// RAS Active to precharge (tRAS)
	temp = ((drt >> 9)& 0x3);
	if (temp == 0x0) { cprint(LINE_CPU+5, col2, "8"); col2 +=7; }
	if (temp == 0x1) { cprint(LINE_CPU+5, col2, "7"); col2 +=6; }
	if (temp == 0x2) { cprint(LINE_CPU+5, col2, "6"); col2 +=5; }
	if (temp == 0x3) { cprint(LINE_CPU+5, col2, "5"); col2 +=5; }
	col2 +=1;

}

static void poll_timings_amd64(void) {

	ulong dramtlr, dramclr;
	int temp;
	int trcd, trp, tras ;

	cprint(LINE_CPU+5, col2 +1, "/ CAS : ");
	col2 += 9;
	
	pci_conf_read(0, 24, 2, 0x88, 4, &dramtlr);
	pci_conf_read(0, 24, 2, 0x90, 4, &dramclr);

	// CAS Latency (tCAS)
	temp = (dramtlr & 0x7);
	if (temp == 0x1) { cprint(LINE_CPU+5, col2, "2-"); col2 +=2; }
	if (temp == 0x2) { cprint(LINE_CPU+5, col2, "3-"); col2 +=2; }
	if (temp == 0x5) { cprint(LINE_CPU+5, col2, "2.5-"); col2 +=4; }

	// RAS-To-CAS (tRCD)
	trcd = ((dramtlr >> 12) & 0x7);
	dprint(LINE_CPU+5, col2, trcd , 1 ,0);
	cprint(LINE_CPU+5, col2 +1, "-"); col2 +=2;

	// RAS Precharge (tRP)
	trp = ((dramtlr >> 24) & 0x7);
	dprint(LINE_CPU+5, col2, trp , 1 ,0);
	cprint(LINE_CPU+5, col2 +1, "-"); col2 +=2;

	// RAS Active to precharge (tRAS)
	tras = ((dramtlr >> 20) & 0xF);
	if (tras < 10){
	dprint(LINE_CPU+5, col2, tras , 1 ,0); col2 += 1;
	} else {
	dprint(LINE_CPU+5, col2, tras , 2 ,0); col2 += 2;
	}
	cprint(LINE_CPU+5, col2+1, "/"); col2 +=2;

	// Print 64 or 128 bits mode

	if (((dramclr >> 16)&1) == 1) {
		cprint(LINE_CPU+5, col2, " Dual Channel (128 bits)");
		col2 +=24;
	} else {
		cprint(LINE_CPU+5, col2, " Single Channel (64 bits)");
		col2 +=15;
	}
}

static void poll_timings_nf2(void) {

	ulong dramtlr, dramtlr2, dramtlr3, temp;
	ulong dimm1p, dimm2p, dimm3p;

	pci_conf_read(0, 0, 1, 0x90, 4, &dramtlr);
	pci_conf_read(0, 0, 1, 0xA0, 4, &dramtlr2);
	pci_conf_read(0, 0, 1, 0x84, 4, &dramtlr3);
	pci_conf_read(0, 0, 2, 0x40, 4, &dimm1p);
	pci_conf_read(0, 0, 2, 0x44, 4, &dimm2p);
	pci_conf_read(0, 0, 2, 0x48, 4, &dimm3p);

	cprint(LINE_CPU+5, col2 +1, "/ CAS : ");
	col2 += 9;

	// CAS Latency (tCAS)
	temp = ((dramtlr2 >> 4) & 0x7);
	if (temp == 0x2) { cprint(LINE_CPU+5, col2, "2-"); col2 +=2; }
	if (temp == 0x3) { cprint(LINE_CPU+5, col2, "3-"); col2 +=2; }
	if (temp == 0x6) { cprint(LINE_CPU+5, col2, "2.5-"); col2 +=4; }

	// RAS-To-CAS (tRCD)
	temp = ((dramtlr >> 20) & 0xF);
	dprint(LINE_CPU+5, col2, temp , 1 ,0);
	cprint(LINE_CPU+5, col2 +1, "-"); col2 +=2;

	// RAS Precharge (tRP)
	temp = ((dramtlr >> 28) & 0xF);
	dprint(LINE_CPU+5, col2, temp , 1 ,0);
	cprint(LINE_CPU+5, col2 +1, "-"); col2 +=2;

	// RAS Active to precharge (tRAS)
	temp = ((dramtlr >> 15) & 0xF);
	if (temp < 10){
		dprint(LINE_CPU+5, col2, temp , 1 ,0); col2 += 1;
	} else {
		dprint(LINE_CPU+5, col2, temp , 2 ,0); col2 += 2;
	}
		cprint(LINE_CPU+5, col2+1, "/"); col2 +=2;

	// Print 64 or 128 bits mode
	// If DIMM1 & DIMM3 or DIMM1 & DIMM2 populated, than Dual Channel.

	if ((dimm3p&1) + (dimm2p&1) == 2 || (dimm3p&1) + (dimm1p&1) == 2 ) {
		cprint(LINE_CPU+5, col2, " Dual Channel (128 bits)");
		col2 +=24;
	} else {
		cprint(LINE_CPU+5, col2, " Single Channel (64 bits)");
		col2 +=15;
	}

}



/* ------------------ Let's continue ------------------ */
/* ---------------------------------------------------- */

static struct pci_memory_controller controllers[] = {
	/* Default unknown chipset */
	{ 0, 0, "",                    0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },

	/* AMD */
	{ 0x1022, 0x7006, "AMD 751",   0, poll_fsb_nothing, poll_timings_nothing, setup_amd751, poll_amd751 },
	{ 0x1022, 0x700c, "AMD 762",   0, poll_fsb_nothing, poll_timings_nothing, setup_amd76x, poll_amd76x },
	{ 0x1022, 0x700e, "AMD 761",   0, poll_fsb_nothing, poll_timings_nothing, setup_amd76x, poll_amd76x },
	{ 0x1022, 0x1100, "AMD 8000",  0, poll_fsb_amd64, poll_timings_amd64, setup_amd64, poll_amd64 },
	{ 0x1022, 0x7454, "AMD 8000",  0, poll_fsb_amd64, poll_timings_amd64, setup_amd64, poll_amd64 },

	/* SiS */
	{ 0x1039, 0x0600, "SiS 600",   0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1039, 0x0620, "SiS 620",   0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1039, 0x5600, "SiS 5600",  0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1039, 0x0645, "SiS 645",   0, poll_fsb_p4, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1039, 0x0646, "SiS 645DX", 0, poll_fsb_p4, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1039, 0x0630, "SiS 630",   0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1039, 0x0650, "SiS 650",   0, poll_fsb_p4, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1039, 0x0651, "SiS 651",   0, poll_fsb_p4, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1039, 0x0730, "SiS 730",   0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1039, 0x0735, "SiS 735",   0, poll_fsb_amd32, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1039, 0x0740, "SiS 740",   0, poll_fsb_amd32, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1039, 0x0745, "SiS 745",   0, poll_fsb_amd32, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1039, 0x0755, "SiS 755",   0, poll_fsb_amd64, poll_timings_amd64, setup_amd64, poll_amd64 },
	{ 0x1039, 0x0748, "SiS 748",   0, poll_fsb_amd32, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1039, 0x0655, "SiS 655",   0, poll_fsb_p4, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1039, 0x0648, "SiS 648",   0, poll_fsb_p4, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1039, 0x0661, "SiS 661",   0, poll_fsb_p4, poll_timings_nothing, setup_nothing, poll_nothing },

	/* ALi */
	{ 0x10b9, 0x1531, "Aladdin 4", 0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x10b9, 0x1541, "Aladdin 5", 0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x10b9, 0x1687, "ALi M1687", 0, poll_fsb_amd64, poll_timings_amd64, setup_amd64, poll_amd64 },

	/* ATi */
	{ 0x1002, 0x5830, "ATi Radeon 9100 IGP", 0, poll_fsb_p4, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1002, 0x5831, "ATi Radeon 9100 IGP", 0, poll_fsb_p4, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1002, 0x5832, "ATi Radeon 9100 IGP", 0, poll_fsb_p4, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1002, 0x5833, "ATi Radeon 9100 IGP", 0, poll_fsb_p4, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1002, 0x5954, "ATi Radeon xPress 200", 0, poll_fsb_p4, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1002, 0x5A41, "ATi Radeon xPress 200", 0, poll_fsb_p4, poll_timings_nothing, setup_nothing, poll_nothing },

	/* nVidia */
	{ 0x10de, 0x01A4, "nVidia nForce", 0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x10de, 0x01E0, "nVidia nForce2 SPP", 0, poll_fsb_nf2, poll_timings_nf2, setup_nothing, poll_nothing },
	{ 0x10de, 0x00D1, "nVidia nForce3", 0, poll_fsb_amd64, poll_timings_amd64, setup_amd64, poll_amd64 },
	{ 0x10de, 0x00E1, "nForce3 250", 0, poll_fsb_amd64, poll_timings_amd64, setup_amd64, poll_amd64 },
	{ 0x10de, 0x005E, "nVidia nForce4", 0, poll_fsb_amd64, poll_timings_amd64, setup_amd64, poll_amd64 },
	{ 0x10de, 0x0071, "nForce4 SLI Intel Edition", 0, poll_fsb_nf4ie, poll_timings_nf4ie, setup_nothing, poll_nothing },

	/* VIA */
	{ 0x1106, 0x0305, "VIA KT133/KT133A",    0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x0391, "vt8371",    0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x0501, "vt8501",    0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x0585, "vt82c585",  0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x0595, "vt82c595",  0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x0597, "vt82c597",  0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x0598, "VT82C598",  0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x0691, "VT82C691/693A/694X",  0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x0693, "VT82C693",  0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x0601, "VIA PLE133",  0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x3099, "VIA KT266(A)/KT333", 0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x3189, "VIA KT400(A)/600", 0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x0269, "VIA KT880", 0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x3205, "VIA KM400", 0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x3116, "VIA KM266", 0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x3156, "VIA KN266", 0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x3123, "VIA CLE266", 0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x0198, "VIA PT800", 0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x3258, "VIA PT880", 0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x1106, 0x3188, "VIA K8T800", 0, poll_fsb_amd64, poll_timings_amd64, setup_amd64, poll_amd64 },
	{ 0x1106, 0x0282, "VIA K8T800Pro", 0, poll_fsb_amd64, poll_timings_amd64, setup_amd64, poll_amd64 },
	{ 0x1106, 0x3238, "VIA K8T890", 0, poll_fsb_amd64, poll_timings_amd64, setup_amd64, poll_amd64 },

	/* Serverworks */
	{ 0x1166, 0x0008, "CNB20HE",   0, poll_fsb_nothing, poll_timings_nothing, setup_cnb20, poll_nothing },
	{ 0x1166, 0x0009, "CNB20LE",   0, poll_fsb_nothing, poll_timings_nothing, setup_cnb20, poll_nothing },

	/* Intel */
	{ 0x8086, 0x1130, "Intel i815",      0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x8086, 0x122d, "Intel i430fx",    0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x8086, 0x1237, "Intel i440fx",    0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x8086, 0x1250, "Intel i430hx",    0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x8086, 0x1A21, "Intel i840",      0, poll_fsb_nothing, poll_timings_nothing, setup_i840, poll_i840 },
	{ 0x8086, 0x1A30, "Intel i845",      0, poll_fsb_p4, poll_timings_nothing, setup_i845, poll_i845 },
	{ 0x8086, 0x2560, "Intel i845E/G/PE/GE", 0, poll_fsb_p4, poll_timings_nothing, setup_i845, poll_i845 },
	{ 0x8086, 0x2500, "Intel i820",      0, poll_fsb_nothing, poll_timings_nothing, setup_i820, poll_i820 },
	{ 0x8086, 0x2530, "Intel i850",      0, poll_fsb_p4, poll_timings_nothing, setup_i850, poll_i850 },
	{ 0x8086, 0x2531, "Intel i860",      1, poll_fsb_nothing, poll_timings_nothing, setup_i860, poll_i860 },
	{ 0x8086, 0x7030, "Intel i430vx",    0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x8086, 0x7120, "Intel i810",      0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x8086, 0x7122, "Intel i810",      0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x8086, 0x7124, "Intel i810e",     0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x8086, 0x7180, "Intel i440[le]x", 0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x8086, 0x7190, "Intel i440BX",    0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x8086, 0x7192, "Intel i440BX",    0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x8086, 0x71A0, "Intel i440gx",    0, poll_fsb_nothing, poll_timings_nothing, setup_i440gx, poll_i440gx },
	{ 0x8086, 0x71A2, "Intel i440gx",    0, poll_fsb_nothing, poll_timings_nothing, setup_i440gx, poll_i440gx },
	{ 0x8086, 0x84C5, "Intel i450gx",    0, poll_fsb_nothing, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x8086, 0x2540, "Intel E7500",     1, poll_fsb_p4, poll_timings_E750x, setup_iE7xxx, poll_iE7xxx },
	{ 0x8086, 0x254C, "Intel E7501",     1, poll_fsb_p4, poll_timings_E750x, setup_iE7xxx, poll_iE7xxx },
	{ 0x8086, 0x255d, "Intel E7205",     0, poll_fsb_p4, poll_timings_nothing, setup_iE7xxx, poll_iE7xxx },
  { 0x8086, 0x3592, "Intel E7320",     0, poll_fsb_p4, poll_timings_E7520, setup_iE7520, poll_iE7520 },
  { 0x8086, 0x2588, "Intel E7221",     1, poll_fsb_i925, poll_timings_i925, setup_i925, poll_iE7221 },
  { 0x8086, 0x3590, "Intel E7520",     0, poll_fsb_p4, poll_timings_E7520, setup_iE7520, poll_nothing },
  { 0x8086, 0x2600, "Intel E8500",     0, poll_fsb_p4, poll_timings_nothing, setup_nothing, poll_nothing },
	{ 0x8086, 0x2570, "Intel i848/i865", 0, poll_fsb_i875, poll_timings_i875, setup_i875, poll_nothing },
	{ 0x8086, 0x2578, "Intel i875P",     0, poll_fsb_i875, poll_timings_i875, setup_i875, poll_i875 },
	{ 0x8086, 0x2550, "Intel E7505",     0, poll_fsb_p4, poll_timings_nothing, setup_iE7xxx, poll_iE7xxx },
	{ 0x8086, 0x3580, "Intel ",          0, poll_fsb_i855, poll_timings_i852, setup_nothing, poll_nothing },
	{ 0x8086, 0x3340, "Intel i855PM",    0, poll_fsb_i855, poll_timings_i855, setup_nothing, poll_nothing },
	{ 0x8086, 0x2580, "Intel i915P/G",   0, poll_fsb_i925, poll_timings_i925, setup_i925, poll_nothing },
	{ 0x8086, 0x2590, "Intel i915PM/GM", 0, poll_fsb_i925, poll_timings_i925, setup_i925, poll_nothing },
	{ 0x8086, 0x2584, "Intel i925X/XE",  0, poll_fsb_i925, poll_timings_i925, setup_i925, poll_iE7221 },
	{ 0x8086, 0x2770, "Intel i945P/G", 	 0, poll_fsb_i945, poll_timings_i925, setup_i925, poll_nothing },
	{ 0x8086, 0x2774, "Intel i955X", 		 0, poll_fsb_i945, poll_timings_i925, setup_i925, poll_nothing}
};

static void print_memory_controller(void)
{
	/* Print memory controller info */

	int d;

	char *name;
	if (ctrl.index == 0) {
		return;
	}

	/* Print the controller name */
	name = controllers[ctrl.index].name;
	col = 10;
	cprint(LINE_CPU+4, col, name);
	/* Now figure out how much I just printed */
	while(name[col - 10] != '\0') {
		col++;
	}
	/* Now print the memory controller capabilities */
	cprint(LINE_CPU+4, col, " "); col++;
	if (ctrl.cap == ECC_UNKNOWN) {
		return;
	}
	if (ctrl.cap & __ECC_DETECT) {
		int on;
		on = ctrl.mode & __ECC_DETECT;
		cprint(LINE_CPU+4, col, "(ECC : ");
		cprint(LINE_CPU+4, col +7, on?"Detect":"Disabled)");
		on?(col += 13):(col += 16);
	}
	if (ctrl.mode & __ECC_CORRECT) {
		int on;
		on = ctrl.mode & __ECC_CORRECT;
		cprint(LINE_CPU+4, col, " / ");
		if (ctrl.cap & __ECC_CHIPKILL) {
		cprint(LINE_CPU+4, col +3, on?"Correct -":"");
		on?(col += 12):(col +=3);
		} else {
			cprint(LINE_CPU+4, col +3, on?"Correct)":"");
			on?(col += 11):(col +=3);
		}
	}
	if (ctrl.mode & __ECC_DETECT) {
	if (ctrl.cap & __ECC_CHIPKILL) {
		int on;
		on = ctrl.mode & __ECC_CHIPKILL;
		cprint(LINE_CPU+4, col, " Chipkill : ");
		cprint(LINE_CPU+4, col +12, on?"On)":"Off)");
		on?(col += 15):(col +=16);
	}}
	if (ctrl.mode & __ECC_SCRUB) {
		int on;
		on = ctrl.mode & __ECC_SCRUB;
		cprint(LINE_CPU+4, col, " Scrub");
		cprint(LINE_CPU+4, col +6, on?"+ ":"- ");
		col += 7;
	}
	if (ctrl.cap & __ECC_UNEXPECTED) {
		int on;
		on = ctrl.mode & __ECC_UNEXPECTED;
		cprint(LINE_CPU+4, col, "Unknown");
		cprint(LINE_CPU+4, col +7, on?"+ ":"- ");
		col += 9;
	}


	/* Print advanced caracteristics  */
	col2 = 0;
	d = get_key();
	/* if F1 is pressed, disable advanced detection */
	if (d != 0x3B) {
	controllers[ctrl.index].poll_fsb();
	controllers[ctrl.index].poll_timings();
	}
}


void find_controller(void)
{
	unsigned long vendor;
	unsigned long device;
	int i;
	int result;
	result = pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, PCI_VENDOR_ID, 2, &vendor);
	result = pci_conf_read(ctrl.bus, ctrl.dev, ctrl.fn, PCI_DEVICE_ID, 2, &device);
	ctrl.index = 0;	
		if (result == 0) {
			for(i = 1; i < sizeof(controllers)/sizeof(controllers[0]); i++) {
				if ((controllers[i].vendor == vendor) && (controllers[i].device == device)) {
					ctrl.index = i;
					break;
				}
			}
		}
		
	controllers[ctrl.index].setup_ecc();
	/* Don't enable ECC polling by default unless it has
	 * been well tested.
	 */
	set_ecc_polling(-1);
	print_memory_controller();

}

void poll_errors(void)
{
	if (ctrl.poll) {
		controllers[ctrl.index].poll_errors();
	}
}

void set_ecc_polling(int val)
{
	int tested = controllers[ctrl.index].tested;
	if (val == -1) {
		val = tested;
	}
	if (val && (ctrl.mode & __ECC_DETECT)) {
		ctrl.poll = 1;
		cprint(LINE_INFO, COL_ECC, tested? " on": " ON");
	} else {
		ctrl.poll = 0;
		cprint(LINE_INFO, COL_ECC, "off");
	}
}


