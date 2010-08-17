/* test.c - MemTest-86  Version 3.3
 *
 * Released under version 2 of the Gnu Public License.
 * By Chris Brady
 */
#include "test.h"
#include "config.h"
#include "ega.h"
#include <inttypes.h>

extern int segs, bail;
extern volatile ulong *p;
extern ulong p1, p2;
extern int test_ticks, nticks;
extern struct tseq tseq[];
void poll_errors();

int ecount = 0;

static void update_err_counts(void);
static void print_err_counts(void);

static inline ulong roundup(ulong value, ulong mask)
{
	return (value + mask) & ~mask;
}
/*
 * Memory address test, walking ones
 */
void addr_tst1()
{
	int i, j, k;
	volatile ulong *pt;
	volatile ulong *end;
	ulong bad, mask, bank;

	/* Test the global address bits */
	for (p1=0, j=0; j<2; j++) {
		hprint(LINE_PAT, COL_PAT, p1);

		/* Set pattern in our lowest multiple of 0x20000 */
		p = (ulong *)roundup((ulong)v->map[0].start, 0x1ffff);
		*p = p1;

		/* Now write pattern compliment */
		p1 = ~p1;
		end = v->map[segs-1].end;
		for (i=0; i<1000; i++) {
			mask = 4;
			do {
				pt = (ulong *)((ulong)p | mask);
				if ((uintptr_t)pt == (uintptr_t)p) {
					mask = mask << 1;
					continue;
				}
				if ((uintptr_t)pt >= (uintptr_t)end) {
					break;
				}
				*pt = p1;
				if ((uintptr_t)(bad = *p) != (uintptr_t)~p1) {
					ad_err1((ulong *)p, (ulong *)mask,
						bad, ~p1);
					i = 1000;
				}
				mask = mask << 1;
			} while(mask);
		}
		do_tick();
		BAILR
	}

	/* Now check the address bits in each bank */
	/* If we have more than 8mb of memory then the bank size must be */
	/* bigger than 256k.  If so use 1mb for the bank size. */
	if (v->pmap[v->msegs - 1].end > (0x800000 >> 12)) {
		bank = 0x100000;
	} else {
		bank = 0x40000;
	}
	for (p1=0, k=0; k<2; k++) {
		hprint(LINE_PAT, COL_PAT, p1);

		for (j=0; j<segs; j++) {
			p = v->map[j].start;
			/* Force start address to be a multiple of 256k */
			p = (ulong *)roundup((ulong)p, bank - 1);
			end = v->map[j].end;
			while ((uintptr_t)p < (uintptr_t)end) {
				*p = p1;

				p1 = ~p1;
				for (i=0; i<200; i++) {
					mask = 4;
					do {
						pt = (ulong *)
						    ((ulong)p | mask);
						if ((uintptr_t)pt == (uintptr_t)p) {
							mask = mask << 1;
							continue;
						}
						if ((uintptr_t)pt >= (uintptr_t)end) {
							break;
						}
						*pt = p1;
						if ((uintptr_t)(bad = *p) != (uintptr_t)~p1) {
							ad_err1((ulong *)p,
							        (ulong *)mask,
							        bad,~p1);
							i = 200;
						}
						mask = mask << 1;
					} while(mask);
				}
				if ((uintptr_t)(p + bank) > (uintptr_t)p) {
					p += bank;
				} else {
					p = end;
				}
				p1 = ~p1;
			}
		}
		do_tick();
		BAILR
		p1 = ~p1;
	}
}

/*
 * Memory address test, own address
 */
void addr_tst2()
{
	int j, done;
	volatile ulong *pe;
	volatile ulong *end, *start;

	cprint(LINE_PAT, COL_PAT, "        ");

	/* Write each address with it's own address */
	for (j=0; j<segs; j++) {
		start = v->map[j].start;
		end = v->map[j].end;
		pe = (ulong *)start;
		p = start;
		done = 0;
		do {
			/* Check for overflow */
			if ((uintptr_t)(pe + SPINSZ) > (uintptr_t)pe) {
				pe += SPINSZ;
			} else {
				pe = end;
			}
			if ((uintptr_t)pe >= (uintptr_t)end) {
				pe = end;
				done++;
			}
			if ((uintptr_t)p == (uintptr_t)pe) {
				break;
			}

/* Original C code replaced with hand tuned assembly code
 *			for (; p < pe; p++) {
 *				*p = (ulong)p;
 *			}
 */
			asm __volatile__ (
				"jmp L90\n\t"

				".p2align 4,,7\n\t"
				"L90:\n\t"
				"movl %%edi,(%%edi)\n\t"
				"addl $4,%%edi\n\t"
				"cmpl %%edx,%%edi\n\t"
				"jb L90\n\t"
				: "=D" (p)
				: "D" (p), "d" (pe)
			);
			do_tick();
			BAILR
		} while (!done);
	}

	/* Each address should have its own address */
	for (j=0; j<segs; j++) {
		start = v->map[j].start;
		end = v->map[j].end;
		pe = (ulong *)start;
		p = start;
		done = 0;
		do {
			/* Check for overflow */
			if ((uintptr_t)(pe + SPINSZ) > (uintptr_t)pe) {
				pe += SPINSZ;
			} else {
				pe = end;
			}
			if ((uintptr_t)pe >= (uintptr_t)end) {
				pe = end;
				done++;
			}
			if ((uintptr_t)p == (uintptr_t)pe ) {
				break;
			}
/* Original C code replaced with hand tuned assembly code
 *			for (; p < pe; p++) {
 *				if((bad = *p) != (ulong)p) {
 *					ad_err2((ulong)p, bad);
 *				}
 *			}
 */
			asm __volatile__ (
				"jmp L91\n\t"

				".p2align 4,,7\n\t"
				"L91:\n\t"
				"movl (%%edi),%%ecx\n\t"
				"cmpl %%edi,%%ecx\n\t"
				"jne L93\n\t"
				"L92:\n\t"
				"addl $4,%%edi\n\t"
				"cmpl %%edx,%%edi\n\t"
				"jb L91\n\t"
				"jmp L94\n\t"

				"L93:\n\t"
				"pushl %%edx\n\t"
				"pushl %%ecx\n\t"
				"pushl %%edi\n\t"
				"call ad_err2\n\t"
				"popl %%edi\n\t"
				"popl %%ecx\n\t"
				"popl %%edx\n\t"
				"jmp L92\n\t"

				"L94:\n\t"
				: "=D" (p)
				: "D" (p), "d" (pe)
				: "ecx"
			);
			do_tick();
			BAILR
		} while (!done);
	}
}

