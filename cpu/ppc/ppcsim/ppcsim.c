// See license at end of file
/*
 * PowerPC instruction set simulator for Forth
 */

#include <stdio.h>

#define BI_ENDIAN

extern long s_bye();
extern long c_key();

typedef	unsigned char	u_char;
typedef	unsigned short	u_short;
typedef	unsigned int	u_int;
typedef	unsigned long	u_long;

#define MAXMEM 0x80000

union {
    u_long all;
    struct {
        u_long SO :1;
        u_long OV :1;
        u_long CA :1;
        u_long res:13;
    } bits;
} XER;

union {
    u_long all;
    struct {
        u_long LTGTEQ :3;
        u_long SO :1;
        u_long res:12;
    } bits;
} CR;


#define ILLEGAL goto illegal

#ifdef TRACE
#define INSTR(a)	trace(a, instruction, pc)
#else
#define INSTR(a)
#endif

#define CMP(a,b)	((a < b) ? 4 : ((a > b) ? 2 : 1 ))

#define DO_UPDATE_SO  CR.bits.SO = XER.bits.SO
#define DO_UPDATE_SO_CRFD(crfd)  {  \
        CR.all &= ~(1 << ((7-crfd)<<2)); \
	CR.all |= (XER.bits.SO << ((7-crfd)<<2));\
    }

#define DO_UPDATE_OV(dest,src1,src2) \
	   if (OE) { \
	       XER.bits.SO |= \
	           (XER.bits.OV = \
		       ((((long)(dest))^((long)(src1))) <  0) && \
		       ((((long)(src1))^((long)(src2))) >= 0));  \
	   }

#ifdef OVERFLOWS
#define UPDATE_SO  DO_UPDATE_SO
#define UPDATE_SO_CRFD(crfd)  DO_UPDATE_SO_CRFD(crfd)
#define UPDATE_OV(a,b,c)  DO_UPDATE_OV(a,b,c)
#else
#define UPDATE_SO
#define UPDATE_SO_CRFD(a)
#define UPDATE_OV(a,b,c)
#endif

#define UPDATE_CA(res,op)  XER.bits.CA = ((u_long)res < (u_long)op)

#define DO_UPDATE_CRFD(dest,src,crfd) \
	   { \
               CR.all &= ~(0xe << ((7-crfd)<<2)); \
	       CR.all |= (CMP(dest, src) << (((7-crfd)<<2)+1)); \
	       UPDATE_SO_CRFD(crfd); \
	   }

#ifdef notdef
#define DO_UPDATE_CR(dest,src) \
	   { \
	       CR.bits.LTGTEQ = CMP(dest, src); \
	       UPDATE_SO; \
	   }
#else
#define DO_UPDATE_CR(dest,src) DO_UPDATE_CRFD(dest,src,0)
#endif

#define UPDATE_CR(dest) \
	   if (RC) { \
		DO_UPDATE_CR((long)dest, 0); \
	   }

/* Add/subtract with carry */
#define ADDC(b,a) \
	   temp = (b)+(a); \
	   UPDATE_OV(temp,(b),(a)); \
	   UPDATE_CA((temp),(a)); \
	   UPDATE_CR(temp); \
	   RD = temp;

#define SUBC(b,a) \
	   temp = (b)-(a); \
	   UPDATE_OV(temp,(b),(a)); \
	   XER.bits.CA = (b) >= (a); \
	   UPDATE_CR(temp); \
	   RD = temp;

/* Add/subtract without carry */
#define ADD(b,a) \
	   temp = (b)+(a);  \
	   UPDATE_OV(temp,(b), (a)); \
	   UPDATE_CR(temp); \
	   RD = temp; \
	   break;

/* logical operations - and, or, shifts, etc */
#define LOGIC(expr) \
	   RA = expr; \
	   UPDATE_CR(RA); \
	   break;

/* Condition/counter evaluation for bcXXX */
#define CONDITION \
	   /* \
	    * If (BO&0x10), don't test condition. \
	    * Otherwise the CR[BI] and the 0x8 bit of BO must be the same. \
	    */ \
	   cond_ok =  ((BO & 0x10) \
	           || ((long)((CR.all << BI) ^ (BO << 28)) >= 0)); \
	   if ((BO & 4) == 0) {  /* Update and test counter */ \
		CTR -= 1; \
		cond_ok &= ((CTR != 0) ^ ((BO >> 1) & 1)); \
	   } \
	   if (LK) \
		LR = CIA+4;


#define UFIELD(lbit,nbits)  ((instruction << lbit) >> (32 - nbits))
#define SFIELD(lbit,nbits)  ((long)(instruction << lbit) >> (32 - nbits))

#define OPCD (instruction >> 26)
#define OP2  UFIELD(21,10)

/* These bits are never used as indices; only as flags */
#define LK   (instruction & 1)
#define RC   (instruction & 1)
#define AA   (instruction & 2)
#define SHD  (instruction & 2)

#define LI   SFIELD( 6,24)

#define RD   reg[UFIELD( 6, 5)]
#define RS   reg[UFIELD( 6, 5)]
#define FRD  reg[UFIELD( 6, 5)]
#define FRS  reg[UFIELD( 6, 5)]
#define BO       UFIELD( 6, 5)
#define CRBD     UFIELD( 6, 5)

#define RA   reg[UFIELD(11, 5)]
#define FRA  reg[UFIELD(11, 5)]
#define BI       UFIELD(11, 5)
#define CRBA     UFIELD(11, 5)
#define TO       UFIELD(11, 5)
#define RA0	 (UFIELD(11, 5) ? RA : 0)

#define RB   reg[UFIELD(16, 5)]
#define FRB  reg[UFIELD(16, 5)]
#define CRBB     UFIELD(16, 5)
#define NB       UFIELD(16, 5)
#define SH       UFIELD(16, 5)

#define FRC  reg[UFIELD(21, 5)]
#define MB       UFIELD(21, 5)

#define ME       UFIELD(26, 5)

#define BD       SFIELD(16,14)
#define DS       SFIELD(16,14)

#define D        SFIELD(16,16)
#define SIMM     SFIELD(16,16)
#define UIMM     UFIELD(16,16)

#define CRFD     UFIELD( 6, 3)
#define FM       UFIELD( 7, 8)
#define L        UFIELD(10, 1)
#define CRFS     UFIELD(11, 3)
#define SPR      (UFIELD(11,5) | (UFIELD(16,5) << 5))
#define TBR      UFIELD(11,10)
#define CRM      UFIELD(12, 8)
#define SR   seg[UFIELD(12, 4)]
#define IMM      UFIELD(16, 4)
#define XO       UFIELD(21,10)
#define OE       UFIELD(21, 1)

#define MASK  ((MB <= ME) ?   (u_long)(-1L << (31-ME+MB)) >>  MB \
	                  :   (u_long)(-1L << (31-ME)) | ((u_long)-1L >> MB))

#define ROTATE(val, cnt) (((val) >> (32-(cnt))) | ((val) << (cnt)))

u_long TBAR;

#ifdef MMU

/*
 * This is not an accurate simulation of the PowerPC MMU behavior
 * a) BATs aren't implemented.
 * b) the simulated TLB is much much larger than a real one
 * c) segment register values are limited to the range 0..f
 */
