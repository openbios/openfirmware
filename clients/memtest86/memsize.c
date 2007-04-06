/* memsize.c - MemTest-86  Version 3.3
 *
 * Released under version 2 of the Gnu Public License.
 * By Chris Brady
 */

#include "test.h"
#include "defs.h"
#include "config.h"

short e820_nr;
short memsz_mode = SZ_MODE_PROBE;
short firmware = FIRMWARE_UNKNOWN;

static ulong alt_mem_k;
static ulong ext_mem_k;
static struct e820entry e820[E820MAX];

extern ulong p1, p2;
extern volatile ulong *p;

static void sort_pmap(void);
static int check_ram(void);
static void memsize_bios(int res);
static void memsize_820(int res);
static void memsize_801(void);
static int sanitize_e820_map(struct e820entry *orig_map, struct e820entry *new_bios,
	short old_nr, short res);
static void memsize_linuxbios();
static void memsize_probe(void);
static int check_ram(void);

/*
 * Find out how much memory there is.
 */
void mem_size(void)
{
	int i;
	v->reserved_pages = 0;
	v->test_pages = 0;

	/* On the first time thru only */
	/* Make a copy of the memory info table so that we can re-evaluate */
	/* The memory map later */
	if (e820_nr == 0 && alt_mem_k == 0 && ext_mem_k == 0) {
		ext_mem_k = mem_info.e88_mem_k;
		alt_mem_k = mem_info.e801_mem_k;
		e820_nr   = mem_info.e820_nr;
		for (i=0; i< mem_info.e820_nr; i++) {
			e820[i].addr = mem_info.e820[i].addr;
			e820[i].size = mem_info.e820[i].size;
			e820[i].type = mem_info.e820[i].type;
		}
	}

	switch (memsz_mode) {
	case SZ_MODE_BIOS:
		/* Get the memory size from the BIOS */
		memsize_bios(0);
		break;
	case SZ_MODE_BIOS_RES:
		/* Get the memory size from the BIOS, include reserved mem */
		memsize_bios(1);
		break;
	case SZ_MODE_PROBE:
		/* Probe to find memory */
		memsize_probe();
		cprint(LINE_INFO, COL_MMAP, " Probed ");
		break;
	}
	/* Guarantee that pmap entries are in ascending order */
	sort_pmap();
	v->plim_lower = 0;
	v->plim_upper = v->pmap[v->msegs-1].end;

	adj_mem();
	aprint(LINE_INFO, COL_RESERVED, v->reserved_pages);
}

static void memsize_bios(int res)
{
	if (firmware == FIRMWARE_PCBIOS) {
		memsize_820(res);
	}
	else if (firmware == FIRMWARE_LINUXBIOS) {
		memsize_linuxbios();
	}
}