/*
 * Test all of memory using a "half moving inversions" algorithm using random
 * numbers and their complment as the data pattern. Since we are not able to
 * produce random numbers in reverse order testing is only done in the forward
 * direction.
 */
void movinvr()
{
	int i, j, done, seed1, seed2;
	volatile ulong *pe;
	volatile ulong *start,*end;
	ulong num;

	/* Initialize memory with initial sequence of random numbers.  */
	if (v->rdtsc) {
		asm __volatile__ ("rdtsc":"=a" (seed1),"=d" (seed2));
	} else {
		seed1 = 521288629 + v->pass;
		seed2 = 362436069 - v->pass;
	}

	/* Display the current seed */
	hprint(LINE_PAT, COL_PAT, seed1);
	rand_seed(seed1, seed2);
	for (j=0; j<segs; j++) {
		start = v->map[j].start;
		end = v->map[j].end;
		pe = start;
		p = start;
		done = 0;
		do {
			/* Check for overflow */
			if ((uintptr_t)(pe + SPINSZ) > (uintptr_t)pe) {
				pe += SPINSZ;
			} else {
				pe = end;
			}
			if ((uintptr_t)pe >= (uintptr_t)end) {
				pe = end;
				done++;
			}
			if ((uintptr_t)p == (uintptr_t)pe) {
				break;
			}
/* Original C code replaced with hand tuned assembly code */
/*
			for (; p < pe; p++) {
				*p = rand();
			}
 */

			asm __volatile__ (
				"jmp L200\n\t"
				".p2align 4,,7\n\t"
				"L200:\n\t"
				"call rand\n\t"
				"movl %%eax,(%%edi)\n\t"
				"addl $4,%%edi\n\t"
				"cmpl %%ebx,%%edi\n\t"
				"jb L200\n\t"
				: "=D" (p)
				: "D" (p), "b" (pe)
				: "eax"
			);

			do_tick();
			BAILR
		} while (!done);
	}

	/* Do moving inversions test. Check for initial pattern and then
	 * write the complement for each memory location. Test from bottom
	 * up and then from the top down.  */
	for (i=0; i<2; i++) {
		rand_seed(seed1, seed2);
		for (j=0; j<segs; j++) {
			start = v->map[j].start;
			end = v->map[j].end;
			pe = start;
			p = start;
			done = 0;
			do {
				/* Check for overflow */
				if ((uintptr_t)(pe + SPINSZ) > (uintptr_t)pe) {
					pe += SPINSZ;
				} else {
					pe = end;
				}
				if ((uintptr_t)pe >= (uintptr_t)end) {
					pe = end;
					done++;
				}
				if ((uintptr_t)p == (uintptr_t)pe) {
					break;
				}
/* Original C code replaced with hand tuned assembly code */
/*
				for (; p < pe; p++) {
					num = rand();
					if (i) {
						num = ~num;
					}
					if ((bad=*p) != num) {
						error((ulong*)p, num, bad);
					}
					*p = ~num;
				}
*/
				if (i) {
					num = 0xffffffff;
				} else {
					num = 0;
				}
				asm __volatile__ (
					"jmp L26\n\t" \

					".p2align 4,,7\n\t" \
					"L26:\n\t" \
					"call rand\n\t"
					"xorl %%ebx,%%eax\n\t" \
					"movl (%%edi),%%ecx\n\t" \
					"cmpl %%eax,%%ecx\n\t" \
					"jne L23\n\t" \
					"L25:\n\t" \
					"movl $0xffffffff,%%edx\n\t" \
					"xorl %%edx,%%eax\n\t" \
					"movl %%eax,(%%edi)\n\t" \
					"addl $4,%%edi\n\t" \
					"cmpl %%esi,%%edi\n\t" \
					"jb L26\n\t" \
					"jmp L24\n" \

					"L23:\n\t" \
					"pushl %%esi\n\t" \
					"pushl %%ecx\n\t" \
					"pushl %%eax\n\t" \
					"pushl %%edi\n\t" \
					"call error\n\t" \
					"popl %%edi\n\t" \
					"popl %%eax\n\t" \
					"popl %%ecx\n\t" \
					"popl %%esi\n\t" \
					"jmp L25\n" \

					"L24:\n\t" \
					: "=D" (p)
					: "D" (p), "S" (pe), "b" (num)
					: "eax", "ecx", "edx"
				);
				do_tick();
				BAILR
			} while (!done);
		}
	}
}

/*
 * Test all of memory using a "moving inversions" algorithm using the
 * pattern in p1 and it's complement in p2.
 */