u_long mmutab[0x100000];
void
init_tlb()
{
	int i;
	for (i = 0; i < 0x100000; i++)
		mmutab[i] = 0xffffffff;
}
u_long
tlb_miss(vaddr)
	register u_long vaddr;
{
	/* References: 603 manual, sections 7.6.1.4 and 7.6.3.1 */
	register u_long temp, vsid, mask;
	vsid = seg[vaddr >> 28];
	temp = ((vaddr >> 12) & 0xffff) | vsid;
	mask = ((((SDR1 & 0x1ff) << 10) | 0x3ff) << 6;
	DMISS = IMISS = vaddr;
	HASH1 = (SDR1 & 0xffff0000) | ((temp << 6) & mask);
	HASH2 = HASH1 ^ mask;
	DCMP = ICMP = 0x80000000 | (vsid << 7) | ((vaddr >> 22) & 0x3f);
}
tlbie(vaddr)
	register u_long vaddr;
{
	mmutab[vaddr >> 12] = 0xffffffff;
}
u_long
MAP(vaddr)
	register u_long vaddr;
{
	register u_long phys;
	register u_long pageno;
	pageno = (seg[vaddr >> 28] << 16) | ((vaddr >> 12) & 0xffff);

	if ((phys = mmutab[pageno]) == 0xffffffff)
		mmutab[pageno] = phys = tlb_miss(vaddr);
	return (phys | (vaddr & 0xfff));
}
#else
#ifdef SIMNT
/*
 * Most PPC kernel stuff wants to run in what used to be kseg0 (long
 * long ago in a galaxy far far away). This little deal maps virtual
 * to physical.
 */
u_long
MAP(vaddr)
	u_long vaddr;
{
	if (vaddr > 0x80000000 && vaddr < 0xf0000000)
		vaddr &= ~0x80000000;
	return(vaddr < 0x10000 ? vaddr + 0x50000 : vaddr);
}
#else
#ifdef TRACE
#ifndef SIMROM
/* This can't be a macro because of side effects of operand evaluation */
u_long
MAP(vaddr)
	register u_long vaddr;
{
	return ((vaddr < 0x1000) ? (vaddr + TBAR) : vaddr);
}
#else
#define MAP(vaddr)   (vaddr)
#endif
#else
#define MAP(vaddr)   (vaddr)
#endif
#endif
#endif

#ifdef NOTDEF
#define CIA  ((u_char *)MAP(pc) - mem)
#else
#define CIA  ((u_long)MAP(pc))
#endif
#define UNIMP(str)  { opname = str;  goto unimplemented; }
#define POWER(str)  { opname = str;  goto power; }

#ifdef BI_ENDIAN
#define MEM(type, size, adr)   *(type *)(&mem[MAP((adr) ^ size)])
#else
#define MEM(type, size, adr)   *(type *)(&mem[MAP(adr)])
#endif

u_long greg[32];
u_long seg[16];

#ifdef TRACE
u_long instruction;
u_long pc;
u_long CTR;
u_long LR;
#endif

u_long IABR;
u_long HID0;
u_long DEC, SRR0, SRR1, SPRG0, SPRG1, SPRG2, SPRG3, MSR;

u_char *xmem;

void
simulate(mem, start, arg0, arg1, arg2, arg3, arg4, arg5)
        register u_char *mem;
	u_long start;
	u_long arg0, arg1, arg2, arg3, arg4, arg5;
{
	register u_long *reg = &greg[0];
#ifndef TRACE
	register u_long instruction;
	register u_long pc;
	register u_long CTR;
	register u_long LR;
#endif
#ifdef BI_ENDIAN
	register u_long BYTE = 0;	/* 7 for little-endian */
	register u_long WORD = 0;	/* 6 for little-endian */
	register u_long LONG = 0;	/* 4 for little-endian */
#endif


	register int cond_ok;
	register u_long temp;
	u_long	scratch;
	char *msg;
	char *opname;

	xmem = mem;

	reg[3] = arg0;

	/*
	 * Pass 0 as the system call vector to let the kernel know it's
	 * running on the simulator.
	 */
	reg[4] = 0;	/* Was	reg[4] = arg1; */ 
	reg[5] = arg2;
	reg[6] = arg3;
	reg[7] = arg4;
	reg[8] = arg5;

#ifdef TRACE
	catch_signals();
#endif

	for (pc = start; ; pc += 4) {

#ifdef TRACE
 		if (DEC-- == 0 && (MSR & 0x8000) && TBAR) {
			SRR0 = CIA;
			SRR1 = MSR;
			pc = TBAR + 0x900 - 4;
			continue;
		}
#endif

		instruction = MEM(u_long , LONG, pc);

switch(OPCD) {

case    0: ILLEGAL;
case    1: ILLEGAL;
case    2: ILLEGAL;
case    3: /* UNIMP("twi"); */
/* Hack to speed-up Forth dictionary searches */
	RA = (u_long) xfindnext((u_char *)reg[3], (long)reg[4], (long)reg[5],
			       (u_long)reg[6], (u_long *)reg[7]);
	break;
case    4: ILLEGAL;
case    5: ILLEGAL;
case    6: ILLEGAL;
case    7: INSTR("mulli");       RD = RA * SIMM;         break;

case    8: INSTR("subfic");  
	   RD = SIMM - RA;
	   UPDATE_CA(RD,SIMM);
           break;

case    9: POWER("dozi");

case   10: INSTR("cmpli");  
/*DEBUG*/  if (L)    UNIMP("cmpli - 64-bit");
           if (CRFD)
               DO_UPDATE_CRFD(RA, UIMM, CRFD)
           else
	       DO_UPDATE_CR(RA, UIMM)
           break;

case   11: INSTR("cmpi");  
/*DEBUG*/  if (L)    UNIMP("cmpi - 64-bit");
           if (CRFD)
               DO_UPDATE_CRFD((long)RA, SIMM, CRFD)
           else
	       DO_UPDATE_CR((long)RA, SIMM)
           break;

case   12: INSTR("addic");  
	   RD = RA + SIMM;
	   UPDATE_CA(RD,SIMM);
           break;

case   13: INSTR("addic.");  
	   RD = RA + SIMM;
	   UPDATE_CA(RD,SIMM);
	   DO_UPDATE_CR((long)RD, 0);
           break;

case   14: INSTR("addi");     RD = RA0 + SIMM;           break;
case   15: INSTR("addis");    RD = RA0 + (SIMM << 16);   break;

case   16: INSTR("bcX");  
	   CONDITION
	   if ( cond_ok )
		pc = (BD << 2) + (AA ? 0 : CIA) - 4;
           break;

case   17: UNIMP("sc");

case   18: INSTR("bX");  
	   if (LK)
		LR = CIA+4;
	   pc = (LI << 2) + (AA ? 0 : CIA) - 4;
           break;

case   19:
	   switch(OP2) {
		case  16: INSTR("bclr");
			  CONDITION
/* XXX Possible problem with updating the link register before using it */
			  if ( cond_ok )
				pc = LR - 4;
			  break;
		case  50: INSTR("rfi");
			  MSR = SRR1;
			  pc = SRR0 - 4;
			  break;
		case 150: INSTR("isync");			  break;
		case 528: INSTR("bcctr");
#ifdef SIMNEXT
#define W    reg[25]
#define BASE reg[26]
#define UP   reg[27]
#define IP   reg[29]
#define RP   reg[30]
#define DOCOLON 0x10
#define UNNEST 0x848
		  if (instruction == 0x4e800420 && CTR == UP
/*
 * If the first instruction of next is a branch, the Forth source
 * debugger is active, in which case we don't want to do the fast
 * next simulation.
 */
		      && (MEM(u_long, LONG, CTR) >> 26) != 18) {

		      next:

		      /* Recognize unnest from the unrelocated token value */
                      IP += sizeof(u_long);
		      while ((temp = *(u_long *)IP) == UNNEST) {
                          IP += sizeof(u_long);
			  IP = *(u_long *)RP;
                          RP += sizeof(u_long);
                      }

		      /* Recognize docolon from the unrelocated code field */
		      if ((temp = *(u_long *)(W = temp + BASE)) == DOCOLON) {
		          RP -= sizeof(u_long);
		          *(u_long *)RP = IP;
			  IP = W;
			  goto next;
		      }

		      /* -4 is an artifact of the simulator implementation */
		      pc = temp + BASE - 4;
		      break;
		  }
#endif
			  CONDITION
			  if ( cond_ok )
				pc = CTR - 4;
			  break;
		default:  UNIMP("CR logical ops");
	   }
           break;
case   20: INSTR("rlwimi"); RA = (RA & ~MASK) | (ROTATE(RS,SH) & MASK);
			    UPDATE_CR(RA); break;
case   21: INSTR("rlwinm"); RA = ROTATE(RS,SH) & MASK; UPDATE_CR(RA); break;
case   22: POWER("rlmi");
case   23: INSTR("rlwnm");  RA = ROTATE(RS,RB) & MASK; UPDATE_CR(RA); break;
case   24: INSTR("ori");    RA = RS |  UIMM;           break;
case   25: INSTR("oris");   RA = RS | (UIMM << 16);    break;
case   26: INSTR("xori");   RA = RS ^  UIMM;           break;
case   27: INSTR("xoris");  RA = RS ^ (UIMM << 16);    break;
case   28: INSTR("andi.");  RA = RS &  UIMM;
			    DO_UPDATE_CR((long)RA, 0); break;
case   29: INSTR("andis."); RA = RS & (UIMM << 16);
			    DO_UPDATE_CR((long)RA, 0); break;
case   30: ILLEGAL;
/* case 31 is at the end */
case   32: INSTR("lwz");   RD = MEM(u_long , LONG,       RA0+ D );      break;
case   33: INSTR("lwzu");  RD = MEM(u_long , LONG, RA = (RA + D));      break;
case   34: INSTR("lbz");   RD = MEM(u_char , BYTE,       RA0+ D );      break;
case   35: INSTR("lbzu");  RD = MEM(u_char , BYTE, RA = (RA + D));      break;
case   36: INSTR("stw");        MEM(u_long , LONG,       RA0+ D ) = RS; break;
case   37: INSTR("stwu");       MEM(u_long , LONG, RA = (RA + D)) = RS; break;
case   38: INSTR("stb");        MEM(u_char , BYTE,       RA0+ D ) = RS; break;
case   39: INSTR("stbu");       MEM(u_char , BYTE, RA = (RA + D)) = RS; break;
case   40: INSTR("lhz");   RD = MEM(u_short, WORD,       RA0+ D );      break;
case   41: INSTR("lhzu");  RD = MEM(u_short, WORD, RA = (RA + D));      break;
case   42: INSTR("lha");   RD = MEM(  short, WORD,       RA0+ D );      break;
case   43: INSTR("lhau");  RD = MEM(  short, WORD, RA = (RA + D));      break;
case   44: INSTR("sth");        MEM(u_short, WORD,       RA0+ D ) = RS; break;
case   45: INSTR("sthu");       MEM(u_short, WORD, RA = (RA + D)) = RS; break;
case   46: INSTR("lmw");  {
				u_long *src, *dst;
#ifdef BI_ENDIAN
				if (LONG)
					goto illegal;
					/* Should be an alignment exception */
#endif
				dst = &(RD);
				src = (u_long  *)(&mem[MAP(RA0+D)]);
				while (dst < &reg[32])
				    *dst++ = *src++;
			  }
			break;
case   47: INSTR("stmw"); {
				u_long *src, *dst;
#ifdef BI_ENDIAN
				if (LONG)
					goto illegal;
					/* Should be an alignment exception */
#endif
				dst = (u_long  *)(&mem[MAP(RA0+D)]);
				src = &(RS);
				while (src < &reg[32])
					*dst++ = *src++;
			  }
			break;
case   48: UNIMP("lfs");
case   49: UNIMP("lfsu");
case   50: UNIMP("lfd");
case   51: UNIMP("lfdu");
case   52: UNIMP("stfs");
case   53: UNIMP("stfsu");
case   54: UNIMP("stfd");
case   55: UNIMP("stfdu");
case   56: ILLEGAL;
case   57: ILLEGAL;
case   58: ILLEGAL;
case   59: UNIMP("Single Floating Point");
case   60: ILLEGAL;
case   61: ILLEGAL;
case   62: ILLEGAL;
case   63: UNIMP("Double Floating Point");
case   31:

switch(OP2) {
case    0: INSTR("cmp");  
/*DEBUG*/  if (L)    UNIMP("cmp - 64-bit");
           if (CRFD)
               DO_UPDATE_CRFD((long)RA, (long)RB, CRFD)
           else
	       DO_UPDATE_CR((long)RA, (long)RB)
	   
           break;
case    1: ILLEGAL;
case    2: ILLEGAL;
case    3: ILLEGAL;
case    4: 
#ifdef notdef
	   UNIMP("tw");
#else
	   /* tw */
	   /* Handle Forth wrapper calls - the call# is in RA */
	   reg[3] = (*(long (*) ())(*(long *)(arg1 + RA)))
		    (reg[3],reg[4],reg[5],reg[6],reg[7], reg[8]);
	   break;
#endif
case    5: ILLEGAL;
case    6: ILLEGAL;
case    7: ILLEGAL;
case    8: INSTR("subfc");  SUBC(RB,RA); break;
case    9: ILLEGAL;
case   10: INSTR("addc");   ADDC(RB,RA); break;
case   11: INSTR("mulhwu");
	   umtimes((u_long *)&RD, (u_long *)&scratch, RA, RB);  UPDATE_CR(RD);  break;
case   12: ILLEGAL;
case   13: ILLEGAL;
case   14: ILLEGAL;
case   15: ILLEGAL;
case   16: ILLEGAL;
case   17: ILLEGAL;
case   18: ILLEGAL;
case   19: INSTR("mfcr");  RD = CR.all;  break;
case   20: UNIMP("lwarx");
case   21: ILLEGAL;
case   22: ILLEGAL;
case   23: INSTR("lwzx");  RD = MEM(u_long , LONG, RA0 + RB);  break;
case   24: INSTR("slw");  LOGIC( (RB & 0x20 ? 0 : RS << (RB & 0x1f)) ); break;
case   25: ILLEGAL;
case   26: INSTR("cntlzw");
	   temp = RS;
	   for(scratch = 0;
	       scratch < 32 && ((temp & 0x80000000) == 0);
	       scratch++) {
		   temp <<= 1;
	   }
	   UPDATE_CR(scratch);
	   RA = scratch;
	   break;
case   27: ILLEGAL;
case   28: INSTR("and");  LOGIC( RS & RB );
case   29: POWER("maskg");
case   30: ILLEGAL;
case   31: ILLEGAL;
case   32: INSTR("cmpl");  
/*DEBUG*/  if (L)    UNIMP("cmpl - 64-bit");
           if (CRFD)
               DO_UPDATE_CRFD(RA, RB, CRFD)
           else
	       DO_UPDATE_CR(RA, RB)
           break;
case   33: ILLEGAL;
case   34: ILLEGAL;
case   35: ILLEGAL;
case   36: ILLEGAL;
case   37: ILLEGAL;
case   38: ILLEGAL;
case   39: ILLEGAL;
case   40: INSTR("subf");  ADD(RB,-RA);
case   41: ILLEGAL;
case   42: ILLEGAL;
case   43: ILLEGAL;
case   44: ILLEGAL;
case   45: ILLEGAL;
case   46: ILLEGAL;
case   47: ILLEGAL;
case   48: ILLEGAL;
case   49: ILLEGAL;
case   50: ILLEGAL;
case   51: ILLEGAL;
case   52: ILLEGAL;
case   53: ILLEGAL;
case   54: INSTR("dcbst");  break;
case   55: INSTR("lwzux");  RD = MEM(u_long , LONG, RA = (RA + RB));   break;
case   56: ILLEGAL;
case   57: ILLEGAL;
case   58: ILLEGAL;
case   59: ILLEGAL;
case   60: INSTR("andc");	LOGIC( RS & ~RB );
case   61: ILLEGAL;
case   62: ILLEGAL;
case   63: ILLEGAL;
case   64: ILLEGAL;
case   65: ILLEGAL;
case   66: ILLEGAL;
case   67: ILLEGAL;
case   68: ILLEGAL;
case   69: ILLEGAL;
case   70: ILLEGAL;
case   71: ILLEGAL;
case   72: ILLEGAL;
case   73: ILLEGAL;
case   74: ILLEGAL;
case   75: INSTR("mulhw");
       {
          int negative = ((long)(RA ^ RB)) < 0;
	  long highres;
          long op1  = ((long)RA < 0) ? -(long)RA : RA;
          long op2  = ((long)RB < 0) ? -(long)RB : RB;
    	  umtimes((u_long *)&highres, (u_long *)&scratch, op1, op2);
          RD = negative ? (~highres) + (scratch==0) : highres;
          UPDATE_CR(RD);
          break;
       }

case   76: ILLEGAL;
case   77: ILLEGAL;
case   78: ILLEGAL;
case   79: ILLEGAL;
case   80: ILLEGAL;
case   81: ILLEGAL;
case   82: ILLEGAL;
case   83: INSTR("mfmsr"); RD = MSR;  break;
case   84: ILLEGAL;
case   85: ILLEGAL;
case   86: INSTR("dcbf");  break;
case   87: INSTR("lbzx");  RD = MEM(u_char , BYTE, RA0 + RB);     break;
case   88: ILLEGAL;
case   89: ILLEGAL;
case   90: ILLEGAL;
case   91: ILLEGAL;
case   92: ILLEGAL;
case   93: ILLEGAL;
case   94: ILLEGAL;
case   95: ILLEGAL;
case   96: ILLEGAL;
case   97: ILLEGAL;
case   98: ILLEGAL;
case   99: ILLEGAL;
case  100: ILLEGAL;
case  101: ILLEGAL;
case  102: ILLEGAL;
case  103: ILLEGAL;
case  104: INSTR("neg");  ADD(0,-RA);
case  105: ILLEGAL;
case  106: ILLEGAL;
case  107: POWER("mul");
case  108: ILLEGAL;
case  109: ILLEGAL;
case  110: ILLEGAL;
case  111: ILLEGAL;
case  112: ILLEGAL;
case  113: ILLEGAL;
case  114: ILLEGAL;
case  115: ILLEGAL;
case  116: ILLEGAL;
case  117: ILLEGAL;
case  118: ILLEGAL;
case  119: INSTR("lbzux");  RD = MEM(u_char , BYTE, RA = (RA + RB));  break;
case  120: ILLEGAL;
case  121: ILLEGAL;
case  122: ILLEGAL;
case  123: ILLEGAL;
case  124: INSTR("nor");  LOGIC( ~(RS | RB) );
case  125: ILLEGAL;
case  126: ILLEGAL;
case  127: ILLEGAL;
case  128: ILLEGAL;
case  129: ILLEGAL;
case  130: ILLEGAL;
case  131: ILLEGAL;
case  132: ILLEGAL;
case  133: ILLEGAL;
case  134: ILLEGAL;
case  135: ILLEGAL;
case  136: INSTR("subfe");  
	   if (XER.bits.CA) {
	       SUBC(RB,RA);
	   } else {
	       ADDC(RB,~RA);
	   }
           break;
case  137: ILLEGAL;
case  138: INSTR("adde");  
/* printf("adde: XER.bits.CA=%d RB %x -~RA %x\n", XER.bits.CA, RB, -(~RA)); */
	   if (XER.bits.CA) {
	       ADDC(RB,-(~RA));
	   } else {
	       ADDC(RB,RA);
	   }
           break;
case  139: ILLEGAL;
case  140: ILLEGAL;
case  141: ILLEGAL;
case  142: ILLEGAL;
case  143: ILLEGAL;
case  144: INSTR("mtcrf");  CR.all = RS;  break; /* XXX Ignores field mask */
case  145: ILLEGAL;
case  146: INSTR("mtmsr");  MSR = RD;	break;
case  147: ILLEGAL;
case  148: ILLEGAL;
case  149: ILLEGAL;
case  150: UNIMP("stwcx");
case  151: INSTR("stwx");  MEM(u_long , LONG, RA0 + RB) = RS;   break;
case  152: POWER("slq");
case  153: POWER("sle");
case  154: ILLEGAL;
case  155: ILLEGAL;
case  156: ILLEGAL;
case  157: ILLEGAL;
case  158: ILLEGAL;
case  159: ILLEGAL;
case  160: ILLEGAL;
case  161: ILLEGAL;
case  162: ILLEGAL;
case  163: ILLEGAL;
case  164: ILLEGAL;
case  165: ILLEGAL;
case  166: ILLEGAL;
case  167: ILLEGAL;
case  168: ILLEGAL;
case  169: ILLEGAL;
case  170: ILLEGAL;
case  171: ILLEGAL;
case  172: ILLEGAL;
case  173: ILLEGAL;
case  174: ILLEGAL;
case  175: ILLEGAL;
case  176: ILLEGAL;
case  177: ILLEGAL;
case  178: ILLEGAL;
case  179: ILLEGAL;
case  180: ILLEGAL;
case  181: ILLEGAL;
case  182: ILLEGAL;
case  183: INSTR("stwux");  MEM(u_long , LONG, RA = (RA + RB)) = RS;   break;
case  184: POWER("sliq");
case  185: ILLEGAL;
case  186: ILLEGAL;
case  187: ILLEGAL;
case  188: ILLEGAL;
case  189: ILLEGAL;
case  190: ILLEGAL;
case  191: ILLEGAL;
case  192: ILLEGAL;
case  193: ILLEGAL;
case  194: ILLEGAL;
case  195: ILLEGAL;
case  196: ILLEGAL;
case  197: ILLEGAL;
case  198: ILLEGAL;
case  199: ILLEGAL;
case  200: INSTR("subfze");  ADDC(~RA,XER.bits.CA); break;
case  201: ILLEGAL;
case  202: INSTR("addze");   ADDC(RA,XER.bits.CA); break;
case  203: ILLEGAL;
case  204: ILLEGAL;
case  205: ILLEGAL;
case  206: ILLEGAL;
case  207: ILLEGAL;
case  208: ILLEGAL;
case  209: ILLEGAL;
case  210:
#ifdef MMU
	INSTR("mtsr");  SR = RS;  break;
#else
	UNIMP("mtsr");
#endif
case  211: ILLEGAL;
case  212: ILLEGAL;
case  213: ILLEGAL;
case  214: ILLEGAL;
case  215: INSTR("stbx");   MEM(u_char , BYTE, RA0 + RB) = RS;    break;
case  216: POWER("sllq");
case  217: POWER("sleq");
case  218: ILLEGAL;
case  219: ILLEGAL;
case  220: ILLEGAL;
case  221: ILLEGAL;
case  222: ILLEGAL;
case  223: ILLEGAL;
case  224: ILLEGAL;
case  225: ILLEGAL;
case  226: ILLEGAL;
case  227: ILLEGAL;
case  228: ILLEGAL;
case  229: ILLEGAL;
case  230: ILLEGAL;
case  231: ILLEGAL;
case  232: UNIMP("subfme");
case  233: ILLEGAL;
case  234: UNIMP("addme");
case  235: INSTR("mullw");  
	   umtimes((u_long *)&scratch, (u_long *)&RD, RA, RB);
#ifdef OVERFLOWS
	   if (OE) {
	       XER.bits.SO |= (XER.bits.OV = (scratch != 0));
	   }
#endif
	   UPDATE_CR(RD);
           break;
case  236: ILLEGAL;
case  237: ILLEGAL;
case  238: ILLEGAL;
case  239: ILLEGAL;
case  240: ILLEGAL;
case  241: ILLEGAL;
case  242:
#ifdef MMU
	INSTR("mtsrin");  seg[RB] = RS;  break;
#else
	UNIMP("mtsrin");
#endif
case  243: ILLEGAL;
case  244: ILLEGAL;
case  245: ILLEGAL;
case  246: INSTR("dcbtst");  break;
case  247: INSTR("stbux");  MEM(u_char , BYTE, RA = (RA + RB)) = RS;   break;
case  248: POWER("slliq");
case  249: ILLEGAL;
case  250: ILLEGAL;
case  251: ILLEGAL;
case  252: ILLEGAL;
case  253: ILLEGAL;
case  254: ILLEGAL;
case  255: ILLEGAL;
case  256: ILLEGAL;
case  257: ILLEGAL;
case  258: ILLEGAL;
case  259: ILLEGAL;
case  260: ILLEGAL;
case  261: ILLEGAL;
case  262: ILLEGAL;
case  263: ILLEGAL;
case  264: POWER("doz");
case  265: ILLEGAL;
case  266: INSTR("add");
	   temp = RB + RA;
	   UPDATE_OV(temp,RB,RA);
	   UPDATE_CR(temp);
	   RD = temp;
           break;
case  267: ILLEGAL;
case  268: ILLEGAL;
case  269: ILLEGAL;
case  270: ILLEGAL;
case  271: ILLEGAL;
case  272: ILLEGAL;
case  273: ILLEGAL;
case  274: ILLEGAL;
case  275: ILLEGAL;
case  276: ILLEGAL;
case  277: POWER("lscbx");
case  278: INSTR("dcbt");  break;
case  279: INSTR("lhzx");   RD = MEM(u_short, WORD, RA0 + RB);   break;
case  280: ILLEGAL;
case  281: ILLEGAL;
case  282: ILLEGAL;
case  283: ILLEGAL;
case  284: INSTR("eqv");    LOGIC( ~(RS ^ RB) );
case  285: ILLEGAL;
case  286: ILLEGAL;
case  287: ILLEGAL;
case  288: ILLEGAL;
case  289: ILLEGAL;
case  290: ILLEGAL;
case  291: ILLEGAL;
case  292: ILLEGAL;
case  293: ILLEGAL;
case  294: ILLEGAL;
case  295: ILLEGAL;
case  296: ILLEGAL;
case  297: ILLEGAL;
case  298: ILLEGAL;
case  299: ILLEGAL;
case  300: ILLEGAL;
case  301: ILLEGAL;
case  302: ILLEGAL;
case  303: ILLEGAL;
case  304: ILLEGAL;
case  305: ILLEGAL;
case  306:
#ifdef MMU
		INSTR("tlbie"); tlbie(RB); break;
#else
		UNIMP("tlbie");
#endif
case  307: ILLEGAL;
case  308: ILLEGAL;
case  309: ILLEGAL;
case  310: UNIMP("eciwx");  /* uses RA0 */
case  311: INSTR("lhzux");  RD = MEM(u_short, WORD, RA = (RA + RB));   break;
case  312: ILLEGAL;
case  313: ILLEGAL;
case  314: ILLEGAL;
case  315: ILLEGAL;
case  316: INSTR("xor");    LOGIC( RS ^ RB );
case  317: ILLEGAL;
case  318: ILLEGAL;
case  319: ILLEGAL;
case  320: ILLEGAL;
case  321: ILLEGAL;
case  322: ILLEGAL;
case  323: ILLEGAL;
case  324: ILLEGAL;
case  325: ILLEGAL;
case  326: ILLEGAL;
case  327: ILLEGAL;
case  328: ILLEGAL;
case  329: ILLEGAL;
case  330: ILLEGAL;
case  331: POWER("div");
case  332: ILLEGAL;
case  333: ILLEGAL;
case  334: ILLEGAL;
case  335: ILLEGAL;
case  336: ILLEGAL;
case  337: ILLEGAL;
case  338: ILLEGAL;
case  339: INSTR("mfspr");  
	   switch(SPR) {
	       case    1: RD = XER.all;  break;
	       case    8: RD = LR;       break;
	       case    9: RD = CTR;      break;
	       case   22: RD = DEC;      break;
#ifdef MMU
	       case   25: SDR1  = RD;    break;
#endif
	       case   26: RD = SRR0;     break;
	       case   27: RD = SRR1;     break;
	       case  272: RD = SPRG0;    break;
	       case  273: RD = SPRG1;    break;
	       case  274: RD = SPRG2;    break;
	       case  275: RD = SPRG3;    break;
	       /*
		* Special simulator reg.  The return value indicates
		* whether or not page-zero addressing is supported.
		*/
#ifdef TRACE
	       case  287: TBAR = RD;  RD = 1;  break;
#else
	       case  287: TBAR = RD;  RD = 0;  break;
#endif
	       case 1008: RD = HID0;	 break;
	       case 1010: RD = IABR;	 break;
	       case 1023: RD = 0;	 break;
	       default: UNIMP("mfspr - bad SPR");
	   }
           break;
case  340: ILLEGAL;
case  341: ILLEGAL;
case  342: ILLEGAL;
case  343: INSTR("lhax");   RD = MEM(short  , WORD, RA0 + RB);   break;
case  344: ILLEGAL;
case  345: ILLEGAL;
case  346: ILLEGAL;
case  347: ILLEGAL;
case  348: ILLEGAL;
case  349: ILLEGAL;
case  350: ILLEGAL;
case  351: ILLEGAL;
case  352: ILLEGAL;
case  353: ILLEGAL;
case  354: ILLEGAL;
case  355: ILLEGAL;
case  356: ILLEGAL;
case  357: ILLEGAL;
case  358: ILLEGAL;
case  359: ILLEGAL;
case  360: POWER("abs");
case  361: ILLEGAL;
case  362: ILLEGAL;
case  363: POWER("divs");
case  364: ILLEGAL;
case  365: ILLEGAL;
case  366: ILLEGAL;
case  367: ILLEGAL;
case  368: ILLEGAL;
case  369: ILLEGAL;
case  370: ILLEGAL;
case  371: INSTR("mftb");
	   {
		extern void gettime();

	        switch(SPR) {
		    case 268:  gettime((long *)0, (long *)&RD);  break;
		    case 269:  gettime((long *)&RD, (long *)0);  break;
		    default:   UNIMP("mftbf - bad TBR");
		}
	   }
	   break;

case  372: ILLEGAL;
case  373: ILLEGAL;
case  374: ILLEGAL;
case  375: INSTR("lhaux");   RD = MEM(short  , WORD, RA = (RA + RB));   break;
case  376: ILLEGAL;
case  377: ILLEGAL;
case  378: ILLEGAL;
case  379: ILLEGAL;
case  380: ILLEGAL;
case  381: ILLEGAL;
case  382: ILLEGAL;
case  383: ILLEGAL;
case  384: ILLEGAL;
case  385: ILLEGAL;
case  386: ILLEGAL;
case  387: ILLEGAL;
case  388: ILLEGAL;
case  389: ILLEGAL;
case  390: ILLEGAL;
case  391: ILLEGAL;
case  392: ILLEGAL;
case  393: ILLEGAL;
case  394: ILLEGAL;
case  395: ILLEGAL;
case  396: ILLEGAL;
case  397: ILLEGAL;
case  398: ILLEGAL;
case  399: ILLEGAL;
case  400: ILLEGAL;
case  401: ILLEGAL;
case  402: ILLEGAL;
case  403: ILLEGAL;
case  404: ILLEGAL;
case  405: ILLEGAL;
case  406: ILLEGAL;
case  407: INSTR("sthx");   MEM(u_short, WORD, RA0 + RB) = RS;   break;
case  408: ILLEGAL;
case  409: ILLEGAL;
case  410: ILLEGAL;
case  411: ILLEGAL;
case  412: INSTR("orc");  LOGIC( RS | ~RB);
case  413: ILLEGAL;
case  414: ILLEGAL;
case  415: ILLEGAL;
case  416: ILLEGAL;
case  417: ILLEGAL;
case  418: ILLEGAL;
case  419: ILLEGAL;
case  420: ILLEGAL;
case  421: ILLEGAL;
case  422: ILLEGAL;
case  423: ILLEGAL;
case  424: ILLEGAL;
case  425: ILLEGAL;
case  426: ILLEGAL;
case  427: ILLEGAL;
case  428: ILLEGAL;
case  429: ILLEGAL;
case  430: ILLEGAL;
case  431: ILLEGAL;
case  432: ILLEGAL;
case  433: ILLEGAL;
case  434: ILLEGAL;
case  435: ILLEGAL;
case  436: ILLEGAL;
case  437: ILLEGAL;
case  438: UNIMP("ecowx");  /* uses RA0 */
case  439: INSTR("sthux");   MEM(u_short, WORD, RA = (RA + RB)) = RS;   break;
case  440: ILLEGAL;
case  441: ILLEGAL;
case  442: ILLEGAL;
case  443: ILLEGAL;
case  444: INSTR("or");    LOGIC( RS | RB );
case  445: ILLEGAL;
case  446: ILLEGAL;
case  447: ILLEGAL;
case  448: ILLEGAL;
case  449: ILLEGAL;
case  450: ILLEGAL;
case  451: ILLEGAL;
case  452: ILLEGAL;
case  453: ILLEGAL;
case  454: ILLEGAL;
case  455: ILLEGAL;
case  456: ILLEGAL;
case  457: ILLEGAL;
case  458: ILLEGAL;
case  459: INSTR("divwu"); RD = (u_long)RA / (u_long)RB; UPDATE_CR(RD);  break;
	   /* XXX Overflow is not handled */
case  460: ILLEGAL;
case  461: ILLEGAL;
case  462: ILLEGAL;
case  463: ILLEGAL;
case  464: ILLEGAL;
case  465: ILLEGAL;
case  466: ILLEGAL;
case  467: INSTR("mtspr");  
	   switch (SPR) {
	       case    1: XER.all = RD;  break;
	       case    8: LR    = RD;	 break;
	       case    9: CTR   = RD;	 break;
	       case   22: DEC   = RD;    break;
#ifdef MMU
	       case   25: SDR1  = RD;    break;
#endif
	       case   26: SRR0  = RD;	 break;
	       case   27: SRR1  = RD;	 break;
	       case  272: SPRG0 = RD;    break;
	       case  273: SPRG1 = RD;    break;
	       case  274: SPRG2 = RD;    break;
	       case  275: SPRG3 = RD;    break;
	       case 1008: HID0  = RD;
#ifdef BI_ENDIAN
					if (HID0 & 8) {
						LONG = 4; WORD = 6; BYTE = 7;
					} else {
						LONG = 0; WORD = 0; BYTE = 0;
					}
#endif
					 break;
	       case 1010: IABR  = RD;	 break;
	       default: UNIMP("mtspr - bad SPR");
	   }
           break;
case  468: ILLEGAL;
case  469: ILLEGAL;
case  470: INSTR("dcbi");  break;
case  471: ILLEGAL;
case  472: ILLEGAL;
case  473: ILLEGAL;
case  474: ILLEGAL;
case  475: ILLEGAL;
case  476: INSTR("nand");  LOGIC( ~(RS & RB) );
case  477: ILLEGAL;
case  478: ILLEGAL;
case  479: ILLEGAL;
case  480: ILLEGAL;
case  481: ILLEGAL;
case  482: ILLEGAL;
case  483: ILLEGAL;
case  484: ILLEGAL;
case  485: ILLEGAL;
case  486: ILLEGAL;
case  487: ILLEGAL;
case  488: POWER("nabs");
case  489: ILLEGAL;
case  490: ILLEGAL;
case  491: INSTR("divw");  RD = RA / RB;  UPDATE_CR(RD);  break;
	   /* XXX Overflow is not handled */
case  492: ILLEGAL;
case  493: ILLEGAL;
case  494: ILLEGAL;
case  495: ILLEGAL;
case  496: ILLEGAL;
case  497: ILLEGAL;
case  498: ILLEGAL;
case  499: ILLEGAL;
case  500: ILLEGAL;
case  501: ILLEGAL;
case  502: ILLEGAL;
case  503: ILLEGAL;
case  504: ILLEGAL;
case  505: ILLEGAL;
case  506: ILLEGAL;
case  507: ILLEGAL;
case  508: ILLEGAL;
case  509: ILLEGAL;
case  510: ILLEGAL;
case  511: ILLEGAL;
case  512: UNIMP("mcrxr");
case  513: ILLEGAL;
case  514: ILLEGAL;
case  515: ILLEGAL;
case  516: ILLEGAL;
case  517: ILLEGAL;
case  518: ILLEGAL;
case  519: ILLEGAL;
case  520: ILLEGAL;
case  521: ILLEGAL;
case  522: ILLEGAL;
case  523: ILLEGAL;
case  524: ILLEGAL;
case  525: ILLEGAL;
case  526: ILLEGAL;
case  527: ILLEGAL;
case  528: ILLEGAL;
case  529: ILLEGAL;
case  530: ILLEGAL;
case  531: POWER("clcs");
case  532: ILLEGAL;
case  533: UNIMP("lswx");
case  534: INSTR("lwbrx");  
	   temp = MEM(u_long , LONG, RA0 + RB);
	   RD = ((temp << 24) & 0xff000000) |
		((temp <<  8) & 0x00ff0000) |
		((temp >>  8) & 0x0000ff00) |
		((temp >> 24) & 0x000000ff);
           break;
case  535: UNIMP("lfsx");
/* XXX is it bit 16 or bit 26? */
case  536: INSTR("srw");  LOGIC( (RB & 0x10020 ? 0 : RS >> (RB & 0x1f)) ); break;
case  537: POWER("rrib");
case  538: ILLEGAL;
case  539: ILLEGAL;
case  540: ILLEGAL;
case  541: POWER("maskir");
case  542: ILLEGAL;
case  543: ILLEGAL;
case  544: ILLEGAL;
case  545: ILLEGAL;
case  546: ILLEGAL;
case  547: ILLEGAL;
case  548: ILLEGAL;
case  549: ILLEGAL;
case  550: ILLEGAL;
case  551: ILLEGAL;
case  552: ILLEGAL;
case  553: ILLEGAL;
case  554: ILLEGAL;
case  555: ILLEGAL;
case  556: ILLEGAL;
case  557: ILLEGAL;
case  558: ILLEGAL;
case  559: ILLEGAL;
case  560: ILLEGAL;
case  561: ILLEGAL;
case  562: ILLEGAL;
case  563: ILLEGAL;
case  564: ILLEGAL;
case  565: ILLEGAL;
case  566:
#ifdef MMU
	INSTR("tlbsync"); break;
#else
	UNIMP("tlbsync");
#endif
case  567: UNIMP("lfsux");
case  568: ILLEGAL;
case  569: ILLEGAL;
case  570: ILLEGAL;
case  571: ILLEGAL;
case  572: ILLEGAL;
case  573: ILLEGAL;
case  574: ILLEGAL;
case  575: ILLEGAL;
case  576: ILLEGAL;
case  577: ILLEGAL;
case  578: ILLEGAL;
case  579: ILLEGAL;
case  580: ILLEGAL;
case  581: ILLEGAL;
case  582: ILLEGAL;
case  583: ILLEGAL;
case  584: ILLEGAL;
case  585: ILLEGAL;
case  586: ILLEGAL;
case  587: ILLEGAL;
case  588: ILLEGAL;
case  589: ILLEGAL;
case  590: ILLEGAL;
case  591: ILLEGAL;
case  592: ILLEGAL;
case  593: ILLEGAL;
case  594: ILLEGAL;
case  595:
#ifdef MMU
	INSTR("mfsr");  RD = SR;  break;
#else
	UNIMP("mfsr");
#endif
case  596: ILLEGAL;
case  597: UNIMP("lswi");
case  598: INSTR("sync");   break;
case  599: UNIMP("lfdx");
case  600: ILLEGAL;
case  601: ILLEGAL;
case  602: ILLEGAL;
case  603: ILLEGAL;
case  604: ILLEGAL;
case  605: ILLEGAL;
case  606: ILLEGAL;
case  607: ILLEGAL;
case  608: ILLEGAL;
case  609: ILLEGAL;
case  610: ILLEGAL;
case  611: ILLEGAL;
case  612: ILLEGAL;
case  613: ILLEGAL;
case  614: ILLEGAL;
case  615: ILLEGAL;
case  616: ILLEGAL;
case  617: ILLEGAL;
case  618: ILLEGAL;
case  619: ILLEGAL;
case  620: ILLEGAL;
case  621: ILLEGAL;
case  622: ILLEGAL;
case  623: ILLEGAL;
case  624: ILLEGAL;
case  625: ILLEGAL;
case  626: ILLEGAL;
case  627: ILLEGAL;
case  628: ILLEGAL;
case  629: ILLEGAL;
case  630: ILLEGAL;
case  631: UNIMP("lfdux");
case  632: ILLEGAL;
case  633: ILLEGAL;
case  634: ILLEGAL;
case  635: ILLEGAL;
case  636: ILLEGAL;
case  637: ILLEGAL;
case  638: ILLEGAL;
case  639: ILLEGAL;
case  640: ILLEGAL;
case  641: ILLEGAL;
case  642: ILLEGAL;
case  643: ILLEGAL;
case  644: ILLEGAL;
case  645: ILLEGAL;
case  646: ILLEGAL;
case  647: ILLEGAL;
case  648: ILLEGAL;
case  649: ILLEGAL;
case  650: ILLEGAL;
case  651: ILLEGAL;
case  652: ILLEGAL;
case  653: ILLEGAL;
case  654: ILLEGAL;
case  655: ILLEGAL;
case  656: ILLEGAL;
case  657: ILLEGAL;
case  658: ILLEGAL;
case  659:
#ifdef MMU
	INSTR("mfsrin");  RD = seg[RB];  break;
#else
	UNIMP("mfsrin");
#endif
case  660: ILLEGAL;
case  661: UNIMP("stswx");
case  662: INSTR("stwbrx");  
	   temp = RS;
	   MEM(u_long , LONG, RA0 + RB) =
	        ((temp << 24) & 0xff000000) |
		((temp <<  8) & 0x00ff0000) |
		((temp >>  8) & 0x0000ff00) |
		((temp >> 24) & 0x000000ff);
           break;
case  663: UNIMP("stfsx");
case  664: POWER("srq");
case  665: POWER("sre");
case  666: ILLEGAL;
case  667: ILLEGAL;
case  668: ILLEGAL;
case  669: ILLEGAL;
case  670: ILLEGAL;
case  671: ILLEGAL;
case  672: ILLEGAL;
case  673: ILLEGAL;
case  674: ILLEGAL;
case  675: ILLEGAL;
case  676: ILLEGAL;
case  677: ILLEGAL;
case  678: ILLEGAL;
case  679: ILLEGAL;
case  680: ILLEGAL;
case  681: ILLEGAL;
case  682: ILLEGAL;
case  683: ILLEGAL;
case  684: ILLEGAL;
case  685: ILLEGAL;
case  686: ILLEGAL;
case  687: ILLEGAL;
case  688: ILLEGAL;
case  689: ILLEGAL;
case  690: ILLEGAL;
case  691: ILLEGAL;
case  692: ILLEGAL;
case  693: ILLEGAL;
case  694: ILLEGAL;
case  695: UNIMP("stfsux");
case  696: POWER("sriq");
case  697: ILLEGAL;
case  698: ILLEGAL;
case  699: ILLEGAL;
case  700: ILLEGAL;
case  701: ILLEGAL;
case  702: ILLEGAL;
case  703: ILLEGAL;
case  704: ILLEGAL;
case  705: ILLEGAL;
case  706: ILLEGAL;
case  707: ILLEGAL;
case  708: ILLEGAL;
case  709: ILLEGAL;
case  710: ILLEGAL;
case  711: ILLEGAL;
case  712: ILLEGAL;
case  713: ILLEGAL;
case  714: ILLEGAL;
case  715: ILLEGAL;
case  716: ILLEGAL;
case  717: ILLEGAL;
case  718: ILLEGAL;
case  719: ILLEGAL;
case  720: ILLEGAL;
case  721: ILLEGAL;
case  722: ILLEGAL;
case  723: ILLEGAL;
case  724: ILLEGAL;
case  725: UNIMP("stswi");
case  726: ILLEGAL;
case  727: UNIMP("stfdx");
case  728: POWER("srlq");
case  729: POWER("sreq");
case  730: ILLEGAL;
case  731: ILLEGAL;
case  732: ILLEGAL;
case  733: ILLEGAL;
case  734: ILLEGAL;
case  735: ILLEGAL;
case  736: ILLEGAL;
case  737: ILLEGAL;
case  738: ILLEGAL;
case  739: ILLEGAL;
case  740: ILLEGAL;
case  741: ILLEGAL;
case  742: ILLEGAL;
case  743: ILLEGAL;
case  744: ILLEGAL;
case  745: ILLEGAL;
case  746: ILLEGAL;
case  747: ILLEGAL;
case  748: ILLEGAL;
case  749: ILLEGAL;
case  750: ILLEGAL;
case  751: ILLEGAL;
case  752: ILLEGAL;
case  753: ILLEGAL;
case  754: ILLEGAL;
case  755: ILLEGAL;
case  756: ILLEGAL;
case  757: ILLEGAL;
case  758: ILLEGAL;
case  759: UNIMP("stfdux");
case  760: POWER("srliq");
case  761: ILLEGAL;
case  762: ILLEGAL;
case  763: ILLEGAL;
case  764: ILLEGAL;
case  765: ILLEGAL;
case  766: ILLEGAL;
case  767: ILLEGAL;
case  768: ILLEGAL;
case  769: ILLEGAL;
case  770: ILLEGAL;
case  771: ILLEGAL;
case  772: ILLEGAL;
case  773: ILLEGAL;
case  774: ILLEGAL;
case  775: ILLEGAL;
case  776: ILLEGAL;
case  777: ILLEGAL;
case  778: ILLEGAL;
case  779: ILLEGAL;
case  780: ILLEGAL;
case  781: ILLEGAL;
case  782: ILLEGAL;
case  783: ILLEGAL;
case  784: ILLEGAL;
case  785: ILLEGAL;
case  786: ILLEGAL;
case  787: ILLEGAL;
case  788: ILLEGAL;
case  789: ILLEGAL;
case  790: INSTR("lhbrx");  
	   temp = MEM(u_short, WORD, RA0 + RB);
	   RD = ((temp & 0xff) << 8 ) | (temp >> 8);
           break;
case  791: ILLEGAL;
case  792: INSTR("sraw");
	   LOGIC( (RB & 0x20 ? (long)RS >> 31 : (long)RS >> (RB & 0x1f)) );
	   break;
	   /* XXX handle XER.bits.CA */
case  793: ILLEGAL;
case  794: ILLEGAL;
case  795: ILLEGAL;
case  796: ILLEGAL;
case  797: ILLEGAL;
case  798: ILLEGAL;
case  799: ILLEGAL;
case  800: ILLEGAL;
case  801: ILLEGAL;
case  802: ILLEGAL;
case  803: ILLEGAL;
case  804: ILLEGAL;
case  805: ILLEGAL;
case  806: ILLEGAL;
case  807: ILLEGAL;
case  808: ILLEGAL;
case  809: ILLEGAL;
case  810: ILLEGAL;
case  811: ILLEGAL;
case  812: ILLEGAL;
case  813: ILLEGAL;
case  814: ILLEGAL;
case  815: ILLEGAL;
case  816: ILLEGAL;
case  817: ILLEGAL;
case  818: ILLEGAL;
case  819: ILLEGAL;
case  820: ILLEGAL;
case  821: ILLEGAL;
case  822: ILLEGAL;
case  823: ILLEGAL;
case  824: INSTR("srawi"); LOGIC( (long)RS >> SH );/* XXX handle XER.bits.CA */
case  825: ILLEGAL;
case  826: ILLEGAL;
case  827: ILLEGAL;
case  828: ILLEGAL;
case  829: ILLEGAL;
case  830: ILLEGAL;
case  831: ILLEGAL;
case  832: ILLEGAL;
case  833: ILLEGAL;
case  834: ILLEGAL;
case  835: ILLEGAL;
case  836: ILLEGAL;
case  837: ILLEGAL;
case  838: ILLEGAL;
case  839: ILLEGAL;
case  840: ILLEGAL;
case  841: ILLEGAL;
case  842: ILLEGAL;
case  843: ILLEGAL;
case  844: ILLEGAL;
case  845: ILLEGAL;
case  846: ILLEGAL;
case  847: ILLEGAL;
case  848: ILLEGAL;
case  849: ILLEGAL;
case  850: ILLEGAL;
case  851: ILLEGAL;
case  852: ILLEGAL;
case  853: ILLEGAL;
case  854: UNIMP("Old MacDonald had a farm - eieio");
case  855: ILLEGAL;
case  856: ILLEGAL;
case  857: ILLEGAL;
case  858: ILLEGAL;
case  859: ILLEGAL;
case  860: ILLEGAL;
case  861: ILLEGAL;
case  862: ILLEGAL;
case  863: ILLEGAL;
case  864: ILLEGAL;
case  865: ILLEGAL;
case  866: ILLEGAL;
case  867: ILLEGAL;
case  868: ILLEGAL;
case  869: ILLEGAL;
case  870: ILLEGAL;
case  871: ILLEGAL;
case  872: ILLEGAL;
case  873: ILLEGAL;
case  874: ILLEGAL;
case  875: ILLEGAL;
case  876: ILLEGAL;
case  877: ILLEGAL;
case  878: ILLEGAL;
case  879: ILLEGAL;
case  880: ILLEGAL;
case  881: ILLEGAL;
case  882: ILLEGAL;
case  883: ILLEGAL;
case  884: ILLEGAL;
case  885: ILLEGAL;
case  886: ILLEGAL;
case  887: ILLEGAL;
case  888: ILLEGAL;
case  889: ILLEGAL;
case  890: ILLEGAL;
case  891: ILLEGAL;
case  892: ILLEGAL;
case  893: ILLEGAL;
case  894: ILLEGAL;
case  895: ILLEGAL;
case  896: ILLEGAL;
case  897: ILLEGAL;
case  898: ILLEGAL;
case  899: ILLEGAL;
case  900: ILLEGAL;
case  901: ILLEGAL;
case  902: ILLEGAL;
case  903: ILLEGAL;
case  904: ILLEGAL;
case  905: ILLEGAL;
case  906: ILLEGAL;
case  907: ILLEGAL;
case  908: ILLEGAL;
case  909: ILLEGAL;
case  910: ILLEGAL;
case  911: ILLEGAL;
case  912: ILLEGAL;
case  913: ILLEGAL;
case  914: ILLEGAL;
case  915: ILLEGAL;
case  916: ILLEGAL;
case  917: ILLEGAL;
case  918: INSTR("sthbrx");  
	   temp = RS & 0xffff;
	   MEM(u_short, WORD, RA0 + RB) = ((temp & 0xff) << 8 ) | (temp >> 8);
           break;
case  919: ILLEGAL;
case  920: POWER("sraq");
case  921: POWER("srea");
case  922: INSTR("extsh");   LOGIC( (long)(RS << 16) >> 16 );
case  923: ILLEGAL;
case  924: ILLEGAL;
case  925: ILLEGAL;
case  926: ILLEGAL;
case  927: ILLEGAL;
case  928: ILLEGAL;
case  929: ILLEGAL;
case  930: ILLEGAL;
case  931: ILLEGAL;
case  932: ILLEGAL;
case  933: ILLEGAL;
case  934: ILLEGAL;
case  935: ILLEGAL;
case  936: ILLEGAL;
case  937: ILLEGAL;
case  938: ILLEGAL;
case  939: ILLEGAL;
case  940: ILLEGAL;
case  941: ILLEGAL;
case  942: ILLEGAL;
case  943: ILLEGAL;
case  944: ILLEGAL;
case  945: ILLEGAL;
case  946: ILLEGAL;
case  947: ILLEGAL;
case  948: ILLEGAL;
case  949: ILLEGAL;
case  950: ILLEGAL;
case  951: ILLEGAL;
case  952: POWER("sraiq");
case  953: ILLEGAL;
case  954: INSTR("extsb");  LOGIC( (long)(RS << 24) >> 24 );
case  955: ILLEGAL;
case  956: ILLEGAL;
case  957: ILLEGAL;
case  958: ILLEGAL;
case  959: ILLEGAL;
case  960: ILLEGAL;
case  961: ILLEGAL;
case  962: ILLEGAL;
case  963: ILLEGAL;
case  964: ILLEGAL;
case  965: ILLEGAL;
case  966: ILLEGAL;
case  967: ILLEGAL;
case  968: ILLEGAL;
case  969: ILLEGAL;
case  970: ILLEGAL;
case  971: ILLEGAL;
case  972: ILLEGAL;
case  973: ILLEGAL;
case  974: ILLEGAL;
case  975: ILLEGAL;
case  976: ILLEGAL;
case  977: ILLEGAL;
case  978:
#ifdef MMU
	INSTR("tlbld");  ONLY603  mmutab[RB >> 12] = RPA & 0xfffff00;  break;
#else
	UNIMP("tlbld");
#endif
case  979: ILLEGAL;
case  980: ILLEGAL;
case  981: ILLEGAL;
case  982: INSTR("icbi");  break;
case  983: ILLEGAL;
case  984: ILLEGAL;
case  985: ILLEGAL;
case  986: ILLEGAL;
case  987: ILLEGAL;
case  988: ILLEGAL;
case  989: ILLEGAL;
case  990: ILLEGAL;
case  991: ILLEGAL;
case  992: ILLEGAL;
case  993: ILLEGAL;
case  994: ILLEGAL;
case  995: ILLEGAL;
case  996: ILLEGAL;
case  997: ILLEGAL;
case  998: ILLEGAL;
case  999: ILLEGAL;
case 1000: ILLEGAL;
case 1001: ILLEGAL;
case 1002: ILLEGAL;
case 1003: ILLEGAL;
case 1004: ILLEGAL;
case 1005: ILLEGAL;
case 1006: ILLEGAL;
case 1007: ILLEGAL;
case 1008: ILLEGAL;
case 1009: ILLEGAL;
case 1010:
#ifdef MMU
	INSTR("tlbli");  ONLY603  mmutab[RB >> 12] = RPA & 0xfffff00;  break;
#else
	UNIMP("tlbli");
#endif
case 1011: ILLEGAL;
case 1012: ILLEGAL;
case 1013: ILLEGAL;
case 1014: UNIMP("dcbz");
case 1015: ILLEGAL;
case 1016: ILLEGAL;
case 1017: ILLEGAL;
case 1018: ILLEGAL;
case 1019: ILLEGAL;
case 1020: ILLEGAL;
case 1021: ILLEGAL;
case 1022: ILLEGAL;
case 1023: ILLEGAL;
			} /* End of big 31-class switch */
		} /* End of main opcode switch */

		continue;
power:
		if (!TBAR)
		    printf("Unimplemented POWER instruction %08lx (%s) at %lx\n",
		           (long)instruction, (long)opname, (long)CIA);
		goto trapout;

unimplemented:
		if (!TBAR)
		    printf("Unimplemented instruction %08lx (%s)at %lx\n",
		           (long)instruction, (long)opname, (long)CIA);
		goto trapout;

illegal:
		if (!TBAR)
		    printf("Illegal instruction %08lx at %lx\n",
			   (long)instruction, (long)CIA, (long)0);

trapout:
		if (TBAR) {
			SRR0 = CIA;
			SRR1 = MSR;
			pc = TBAR + 0x700 - 4;
			continue;
		} else
			return;

	}  /* End of main loop */
}


umtimes(dhighp, dlowp, u1, u2)
    u_long *dhighp, *dlowp;
    u_long u1, u2;
{
    register u_long ah, al, bh, bl, tmp;
    extern void dplus();

    ah = u1>>16;  al = u1 & 0xffff;
    bh = u2>>16;  bl = u2 & 0xffff;

    *dhighp = ah*bh;  *dlowp = al*bl;
    
    tmp = ah*bl;
    dplus((long *)dhighp, (long *)dlowp, (long)(tmp>>16), (long)(tmp<<16));

    tmp = al*bh;
    dplus((long *)dhighp, (long *)dlowp, (long)(tmp>>16), (long)(tmp<<16));
}

/* Carry calculation assumes 2's complement arithmetic. */
#define CARRY(res,b)  ((u_long)res < (u_long)b)

void
dplus(dhighp, dlowp, shigh, slow)
    register long *dhighp, *dlowp, shigh, slow;
{
    register long lowres;

    lowres   = *dlowp + slow;
    *dhighp += shigh + CARRY(lowres, slow);
    *dlowp   = lowres;
}


#ifdef TRACE
#include <sys/signal.h>
dumpregs()
{
#ifdef ARGREGS
	printf(
	 "      r0         r1         r2         r3         r4         r5\n"
	);
	printf(
	 "%8x   %8x   %8x   %8x   %8x   %8x\n\n",
	 greg[ 0],  greg[ 1],   greg[ 2],  greg[ 3],  greg[ 4],  greg[ 5]
	);

	printf(
	 "      r6         r7         r8         r9         r10        r11\n"
	);
	printf(
	 "%8x   %8x   %8x   %8x   %8x   %8x\n\n",
	 greg[ 6],  greg[ 7],   greg[ 8],  greg[ 9],  greg[10],  greg[11]
	);
#endif
	printf(
	 " r20  t0    r21  t1    r22  t2    r23  t3    r24  t4    r25  t5\n"
	);
	printf(
	 "%8x   %8x   %8x   %8x   %8x   %8x\n\n",
	 greg[20],  greg[21],   greg[22],  greg[23],  greg[24],  greg[25]
	);
	printf(
	 " r26 base   r27  up    r28 tos    r29  ip    r30  rp    r31  sp\n"
	);
	printf(
	 "%8x   %8x   %8x   %8x   %8x   %8x\n\n",
	 greg[26],  greg[27],   greg[28],  greg[29],  greg[30],  greg[31]
	);
	printf("pc %x  LR %x  CTR %x  CR %x",
		pc,    LR,    CTR,    CR.all
	);
#ifndef SIMROM
	printf("  CALLS: %x", greg[29]	/* IP */);

	if (greg[30])
		printf(" %x %x %x",
		 ((u_long *)greg[30])[0],	/* Return stack */
		 ((u_long *)greg[30])[1],
		 ((u_long *)greg[30])[2]
		);
	printf("\n");
#endif
}
dumpallregs()
{
        int i;
	for (i=0; i<8 ; i++)  printf("%9x", greg[i]);  putchar('\n');
	for (   ; i<16; i++)  printf("%9x", greg[i]);  putchar('\n');
	for (   ; i<24; i++)  printf("%9x", greg[i]);  putchar('\n');
	for (   ; i<32; i++)  printf("%9x", greg[i]);  putchar('\n');

	printf("pc %x  LR %x  CTR %x  CR %x  ",
		pc,    LR,    CTR,    CR.all
	);
	printf("\n");
}

void
handle_signal(foo)
	int foo;
{
	dumpregs();
	s_bye(1);
}
catch_signals()
{
	signal(SIGINT,handle_signal);
	signal(SIGILL,handle_signal);
	signal(SIGFPE,handle_signal);
	signal(SIGSEGV,handle_signal);
#ifdef UNIX
	signal(SIGTRAP,handle_signal);
//	signal(SIGEMT,handle_signal);
	signal(SIGBUS,handle_signal);
#endif
}

dumpmem(adr)
	long adr;
{
	u_long *reladr;

	reladr = (u_long *) &xmem[ (int)adr ];
	printf("%x: %8x %8x %8x %8x %8x %8x %8x %8x\n",
		adr,
		reladr[0], reladr[1], reladr[2], reladr[3],
		reladr[4], reladr[5], reladr[6], reladr[7]
	);
}

#ifdef SIMROM
#define GETLINE  (void)c_key();
#else
#define GETLINE
#endif
trace(name, instruction)
	char *name;
	u_long instruction;
{
	int done;
	int arg;
	int c;
	static int stepping = 1;

	if (!stepping & (!IABR || pc != IABR))
		return;

	IABR = 0;
	stepping = 1;

	printf("%x %x %s ", pc, greg[29], name);
	for (done=0; !done; ) {
		printf(" : ");
#ifndef SIMROM
		putchar(c = c_key());
		putchar('\n');
#else
		c = c_key();
#endif
		switch(c)
		{
			case 'b':  scanf("%x", &IABR); stepping = 0; break;
			case 'n':  IABR = greg[27]; stepping = 0; break;
			case 'u':  scanf("%x", &arg);
				   dumpmem((long)(greg[27]+arg));
				   GETLINE;
				   break;
			case 'm':  scanf("%x", &arg);
				   dumpmem((long)arg);
				   GETLINE;
				   break;
			case 'q':  s_bye(0); break;
			case 'r':  dumpregs();
				   GETLINE;
				   break;
			case 'a':  dumpallregs();
				   GETLINE;
				   break;
			case 'c':  stepping = 0; done=1; GETLINE; break;
			default: done=1; break;
		}
	}
}
#endif

#ifdef UNIX
#include <sys/time.h>
#else
/* ARGSUSED */
#endif
void
gettime(secp, nsecp)
    long *secp, *nsecp;
{
#ifdef UNIX
    struct timeval t;
    extern int gettimeofday();

    (void) gettimeofday(&t, (struct timezone *)0);
    if (secp)
	*secp = t.tv_sec;
    if (nsecp)
	*nsecp = t.tv_usec * 1000;
#endif
}
#define TOKEN 4
int
xfindnext(adr, strlen, base, link, alf)
    register u_char *adr;
    register long strlen;
    register long base;
    register u_long link;
    u_long *alf;
{
    register u_char *s, *p;
    register int namelen, len;

    while((link = *(u_long *)link + base) != base) {
        link -= TOKEN;		/* link is now the absolute alf */
        s = (u_char *)(link-1-strlen);
        p = adr;
	len = strlen;
	while (len-- && *s == *p) {
	    s++;
	    p++;
	}
	if ((len < 0) && ((*s & 0x1f) == strlen)) {
	    *alf = link;
	    return(-1);
	}
    }
    return(0);
}

// LICENSE_BEGIN
// Copyright (c) 2007 FirmWorks
// 
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// LICENSE_END