static void sort_pmap(void)
{
	int i, j;
	/* Do an insertion sort on the pmap, on an already sorted
	 * list this should be a O(1) algorithm.
	 */
	for(i = 0; i < v->msegs; i++) {
		/* Find where to insert the current element */
		for(j = i -1; j >= 0; j--) {
			if (v->pmap[i].start > v->pmap[j].start) {
				j++;
				break;
			}
		}
		/* Insert the current element */
		if (i != j) {
			struct pmap temp;
			temp = v->pmap[i];
			memmove(&v->pmap[j], &v->pmap[j+1], 
				(i -j)* sizeof(temp));
			v->pmap[j] = temp;
		}
	}
}
static void memsize_linuxbios(void)
{
	int i, n;
	/* Build the memory map for testing */
	n = 0;
	for (i=0; i < e820_nr; i++) {
		unsigned long long end;
		if (e820[i].type != E820_RAM) {
			continue;
		}
		end = e820[i].addr;
		end += e820[i].size;
		v->pmap[n].start = (e820[i].addr + 4095) >> 12;
		v->pmap[n].end = end >> 12;
		v->test_pages += v->pmap[n].end - v->pmap[n].start;
		n++;
	}
	v->msegs = n;
	cprint(LINE_INFO, COL_MMAP, "LinuxBIOS");
}
static void memsize_820(int res)
{
	int i, n, nr;
	struct e820entry nm[E820MAX];

	/* Clean up, adjust and copy the BIOS-supplied E820-map. */
	/* If the res arg is true reclassify reserved memory as E820_RAM */
	nr = sanitize_e820_map(e820, nm, e820_nr, res);

	/* If there is not a good 820 map use the BIOS 801/88 info */
	if (nr < 1 || nr > E820MAX) {
		memsize_801();
		return;
	}

	/* Build the memory map for testing */
	n = 0;
	for (i=0; i<nr; i++) {
		if (nm[i].type == E820_RAM) {
			unsigned long long start;
			unsigned long long end;
			start = nm[i].addr;
			end = start + nm[i].size;

			/* Don't ever use memory between 640 and 1024k */
			if (start > RES_START && start < RES_END) {
				if (end < RES_END) {
					continue;
				}
				start = RES_END;
			}
			if (end > RES_START && end < RES_END) {
				end = RES_START;
			}
			v->pmap[n].start = (start + 4095) >> 12;
			v->pmap[n].end = end >> 12;
			v->test_pages += v->pmap[n].end - v->pmap[n].start;
			n++;
		} else {
			/* If this is reserved memory starting at the top
			 * of memory then don't count it as reserved, since
			 * it is very unlikely to be real memory.
			 */
			if (nm[i].addr < 0xff000000) {
				v->reserved_pages += nm[i].size >> 12;
			}
		}
	}
	v->msegs = n;
	if (res) {
		cprint(LINE_INFO, COL_MMAP, "e820-All");
	} else {
		cprint(LINE_INFO, COL_MMAP, "e820-Std");
	}
}
	
static void memsize_801(void)
{
	ulong mem_size;

	/* compare results from 88 and 801 methods and take the greater */
	/* These sizes are for extended memory in 1k units. */

	if (alt_mem_k < ext_mem_k) {
		mem_size = ext_mem_k;
		cprint(LINE_INFO, COL_MMAP, "e88-Std ");
	} else {
		mem_size = alt_mem_k;
		cprint(LINE_INFO, COL_MMAP, "e801-Std");
	}
	/* First we map in the first 640k */
	v->pmap[0].start = 0;
	v->pmap[0].end = RES_START >> 12;
	v->test_pages = RES_START >> 12;

	/* Now the extended memory */
	v->pmap[1].start = (RES_END + 4095) >> 12;
	v->pmap[1].end = (mem_size + 1024) >> 2;
	v->test_pages += mem_size >> 2;
	v->msegs = 2;
}

/*
 * Sanitize the BIOS e820 map.
 *
 * Some e820 responses include overlapping entries.  The following 
 * replaces the original e820 map with a new one, removing overlaps.
 *
 */