void movinv1(int iter, ulong p1, ulong p2)
{
	int i, j, done;
	volatile ulong *pe;
	volatile ulong len;
	volatile ulong *start,*end;

	/* Display the current pattern */
	hprint(LINE_PAT, COL_PAT, p1);

	/* Initialize memory with the initial pattern.  */
	for (j=0; j<segs; j++) {
		start = v->map[j].start;
		end = v->map[j].end;
		pe = start;
		p = start;
		done = 0;
		do {
			/* Check for overflow */
			if ((uintptr_t)(pe + SPINSZ) > (uintptr_t)pe) {
				pe += SPINSZ;
			} else {
				pe = end;
			}
			if ((uintptr_t)pe >= (uintptr_t)end) {
				pe = end;
				done++;
			}
			len = pe - p;
			if ((uintptr_t)p == (uintptr_t)pe) {
				break;
			}
/* Original C code replaced with hand tuned assembly code
 *			for (; p < pe; p++) {
 *				*p = p1;
 *			}
 */
			asm __volatile__ (
				"rep\n\t" \
				"stosl\n\t"
				: "=D" (p)
				: "c" (len), "0" (p), "a" (p1)
			);
			do_tick();
			BAILR
		} while (!done);
	}

	/* Do moving inversions test. Check for initial pattern and then
	 * write the complement for each memory location. Test from bottom
	 * up and then from the top down.  */
	for (i=0; i<iter; i++) {
		for (j=0; j<segs; j++) {
			start = v->map[j].start;
			end = v->map[j].end;
			pe = start;
			p = start;
			done = 0;
			do {
				/* Check for overflow */
				if ((uintptr_t)(pe + SPINSZ) > (uintptr_t)pe) {
					pe += SPINSZ;
				} else {
					pe = end;
				}
				if ((uintptr_t)pe >= (uintptr_t)end) {
					pe = end;
					done++;
				}
				if ((uintptr_t)p == (uintptr_t)pe) {
					break;
				}
/* Original C code replaced with hand tuned assembly code
 *				for (; p < pe; p++) {
 *					if ((bad=*p) != p1) {
 *						error((ulong*)p, p1, bad);
 *					}
 *					*p = p2;
 *				}
 */
				asm __volatile__ (
					"jmp L2\n\t" \

					".p2align 4,,7\n\t" \
					"L2:\n\t" \
					"movl (%%edi),%%ecx\n\t" \
					"cmpl %%eax,%%ecx\n\t" \
					"jne L3\n\t" \
					"L5:\n\t" \
					"movl %%ebx,(%%edi)\n\t" \
					"addl $4,%%edi\n\t" \
					"cmpl %%edx,%%edi\n\t" \
					"jb L2\n\t" \
					"jmp L4\n" \

					"L3:\n\t" \
					"pushl %%edx\n\t" \
					"pushl %%ebx\n\t" \
					"pushl %%ecx\n\t" \
					"pushl %%eax\n\t" \
					"pushl %%edi\n\t" \
					"call error\n\t" \
					"popl %%edi\n\t" \
					"popl %%eax\n\t" \
					"popl %%ecx\n\t" \
					"popl %%ebx\n\t" \
					"popl %%edx\n\t" \
					"jmp L5\n" \

					"L4:\n\t" \
					: "=D" (p)
					: "a" (p1), "0" (p), "d" (pe), "b" (p2)
					: "ecx"
				);
				do_tick();
				BAILR
			} while (!done);
		}
		for (j=segs-1; j>=0; j--) {
			start = v->map[j].start;
			end = v->map[j].end;
			pe = end -1;
			p = end -1;
			done = 0;
			do {
				/* Check for underflow */
				if ((uintptr_t)(pe - SPINSZ) < (uintptr_t)pe) {
					pe -= SPINSZ;
				} else {
					pe = start;
				}
				if ((uintptr_t)pe <= (uintptr_t)start) {
					pe = start;
					done++;
				}
				if ((uintptr_t)p == (uintptr_t)pe) {
					break;
				}
/* Original C code replaced with hand tuned assembly code
 *				do {
 *					if ((bad=*p) != p2) {
 *						error((ulong*)p, p2, bad);
 *					}
 *					*p = p1;
 *				} while (p-- > pe);
 */
				asm __volatile__ (
					"addl $4, %%edi\n\t"
					"jmp L9\n\t"

					".p2align 4,,7\n\t"
					"L9:\n\t"
					"subl $4, %%edi\n\t"
					"movl (%%edi),%%ecx\n\t"
					"cmpl %%ebx,%%ecx\n\t"
					"jne L6\n\t"
					"L10:\n\t"
					"movl %%eax,(%%edi)\n\t"
					"cmpl %%edi, %%edx\n\t"
					"jne L9\n\t"
					"subl $4, %%edi\n\t"
					"jmp L7\n\t"

					"L6:\n\t"
					"pushl %%edx\n\t"
					"pushl %%eax\n\t"
					"pushl %%ecx\n\t"
					"pushl %%ebx\n\t"
					"pushl %%edi\n\t"
					"call error\n\t"
					"popl %%edi\n\t"
					"popl %%ebx\n\t"
					"popl %%ecx\n\t"
					"popl %%eax\n\t"
					"popl %%edx\n\t"
					"jmp L10\n"

					"L7:\n\t"
					: "=D" (p)
					: "a" (p1), "0" (p), "d" (pe), "b" (p2)
					: "ecx"
				);
				do_tick();
				BAILR
			} while (!done);
		}
	}
}

void movinv32(int iter, ulong p1, ulong lb, ulong hb, int sval, int off)
{
	int i, j, k=0, done;
	volatile ulong *pe;
	volatile ulong *start, *end;
	ulong pat = 0;

	/* Display the current pattern */
	hprint(LINE_PAT, COL_PAT, p1);

	/* Initialize memory with the initial pattern.  */
	for (j=0; j<segs; j++) {
		start = v->map[j].start;
		end = v->map[j].end;
		pe = start;
		p = start;
		done = 0;
		k = off;
		pat = p1;
		do {
			/* Check for overflow */
			if ((uintptr_t)(pe + SPINSZ) > (uintptr_t)pe) {
				pe += SPINSZ;
			} else {
				pe = end;
			}
			if ((uintptr_t)pe >= (uintptr_t)end) {
				pe = end;
				done++;
			}
			if ((uintptr_t)p == (uintptr_t)pe) {
				break;
			}
			/* Do a SPINSZ section of memory */
/* Original C code replaced with hand tuned assembly code
 *			while (p < pe) {
 *				*p = pat;
 *				if (++k >= 32) {
 *					pat = lb;
 *					k = 0;
 *				} else {
 *					pat = pat << 1;
 *					pat |= sval;
 *				}
 *				p++;
 *			}
 */
			asm __volatile__ (
				"jmp L20\n\t"
				".p2align 4,,7\n\t"

/* CDH start */
				"L20:\n\t"
				"movl %%ecx,(%%edi)\n\t"
				"incb %%bl\n\t"
				"addl $4,%%edi\n\t"
				"roll $1,%%ecx\n\t"
				"cmpl %%edx,%%edi\n\t"
				"jb L20\n\t"
				"andb $31,%%bl\n\t"
				: "=b" (k), "=D" (p), "=c" (pat)
				: "D" (p),"d" (pe),"b" (k),"c" (pat)
/* CDH end */
			);
			do_tick();
			BAILR
		} while (!done);
	}

	/* Do moving inversions test. Check for initial pattern and then
	 * write the complement for each memory location. Test from bottom
	 * up and then from the top down.  */
	for (i=0; i<iter; i++) {
		for (j=0; j<segs; j++) {
			start = v->map[j].start;
			end = v->map[j].end;
			pe = start;
			p = start;
			done = 0;
			k = off;
			pat = p1;
			do {
				/* Check for overflow */
				if ((uintptr_t)(pe + SPINSZ) > (uintptr_t)pe) {
					pe += SPINSZ;
				} else {
					pe = end;
				}
				if ((uintptr_t)pe >= (uintptr_t)end) {
					pe = end;
					done++;
				}
				if ((uintptr_t)p == (uintptr_t)pe) {
					break;
				}
/* Original C code replaced with hand tuned assembly code
 *				while (p < pe) {
 *					if ((bad=*p) != pat) {
 *						error((ulong*)p, pat, bad);
 *					}
 *					*p = ~pat;
 *					if (++k >= 32) {
 *						pat = lb;
 *						k = 0;
 *					} else {
 *						pat = pat << 1;
 *						pat |= sval;
 *					}
 *					p++;
 *				}
 */
				asm __volatile__ (
					"pushl %%ebp\n\t"
					"jmp L30\n\t"

					".p2align 4,,7\n\t"
					"L30:\n\t"
					"movl (%%edi),%%ebp\n\t"
					"cmpl %%ecx,%%ebp\n\t"
					"jne L34\n\t"

/* CDH start */
					"L35:\n\t"
					"notl %%ecx\n\t"
					"movl %%ecx,(%%edi)\n\t"
					"notl %%ecx\n\t"
					"addl $4,%%edi\n\t"
					"incb %%bl\n\t"
					"roll $1,%%ecx\n\t"
					"cmpl %%edx,%%edi\n\t"
					"jb L30\n\t"
					"jmp L33\n\t"
/* CDH end */

					"L34:\n\t" \
					"pushl %%esi\n\t"
					"pushl %%eax\n\t"
					"pushl %%ebx\n\t"
					"pushl %%edx\n\t"
					"pushl %%ebp\n\t"
					"pushl %%ecx\n\t"
					"pushl %%edi\n\t"
					"call error\n\t"
					"popl %%edi\n\t"
					"popl %%ecx\n\t"
					"popl %%ebp\n\t"
					"popl %%edx\n\t"
					"popl %%ebx\n\t"
					"popl %%eax\n\t"
					"popl %%esi\n\t"
					"jmp L35\n"

/* CDH start */
					"L33:\n\t"
					"andb $31,%%bl\n\t"
					"popl %%ebp\n\t"
					: "=b" (k), "=D" (p), "=c" (pat)
					: "D" (p),"d" (pe),"b" (k),"c" (pat)
/* CDH end */
				);
				do_tick();
				BAILR
			} while (!done);
		}

		/* Since we already adjusted k and the pattern this
		 * code backs both up one step
		 */
/* CDH start */
/* Original C code replaced with hand tuned assembly code
 *		pat = lb;
 *		if ( 0 != (k = (k-1) & 31) ) {
 *			pat = (pat << k);
 *			if ( sval )
 *			pat |= ((sval << k) - 1);
 *		}
 *		k++;
 */
			asm __volatile__ (
			"decl %%ecx\n\t"
			"andl $31,%%ecx\n\t"
			"roll %%cl,%%ebx\n\t"
			"incb %%cl\n\t"
			: "=c" (k), "=b" (pat)
			: "c" (k), "b" (lb)
			);
/* CDH end */

		for (j=segs-1; j>=0; j--) {
			start = v->map[j].start;
			end = v->map[j].end;
			p = end -1;
			pe = end -1;
			done = 0;
			do {
				/* Check for underflow */
				if ((uintptr_t)(pe - SPINSZ) < (uintptr_t)pe) {
					pe -= SPINSZ;
				} else {
					pe = start;
				}
				if ((uintptr_t)pe <= (uintptr_t)start) {
					pe = start;
					done++;
				}
				if ((uintptr_t)p == (uintptr_t)pe) {
					break;
				}
/* Original C code replaced with hand tuned assembly code
 *				do {
 *					if ((bad=*p) != ~pat) {
 *						error((ulong*)p, ~pat, bad);
 *					}
 *					*p = pat;
 *					if (--k <= 0) {
 *						pat = hb;
 *						k = 32;
 *					} else {
 *						pat = pat >> 1;
 *						pat |= p3;
 *					}
 *				} while (p-- > pe);
 */
				asm __volatile__ (
					"pushl %%ebp\n\t"
					"addl $4,%%edi\n\t"
					"jmp L40\n\t"

					".p2align 4,,7\n\t"
					"L40:\n\t"
					"subl $4,%%edi\n\t"
					"movl (%%edi),%%ebp\n\t"
					"notl %%ecx\n\t"
					"cmpl %%ecx,%%ebp\n\t"
					"jne L44\n\t"

/* CDH start */
					"L45:\n\t"
					"notl %%ecx\n\t"
					"movl %%ecx,(%%edi)\n\t"
					"decb %%bl\n\t"
					"rorl $1,%%ecx\n\t"
					"cmpl %%edx,%%edi\n\t"
					"ja L40\n\t"
					"jmp L43\n\t"
/* CDH end */

					"L44:\n\t" \
					"pushl %%esi\n\t"
					"pushl %%eax\n\t"
					"pushl %%ebx\n\t"
					"pushl %%edx\n\t"
					"pushl %%ebp\n\t"
					"pushl %%ecx\n\t"
					"pushl %%edi\n\t"
					"call error\n\t"
					"popl %%edi\n\t"
					"popl %%ecx\n\t"
					"popl %%ebp\n\t"
					"popl %%edx\n\t"
					"popl %%ebx\n\t"
					"popl %%eax\n\t"
					"popl %%esi\n\t"
					"jmp L45\n"

/* CDH start */
					"L43:\n\t"
					"andb $31,%%bl\n\t"
					"subl $4,%%edi\n\t"
					"popl %%ebp\n\t"
					: "=b" (k), "=D" (p), "=c" (pat)
					: "D" (p),"d" (pe),"b" (k),"c" (pat)
/* CDH end */
				);
				do_tick();
				BAILR
			} while (!done);
		}
	}
}