static int sanitize_e820_map(struct e820entry *orig_map, struct e820entry *new_bios,
	short old_nr, short res)
{
	struct change_member {
		struct e820entry *pbios; /* pointer to original bios entry */
		unsigned long long addr; /* address for this change point */
	};
	struct change_member change_point_list[2*E820MAX];
	struct change_member *change_point[2*E820MAX];
	struct e820entry *overlap_list[E820MAX];
	struct e820entry biosmap[E820MAX];
	struct change_member *change_tmp;
	ulong current_type, last_type;
	unsigned long long last_addr;
	int chgidx, still_changing;
	int overlap_entries;
	int new_bios_entry;
	int i;

	/*
		Visually we're performing the following (1,2,3,4 = memory types)...
		Sample memory map (w/overlaps):
		   ____22__________________
		   ______________________4_
		   ____1111________________
		   _44_____________________
		   11111111________________
		   ____________________33__
		   ___________44___________
		   __________33333_________
		   ______________22________
		   ___________________2222_
		   _________111111111______
		   _____________________11_
		   _________________4______

		Sanitized equivalent (no overlap):
		   1_______________________
		   _44_____________________
		   ___1____________________
		   ____22__________________
		   ______11________________
		   _________1______________
		   __________3_____________
		   ___________44___________
		   _____________33_________
		   _______________2________
		   ________________1_______
		   _________________4______
		   ___________________2____
		   ____________________33__
		   ______________________4_
	*/
	/* First make a copy of the map */
	for (i=0; i<old_nr; i++) {
		biosmap[i].addr = orig_map[i].addr;
		biosmap[i].size = orig_map[i].size;
		biosmap[i].type = orig_map[i].type;
	}

	/* bail out if we find any unreasonable addresses in bios map */
	for (i=0; i<old_nr; i++) {
		if (biosmap[i].addr + biosmap[i].size < biosmap[i].addr)
			return 0;
		if (res) {
			/* If we want to test the reserved memory include
			 * everything except for reserved segments that start
			 * at the  the top of memory
			 */
			if (biosmap[i].type == E820_RESERVED &&
					biosmap[i].addr > 0xff000000) {
				continue;
			}
			biosmap[i].type = E820_RAM;
		} else {
			/* It is always be safe to test ACPI ram */
			if ( biosmap[i].type == E820_ACPI) {
				biosmap[i].type = E820_RAM;
			}
		}
	}

	/* create pointers for initial change-point information (for sorting) */
	for (i=0; i < 2*old_nr; i++)
		change_point[i] = &change_point_list[i];

	/* record all known change-points (starting and ending addresses) */
	chgidx = 0;
	for (i=0; i < old_nr; i++)	{
		change_point[chgidx]->addr = biosmap[i].addr;
		change_point[chgidx++]->pbios = &biosmap[i];
		change_point[chgidx]->addr = biosmap[i].addr + biosmap[i].size;
		change_point[chgidx++]->pbios = &biosmap[i];
	}

	/* sort change-point list by memory addresses (low -> high) */
	still_changing = 1;
	while (still_changing)	{
		still_changing = 0;
		for (i=1; i < 2*old_nr; i++)  {
			/* if <current_addr> > <last_addr>, swap */
			/* or, if current=<start_addr> & last=<end_addr>, swap */
			if ((change_point[i]->addr < change_point[i-1]->addr) ||
				((change_point[i]->addr == change_point[i-1]->addr) &&
				 (change_point[i]->addr == change_point[i]->pbios->addr) &&
				 (change_point[i-1]->addr != change_point[i-1]->pbios->addr))
			   )
			{
				change_tmp = change_point[i];
				change_point[i] = change_point[i-1];
				change_point[i-1] = change_tmp;
				still_changing=1;
			}
		}
	}

	/* create a new bios memory map, removing overlaps */
	overlap_entries=0;	 /* number of entries in the overlap table */
	new_bios_entry=0;	 /* index for creating new bios map entries */
	last_type = 0;		 /* start with undefined memory type */
	last_addr = 0;		 /* start with 0 as last starting address */
	/* loop through change-points, determining affect on the new bios map */
	for (chgidx=0; chgidx < 2*old_nr; chgidx++)
	{
		/* keep track of all overlapping bios entries */
		if (change_point[chgidx]->addr == change_point[chgidx]->pbios->addr)
		{
			/* add map entry to overlap list (> 1 entry implies an overlap) */
			overlap_list[overlap_entries++]=change_point[chgidx]->pbios;
		}
		else
		{
			/* remove entry from list (order independent, so swap with last) */
			for (i=0; i<overlap_entries; i++)
			{
				if (overlap_list[i] == change_point[chgidx]->pbios)
					overlap_list[i] = overlap_list[overlap_entries-1];
			}
			overlap_entries--;
		}
		/* if there are overlapping entries, decide which "type" to use */
		/* (larger value takes precedence -- 1=usable, 2,3,4,4+=unusable) */
		current_type = 0;
		for (i=0; i<overlap_entries; i++)
			if (overlap_list[i]->type > current_type)
				current_type = overlap_list[i]->type;
		/* continue building up new bios map based on this information */
		if (current_type != last_type)	{
			if (last_type != 0)	 {
				new_bios[new_bios_entry].size =
					change_point[chgidx]->addr - last_addr;
				/* move forward only if the new size was non-zero */
				if (new_bios[new_bios_entry].size != 0)
					if (++new_bios_entry >= E820MAX)
						break; 	/* no more space left for new bios entries */
			}
			if (current_type != 0)	{
				new_bios[new_bios_entry].addr = change_point[chgidx]->addr;
				new_bios[new_bios_entry].type = current_type;
				last_addr=change_point[chgidx]->addr;
			}
			last_type = current_type;
		}
	}
	return(new_bios_entry);
}