/*
 * Test all of memory using modulo X access pattern.
 */
void modtst(int offset, int iter, ulong p1, ulong p2)
{
	int j, k, l, done;
	volatile ulong *pe;
	volatile ulong *start, *end;

	/* Display the current pattern */
	hprint(LINE_PAT, COL_PAT-2, p1);
	cprint(LINE_PAT, COL_PAT+6, "-");
	dprint(LINE_PAT, COL_PAT+7, offset, 2, 1);

	/* Write every nth location with pattern */
	for (j=0; j<segs; j++) {
		start = v->map[j].start;
		end = v->map[j].end;
		pe = (ulong *)start;
		p = start+offset;
		done = 0;
		do {
			/* Check for overflow */
			if ((uintptr_t)(pe + SPINSZ) > (uintptr_t)pe) {
				pe += SPINSZ;
			} else {
				pe = end;
			}
			if ((uintptr_t)pe >= (uintptr_t)end) {
				pe = end;
				done++;
			}
			if ((uintptr_t)p == (uintptr_t)pe) {
				break;
			}
/* Original C code replaced with hand tuned assembly code
 *			for (; p < pe; p += MOD_SZ) {
 *				*p = p1;
 *			}
 */
			asm __volatile__ (
				"jmp L60\n\t" \
				".p2align 4,,7\n\t" \

				"L60:\n\t" \
				"movl %%eax,(%%edi)\n\t" \
				"addl $80,%%edi\n\t" \
				"cmpl %%edx,%%edi\n\t" \
				"jb L60\n\t" \
				: "=D" (p)
				: "D" (p), "d" (pe), "a" (p1)
			);
			do_tick();
			BAILR
		} while (!done);
	}

	/* Write the rest of memory "iter" times with the pattern complement */
	for (l=0; l<iter; l++) {
		for (j=0; j<segs; j++) {
			start = v->map[j].start;
			end = v->map[j].end;
			pe = (ulong *)start;
			p = start;
			done = 0;
			k = 0;
			do {
				/* Check for overflow */
				if ((uintptr_t)(pe + SPINSZ) > (uintptr_t)pe) {
					pe += SPINSZ;
				} else {
					pe = end;
				}
				if ((uintptr_t)pe >= (uintptr_t)end) {
					pe = end;
					done++;
				}
				if ((uintptr_t)p == (uintptr_t)pe) {
					break;
				}
/* Original C code replaced with hand tuned assembly code
 *				for (; p < pe; p++) {
 *					if (k != offset) {
 *						*p = p2;
 *					}
 *					if (++k > MOD_SZ-1) {
 *						k = 0;
 *					}
 *				}
 */
				asm __volatile__ (
					"jmp L50\n\t" \
					".p2align 4,,7\n\t" \

					"L50:\n\t" \
					"cmpl %%ebx,%%ecx\n\t" \
					"je L52\n\t" \
					  "movl %%eax,(%%edi)\n\t" \
					"L52:\n\t" \
					"incl %%ebx\n\t" \
					"cmpl $19,%%ebx\n\t" \
					"jle L53\n\t" \
					  "xorl %%ebx,%%ebx\n\t" \
					"L53:\n\t" \
					"addl $4,%%edi\n\t" \
					"cmpl %%edx,%%edi\n\t" \
					"jb L50\n\t" \
					: "=D" (p), "=b" (k)
					: "D" (p), "d" (pe), "a" (p2),
						"b" (k), "c" (offset)
				);
				do_tick();
				BAILR
			} while (!done);
		}
	}

	/* Now check every nth location */
	for (j=0; j<segs; j++) {
		start = v->map[j].start;
		end = v->map[j].end;
		pe = (ulong *)start;
		p = start+offset;
		done = 0;
		do {
			/* Check for overflow */
			if ((uintptr_t)(pe + SPINSZ) > (uintptr_t)pe) {
				pe += SPINSZ;
			} else {
				pe = end;
			}
			if ((uintptr_t)pe >= (uintptr_t)end) {
				pe = end;
				done++;
			}
			if ((uintptr_t)p == (uintptr_t)pe) {
				break;
			}
/* Original C code replaced with hand tuned assembly code
 *			for (; p < pe; p += MOD_SZ) {
 *				if ((bad=*p) != p1) {
 *					error((ulong*)p, p1, bad);
 *				}
 *			}
 */
			asm __volatile__ (
				"jmp L70\n\t" \
				".p2align 4,,7\n\t" \

				"L70:\n\t" \
				"movl (%%edi),%%ecx\n\t" \
				"cmpl %%eax,%%ecx\n\t" \
				"jne L71\n\t" \
				"L72:\n\t" \
				"addl $80,%%edi\n\t" \
				"cmpl %%edx,%%edi\n\t" \
				"jb L70\n\t" \
				"jmp L73\n\t" \

				"L71:\n\t" \
				"pushl %%edx\n\t"
				"pushl %%ecx\n\t"
				"pushl %%eax\n\t"
				"pushl %%edi\n\t"
				"call error\n\t"
				"popl %%edi\n\t"
				"popl %%eax\n\t"
				"popl %%ecx\n\t"
				"popl %%edx\n\t"
				"jmp L72\n"

				"L73:\n\t" \
				: "=D" (p)
				: "D" (p), "d" (pe), "a" (p1)
				: "ecx"
			);
			do_tick();
			BAILR
		} while (!done);
	}
	cprint(LINE_PAT, COL_PAT, "          ");
}

/*
 * Test memory using block moves
 * Adapted from Robert Redelmeier's burnBX test
 */
void block_move(int iter)
{
	int i, j, done;
	ulong len;
	volatile ulong p, pe, pp;
	volatile ulong start, end;

	cprint(LINE_PAT, COL_PAT-2, "          ");

	/* Initialize memory with the initial pattern.  */
	for (j=0; j<segs; j++) {
		start = (ulong)v->map[j].start;
#ifdef USB_WAR
		/* We can't do the block move test on low memory beacuase
		 * BIOS USB support clobbers location 0x410 and 0x4e0
		 */
		if (start < 0x4f0) {
			start = 0x4f0;
		}
#endif
		end = (ulong)v->map[j].end;
		pe = start;
		p = start;
		done = 0;
		do {
			/* Check for overflow */
			if ((uintptr_t)(pe + SPINSZ*4) > (uintptr_t)pe) {
				pe += SPINSZ*4;
			} else {
				pe = end;
			}
			if ((uintptr_t)pe >= (uintptr_t)end) {
				pe = end;
				done++;
			}
			if ((uintptr_t)p == (uintptr_t)pe) {
				break;
			}
			len  = ((ulong)pe - (ulong)p) / 64;
			asm __volatile__ (
				"jmp L100\n\t"

				".p2align 4,,7\n\t"
				"L100:\n\t"
				"movl %%eax, %%edx\n\t"
				"notl %%edx\n\t"
				"movl %%eax,0(%%edi)\n\t"
				"movl %%eax,4(%%edi)\n\t"
				"movl %%eax,8(%%edi)\n\t"
				"movl %%eax,12(%%edi)\n\t"
				"movl %%edx,16(%%edi)\n\t"
				"movl %%edx,20(%%edi)\n\t"
				"movl %%eax,24(%%edi)\n\t"
				"movl %%eax,28(%%edi)\n\t"
				"movl %%eax,32(%%edi)\n\t"
				"movl %%eax,36(%%edi)\n\t"
				"movl %%edx,40(%%edi)\n\t"
				"movl %%edx,44(%%edi)\n\t"
				"movl %%eax,48(%%edi)\n\t"
				"movl %%eax,52(%%edi)\n\t"
				"movl %%edx,56(%%edi)\n\t"
				"movl %%edx,60(%%edi)\n\t"
				"rcll $1, %%eax\n\t"
				"leal 64(%%edi), %%edi\n\t"
				"decl %%ecx\n\t"
				"jnz  L100\n\t"
				: "=D" (p)
				: "D" (p), "c" (len), "a" (1)
				: "edx"
			);
			do_tick();
			BAILR
		} while (!done);
	}

	/* Now move the data around
	 * First move the data up half of the segment size we are testing
	 * Then move the data to the original location + 32 bytes
	 */
	for (j=0; j<segs; j++) {
		start = (ulong)v->map[j].start;
#ifdef USB_WAR
		/* We can't do the block move test on low memory beacuase
		 * BIOS USB support clobbers location 0x410 and 0x4e0
		 */
		if (start < 0x4f0) {
			start = 0x4f0;
		}
#endif
		end = (ulong)v->map[j].end;
		pe = start;
		p = start;
		done = 0;
		do {
			/* Check for overflow */
			if ((uintptr_t)(pe + SPINSZ*4) > (uintptr_t)pe) {
				pe += SPINSZ*4;
			} else {
				pe = end;
			}
			if ((uintptr_t)pe >= (uintptr_t)end) {
				pe = end;
				done++;
			}
			if ((uintptr_t)p == (uintptr_t)pe) {
				break;
			}
			pp = p + ((pe - p) / 2);
			len  = ((ulong)pe - (ulong)p) / 8;
			for(i=0; i<iter; i++) {
				asm __volatile__ (
					"cld\n"
					"jmp L110\n\t"

					".p2align 4,,7\n\t"
					"L110:\n\t"
					"movl %1,%%edi\n\t"
					"movl %0,%%esi\n\t"
					"movl %2,%%ecx\n\t"
					"rep\n\t"
					"movsl\n\t"
					"movl %0,%%edi\n\t"
					"addl $32,%%edi\n\t"
					"movl %1,%%esi\n\t"
					"movl %2,%%ecx\n\t"
					"subl $8,%%ecx\n\t"
					"rep\n\t"
					"movsl\n\t"
					"movl %0,%%edi\n\t"
					"movl $8,%%ecx\n\t"
					"rep\n\t"
					"movsl\n\t"
					:: "g" (p), "g" (pp), "g" (len)
					: "edi", "esi", "ecx"
				);
				do_tick();
				BAILR
			}
			p = pe;
		} while (!done);
	}

	/* Now check the data
	 * The error checking is rather crude.  We just check that the
	 * adjacent words are the same.
	 */
	for (j=0; j<segs; j++) {
		start = (ulong)v->map[j].start;
#ifdef USB_WAR
		/* We can't do the block move test on low memory beacuase
		 * BIOS USB support clobbers location 0x4e0 and 0x410
		 */
		if (start < 0x4f0) {
			start = 0x4f0;
		}
#endif
		end = (ulong)v->map[j].end;
		pe = start;
		p = start;
		done = 0;
		do {
			/* Check for overflow */
			if ((uintptr_t)(pe + SPINSZ*4) > (uintptr_t)pe) {
				pe += SPINSZ*4;
			} else {
				pe = end;
			}
			if ((uintptr_t)pe >= (uintptr_t)end) {
				pe = end;
				done++;
			}
			if ((uintptr_t)p == (uintptr_t)pe) {
				break;
			}
			asm __volatile__ (
				"jmp L120\n\t"

				".p2align 4,,7\n\t"
				"L120:\n\t"
				"movl (%%edi),%%ecx\n\t"
				"cmpl 4(%%edi),%%ecx\n\t"
				"jnz L121\n\t"

				"L122:\n\t"
				"addl $8,%%edi\n\t"
				"cmpl %%edx,%%edi\n\t"
				"jb L120\n"
				"jmp L123\n\t"

				"L121:\n\t"
				"pushl %%edx\n\t"
				"pushl 4(%%edi)\n\t"
				"pushl %%ecx\n\t"
				"pushl %%edi\n\t"
				"call mv_error\n\t"
				"popl %%edi\n\t"
				"addl $8,%%esp\n\t"
				"popl %%edx\n\t"
				"jmp L122\n"
				"L123:\n\t"
				: "=D" (p)
				: "D" (p), "d" (pe)
				: "ecx"
			);
			do_tick();
			BAILR
		} while (!done);
	}
}