static void memsize_probe(void)
{
	int i, n;
	ulong m_lim;
	static unsigned long magic = 0x1234569;

	/* Since all address bits may not be decoded, the search for memory
	 * must be limited.  The max address is found by checking for
	 * memory wrap from 1MB to 4GB.  */
	p1 = (ulong)&magic;
	m_lim = 0xfffffffc; 
	for (p2 = 0x100000; p2; p2 <<= 1) {  
		p = (ulong *)(p1 + p2);
		if (*p == 0x1234569) {
			m_lim = --p2;
			break;
		}
	}

	/* Turn on cache */
	set_cache(1);

	/* Find all segments of RAM */

	i = 0;
	v->pmap[i].start = ((ulong)&_end + (1 << 12) - 1) >> 12;
	p = (ulong *)(v->pmap[i].start << 12);

	/* Limit search for memory to m_lim and make sure we don't 
	 * overflow the 32 bit size of p.  */
	while ((ulong)p < m_lim && (ulong)p >= (ulong)&_end) {
		/*
		 * Skip over reserved memory
		 */
		if ((ulong)p < RES_END && (ulong)p >= RES_START) {
			v->pmap[i].end = RES_START >> 12;
			v->test_pages += (v->pmap[i].end - v->pmap[i].start);
			p = (ulong *)RES_END;
			i++;
			v->pmap[i].start = 0;
			goto fstart;
		}

		if (check_ram() == 0) {
			/* ROM or nothing at this address, record end addrs */
			v->pmap[i].end = ((ulong)p) >> 12;
			v->test_pages += (v->pmap[i].end - v->pmap[i].start);
			i++;
			v->pmap[i].start = 0;
fstart:

			/* We get here when there is a gap in memory.
			 * Loop until we find more ram, the gap is more
			 * than 32768k or we hit m_lim */
			n = 32768 >> 2;
			while ((ulong)p < m_lim && (ulong)p >= (ulong)&_end) {

				/* Skip over video memory */
				if ((ulong)p < RES_END &&
					(ulong)p >= RES_START) {
					p = (ulong *)RES_END;
				}
				if (check_ram() == 1) {
					/* More RAM, record start addrs */
					v->pmap[i].start = (ulong)p >> 12;
					break;
				}

				/* If the gap is 32768k or more then there
				 * is probably no more memory so bail out */
				if (--n <= 0) {
					p = (ulong *)m_lim;
					break;
				}
				p += 0x1000;
			}
		}
		p += 0x1000;
	}

	/* If there is ram right up to the memory limit this will record
	 * the last address.  */
	if (v->pmap[i].start) {
		v->pmap[i].end = m_lim >> 12;
		v->test_pages += (v->pmap[i].end - v->pmap[i].start);
		i++;
	}
	v->msegs = i;
}

/* check_ram - Determine if this address points to memory by checking
 * for a wrap pattern and then reading and then writing the complement.
 * We then check that at least one bit changed in each byte before
 * believing that it really is memory.  */

static int check_ram(void) 
{
        int s;

        p1 = *p;

        /* write the complement */
        *p = ~p1;
        p2 = *p;
        s = 0;

        /* Now make sure a bit changed in each byte */
        if ((0xff & p1) != (0xff & p2)) {
                s++;
        }
        if ((0xff00 & p1) != (0xff00 & p2)) {
                s++;
        }
        if ((0xff0000 & p1) != (0xff0000 & p2)) {
                s++;
        }
        if ((0xff000000 & p1) != (0xff000000 & p2)) {
                s++;
        }
        if (s == 4) {
                /* RAM at this address */
                return 1;
        }

        return 0;
}