/*
 * Test memory for bit fade.
 */
#define STIME 5400
void bit_fade()
{
	int j;
	volatile ulong *pe;
	volatile ulong bad;
	volatile ulong *start,*end;

	test_ticks += (STIME * 2);
	v->pass_ticks += (STIME * 2);

	/* Do -1 and 0 patterns */
	p1 = 0;
	while (1) {

		/* Display the current pattern */
		hprint(LINE_PAT, COL_PAT, p1);

		/* Initialize memory with the initial pattern.  */
		for (j=0; j<segs; j++) {
			start = v->map[j].start;
			end = v->map[j].end;
			pe = start;
			p = start;
			for (p=start; p<end; p++) {
				*p = p1;
			}
			do_tick();
			BAILR
		}
		/* Snooze for 90 minutes */
		sleep (STIME);

		/* Make sure that nothing changed while sleeping */
		for (j=0; j<segs; j++) {
			start = v->map[j].start;
			end = v->map[j].end;
			pe = start;
			p = start;
			for (p=start; p<end; p++) {
				if ((bad=*p) != p1) {
					error((ulong*)p, p1, bad);
				}
			}
			do_tick();
			BAILR
		}
		if (p1 == 0) {
			p1=-1;
		} else {
			break;
		}
	}
}

/*
 * Display data error message. Don't display duplicate errors.
 */
void error(ulong *adr, ulong good, ulong bad)
{
	ulong xor;
	int patnchg;

	xor = good ^ bad;
#ifdef USB_WAR
	/* Skip any errrors that appear to be due to the BIOS using location
	 * 0x4e0 for USB keyboard support.  This often happens with Intel
         * 810, 815 and 820 chipsets.  It is possible that we will skip
	 * a real error but the odds are very low.
	 */
	if ((ulong)adr == 0x4e0 || (ulong)adr == 0x410) {
		return;
	}
#endif

	/* Process the address in the pattern administration */
	patnchg=insertaddress ((ulong) adr);

	update_err_counts();
	if (v->printmode == PRINTMODE_ADDRESSES) {

		/* Don't display duplicate errors */
		if ((ulong)adr == (ulong)v->eadr && xor == v->exor) {
			print_err_counts();
			dprint(v->msg_line, 66, ++ecount, 5, 0);
			return;
		}
		print_err(adr, good, bad, xor);

	} else if (v->printmode == PRINTMODE_PATTERNS) {
		print_err_counts();

		if (patnchg) { 
			printpatn();
		}
	}
}

/*
 * Display data error message from the block move test.  The actual failing
 * address is unknown so don't use this failure information to create
 * BadRAM patterns.
 */
void mv_error(ulong *adr, ulong good, ulong bad)
{
	ulong xor;

	update_err_counts();
	if (v->printmode == PRINTMODE_NONE) {
		return;
	}
	xor = good ^ bad;
	print_err(adr, good, bad, xor);
}

/*
 * Display address error message.
 * Since this is strictly an address test, trying to create BadRAM
 * patterns does not make sense.  Just report the error.
 */
void ad_err1(ulong *adr1, ulong *adr2, ulong good, ulong bad)
{
	ulong xor;
	update_err_counts();
	if (v->printmode == PRINTMODE_NONE) {
		return;
	}
	xor = ((ulong)adr1) ^ ((ulong)adr2);
	print_err(adr1, good, bad, xor);
}

/*
 * Display address error message.
 * Since this type of address error can also report data errors go
 * ahead and generate BadRAM patterns.
 */
void ad_err2(ulong *adr, ulong bad)
{
	int patnchg;

	/* Process the address in the pattern administration */
	patnchg=insertaddress ((ulong) adr);

	update_err_counts();
	if (v->printmode == PRINTMODE_ADDRESSES) {
		print_err(adr, (ulong)adr, bad, ((ulong)adr) ^ bad);
	} else if (v->printmode == PRINTMODE_PATTERNS) {
		print_err_counts();
		if (patnchg) { 
			printpatn();
		}
	}
}
void print_hdr(void)
{
	if (v->ecount > 1) {
		return;
	}
	cprint(LINE_HEADER, 0,  "Tst  Pass   Failing Address          Good       Bad     Err-Bits  Count Chan");
	cprint(LINE_HEADER+1, 0,"---  ----  -----------------------  --------  --------  --------  ----- ----");
}

static void update_err_counts(void)
{
	if (v->pass && v->ecount == 0) {
		cprint(LINE_MSG, COL_MSG,
			"                                            ");
	}
	++(v->ecount);
	tseq[v->test].errors++;
		
}

static void print_err_counts(void)
{
	int i;

	if ((v->ecount > 1048756) && (v->ecount % 32768 != 0)) return;
	if ((v->ecount > 2048) && (v->ecount % 1024 != 0)) return;

	dprint(LINE_INFO, COL_ERR, v->ecount, 6, 0);
	dprint(LINE_INFO, COL_ECC_ERR, v->ecc_ecount, 6, 0);

	/* Paint the error messages on the screen red to provide a vivid */
	/* indicator that an error has occured */ 
	if (v->msg_line < 24) {
	        for (i=0; i<76; i++) {
	                set_ega_color (v->msg_line, i, 0x47);
		}
	}
}

static void common_err(ulong page, ulong offset)
{
	ulong mb;

	/* Check for keyboard input */
	print_hdr();
	check_input();
	scroll();
	print_err_counts();

	mb = page >> 8;
	dprint(v->msg_line, 0, v->test, 3, 0);
	dprint(v->msg_line, 4, v->pass, 5, 0);
	hprint(v->msg_line, 11, page);
	hprint2(v->msg_line, 19, offset, 3);
	cprint(v->msg_line, 22, " -      . MB");
	dprint(v->msg_line, 25, mb, 5, 0);
	dprint(v->msg_line, 31, ((page & 0xF)*10)/16, 1, 0);
}
/*
 * Print an individual error
 */
void print_err( ulong *adr, ulong good, ulong bad, ulong xor) 
{
	ulong page, offset;

	page = page_of(adr);
	offset = ((unsigned long)adr) & 0xFFF;
	common_err(page, offset);

	ecount = 1;
	hprint(v->msg_line, 36, good);
	hprint(v->msg_line, 46, bad);
	hprint(v->msg_line, 56, xor);
	dprint(v->msg_line, 66, ecount, 5, 0);
	v->eadr = adr;
	v->exor = xor;
}

/*
 * Print an ecc error
 */
void print_ecc_err(unsigned long page, unsigned long offset, 
	int corrected, unsigned short syndrome, int channel)
{
	if (!corrected) {
		update_err_counts();
	}
	++(v->ecc_ecount);
	if (v->printmode == PRINTMODE_NONE) {
		return;
	}
	common_err(page, offset);

	cprint(v->msg_line, 36, 
		corrected?"corrected           ": "uncorrected         ");
	hprint2(v->msg_line, 60, syndrome, 4);
	cprint(v->msg_line, 68, "ECC"); 
	dprint(v->msg_line, 74, channel, 2, 0);
}

#ifdef PARITY_MEM
/*
 * Print a parity error message
 */
void parity_err( unsigned long edi, unsigned long esi) 
{
	unsigned long addr;

	if (v->test == 5) {
		addr = esi;
	} else {
		addr = edi;
	}
	update_err_counts();
	if (v->printmode == PRINTMODE_NONE) {
		return;
	}
	common_err(page_of((void *)addr), addr & 0xFFF);
	cprint(v->msg_line, 36, "Parity error detected                ");
}
#endif


/*
 * Print the pattern array as a LILO boot option addressing BadRAM support.
 */
void printpatn (void)
{
       int idx=0;
       int x;

	/* Check for keyboard input */
	check_input();

       if (v->numpatn == 0)
               return;

       scroll();

       cprint (v->msg_line, 0, "badram=");
       x=7;

       for (idx = 0; idx < v->numpatn; idx++) {

               if (x > 80-22) {
                       scroll();
                       x=7;
               }
               cprint (v->msg_line, x, "0x");
               hprint (v->msg_line, x+2,  v->patn[idx].adr );
               cprint (v->msg_line, x+10, ",0x");
               hprint (v->msg_line, x+13, v->patn[idx].mask);
               if (idx+1 < v->numpatn)
                       cprint (v->msg_line, x+21, ",");
               x+=22;
       }
}
	
/*
 * Show progress by displaying elapsed time and update bar graphs
 */
void do_tick(void)
{
	int i, pct;
	ulong h, l, t;

	/* FIXME only print serial error messages from the tick handler */
	if (v->ecount) {
		print_err_counts();
	}
	
	nticks++;
	v->total_ticks++;

	pct = 100*nticks/test_ticks;
	dprint(1, COL_MID+4, pct, 3, 0);
	i = (BAR_SIZE * pct) / 100;
	while (i > v->tptr) {
		if (v->tptr >= BAR_SIZE) {
			break;
		}
		cprint(1, COL_MID+9+v->tptr, "#");
		v->tptr++;
	}
	
	pct = 100*v->total_ticks/v->pass_ticks;
	dprint(0, COL_MID+4, pct, 3, 0);
	i = (BAR_SIZE * pct) / 100;
	while (i > v->pptr) {
		if (v->pptr >= BAR_SIZE) {
			break;
		}
		cprint(0, COL_MID+9+v->pptr, "#");
		v->pptr++;
	}

	/* We can't do the elapsed time unless the rdtsc instruction
	 * is supported
	 */
	if (v->rdtsc) {
		asm __volatile__(
			"rdtsc":"=a" (l),"=d" (h));
		asm __volatile__ (
			"subl %2,%0\n\t"
			"sbbl %3,%1"
			:"=a" (l), "=d" (h)
			:"g" (v->startl), "g" (v->starth),
			"0" (l), "1" (h));
		t = h * ((unsigned)0xffffffff / v->clks_msec) / 1000;
		t += (l / v->clks_msec) / 1000;
		i = t % 60;
		dprint(LINE_TIME, COL_TIME+9, i%10, 1, 0);
		dprint(LINE_TIME, COL_TIME+8, i/10, 1, 0);
		t /= 60;
		i = t % 60;
		dprint(LINE_TIME, COL_TIME+6, i % 10, 1, 0);
		dprint(LINE_TIME, COL_TIME+5, i / 10, 1, 0);
		t /= 60;
		dprint(LINE_TIME, COL_TIME, t, 4, 0);
	}

	/* Check for keyboard input */
	check_input();

	/* Poll for ECC errors */
	poll_errors();
}

void sleep(int n)
{
	int i, ip=0;
	ulong sh, sl, l, h, t;

	/* save the starting time */
	asm __volatile__(
		"rdtsc":"=a" (sl),"=d" (sh));

	/* loop for n seconds */
	while (1) {
		asm __volatile__(
			"rdtsc":"=a" (l),"=d" (h));
		asm __volatile__ (
			"subl %2,%0\n\t"
			"sbbl %3,%1"
			:"=a" (l), "=d" (h)
			:"g" (sl), "g" (sh),
			"0" (l), "1" (h));
		t = h * ((unsigned)0xffffffff / v->clks_msec) / 1000;
		t += (l / v->clks_msec) / 1000;

		/* Is the time up? */
		if (t >= n) {
			break;
		}

		/* Display the elapsed time on the screen */
		i = t % 60;
		dprint(LINE_TIME, COL_TIME+9, i%10, 1, 0);
		dprint(LINE_TIME, COL_TIME+8, i/10, 1, 0);
		if (i != ip) {
			do_tick();
			BAILR
			ip = i;
		}
		t /= 60;
		i = t % 60;
		dprint(LINE_TIME, COL_TIME+6, i % 10, 1, 0);
		dprint(LINE_TIME, COL_TIME+5, i / 10, 1, 0);
		t /= 60;
		dprint(LINE_TIME, COL_TIME, t, 4, 0);
	}
}
