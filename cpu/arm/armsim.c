//
// ARM32 Application-level simulator.
// 
// 
// Copyright (c) 2007 FirmWorks
// Copyright 2010 Apple, Inc. All rights reserved.
// See license at end.

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

typedef          char       s8;
typedef          short      s16;
typedef          int        s32;
typedef          long long  s64;
typedef unsigned char       u8;
typedef unsigned short      u16;
typedef unsigned int        u32;
typedef unsigned long long  u64;

static u32 trace = 0;

#if TRACE
#define INSTR(a)   if (trace) printf("%s -- %0x N%d Z%d C%d V%d %s\n", \
                          a, COND, N, Z, C, V, cond ? "true" : "false"); \
                   if (cond == 0) break
#else
#define INSTR(a)   if (cond == 0) break
#endif

#define MAXMEM 0x80000
#define MEM(type, adr)   *(type *)(&mem[(adr)])

u32 r[16];
#define SP r[13]
#define LR r[14]
#define PC r[15]

void regdump(u32 instruction, u32 last_pc, u8 cr)
{
    printf("  0 %08x 1 %08x 2 %08x 3 %08x\n", r[0],  r[1],  r[2],  r[3]);
    printf("  4 %08x 5 %08x 6 %08x 7 %08x\n", r[4],  r[5],  r[6],  r[7]);
    printf("  8 %08x 9 %08x a %08x b %08x\n", r[8],  r[9],  r[10], r[11]);
    printf("  c %08x d %08x e %08x f %08x\n", r[12], r[13], r[14], r[15]);
    printf("pc %08x lpc %08x i %08x ", PC - 8, last_pc, instruction);
    if (cr)
        putchar('\n');
}

#define UFIELD(lbit,nbits)  (      (instruction << (31 - lbit)) >> (32 - nbits))
#define SFIELD(lbit,nbits)  ((long)(instruction << (31 - lbit)) >> (32 - nbits))

#define COND      UFIELD(31, 4)
#define OP        UFIELD(27, 7)
#define S         UFIELD(20, 1)
#define L         UFIELD(20, 1)
#define RD      r[UFIELD(15, 4)]
#define RN      r[UFIELD(19, 4)]
#define RM      r[UFIELD( 3, 4)]
#define RS      r[UFIELD(11, 4)]
#define TYPE      UFIELD( 6, 2)
#define IMM5      UFIELD(11, 5)
#define OP1       UFIELD( 4, 1)
#define OP2       UFIELD( 7, 1)
#define ROT       UFIELD(11, 4)
#define IMM8      UFIELD( 7, 8)
#define IMM24     UFIELD(23,24)
#define LINK      UFIELD( 5, 1)
#define MSB       UFIELD(20, 5)
#define LSB       UFIELD(11, 5)
#define BXTYPE    UFIELD( 7, 4)
#define IMM12     UFIELD(11,12)
#define IMM16   ((UFIELD(19, 4) << 12) | IMM12)
#define IMMHL   ((UFIELD(11, 4) << 4) | UFIELD( 3, 4))
#define P         UFIELD(24, 1)
#define U         UFIELD(23, 1)
#define W         UFIELD(21, 1)

// In BTGT we want to force a PC update. Since we don't implement Thumb
// the value "1" must always be invalid for last_pc.
struct { signed int imm24:24; } sext24;
#define BTGT   { PC += sext24.imm24 = (IMM24 << 2); last_pc = 1; }

#define ROTATE(imm, rot) (((imm) >> (rot)) | ((imm) << (32-(rot))))
#define IMM32     ROTATE(IMM8, (ROT<<1))

#define SHSRC (OP1 ? RS : IMM5)
#define SHFT(res) \
{ \
    switch (TYPE) { \
    case 0: res = RM << SHSRC; break; \
    case 1: res = RM >> SHSRC; break; \
    case 2: if (SHSRC == 0) { res = ((s32)(RM) < 0) ? -1 : 0; } else { res = (s32)(RM) >> SHSRC; } break; \
    case 3: res = ROTATE(RM, SHSRC); \
    } \
}

#define BF(sb, eb) ((u32)(((s32)0x80000000) >> (sb - eb))) >> (31 - sb);

union {
    u32 all;
    struct {
        u32 res :28;
        u32 Vbit:1;
        u32 Zbit:1;
        u32 Cbit:1;
        u32 Nbit:1;
    } bits;
} APSR;

#define N       (APSR.bits.Nbit)
#define Z       (APSR.bits.Zbit)
#define C       (APSR.bits.Cbit)
#define V       (APSR.bits.Vbit)

// FIXME: We're skipping the V bit for now.

/* Leave C alone. */
#define UPCC(res) \
{ \
    if (S) { \
        N = (res) >> 31; \
        Z = (res == 0); \
/* FIXME - possible problem with C bit - should be set to carry output from shifter */ \
    } \
}

#define ADC(dest, a, b, c) \
{ \
    temp = (a) + (b) + (c); \
    if (S) { \
        N = temp >> 31; \
        Z = temp == 0; \
        C = (temp < (a)) || ((c) && (temp == (a)));                     \
        V = ((((s32)(temp)^(s32)(a)) < 0) && (((s32)(a)^(s32)(b)) >= 0));  \
    } \
    dest = temp; \
}
    
#define SBB(dest, a, b, c) \
{ \
    temp = (a) - (b) - (!(c));    \
    if (S) { \
        N = temp >> 31; \
        Z = temp == 0;                             \
        C = !(((a) < temp) || ((!(c)) && ((a) == temp)));               \
        V = ((((s32)temp^(s32)(a)) < 0) && (((s32)(a)^(s32)(b)) < 0));         \
    } \
    dest = temp; \
}
    
#define UNIMP(s) \
{ \
    printf("UNIMPLEMENTED '%s' op %02x s %d bxtype %02x\n", s, OP, S, BXTYPE); \
    regdump(instruction, last_pc, 1); \
    return; \
}

#define EVAL_COND(cc) \
{ \
    switch (cc) { \
    case 0x0:       cond = (Z == 1); break; \
    case 0x1:       cond = (Z == 0); break; \
    case 0x2:       cond = (C == 1); break; \
    case 0x3:       cond = (C == 0); break; \
    case 0x4:       cond = (N == 1); break; \
    case 0x5:       cond = (N == 0); break; \
    case 0x6:       cond = (V == 1); break; \
    case 0x7:       cond = (V == 0); break; \
    case 0x8:       cond = (C == 1 && Z == 0); break; \
    case 0x9:       cond = (C == 0 || Z == 1); break; \
    case 0xa:       cond = (N == V); break; \
    case 0xb:       cond = (N != V); break; \
    case 0xc:       cond = (Z == 0 && N == V); break; \
    case 0xd:       cond = (Z == 1 || N != V); break; \
    case 0xe:       cond = (1); break; \
    case 0xf:       cond = (0xf); break; \
    } \
}

u32 instruction;
u32 last_pc;

void simhandler(int sig)
{
    extern void restoremode();

	psignal(sig, "forth");
    regdump(instruction, last_pc, 1);
    restoremode();
    exit(1);
}

               // alf = find(adr, len, link, origin);
u32 *
find(u8 *adr, u32 len, u32 *link, void *origin)
{
    u8 *wp, *np;
    u32 namelen;
    
    while (link != origin) {
        link -= 1;  // Move from code field to link field
        np = (u8 *)link - 1;
        namelen = (*np) & 0x1f;
        if (namelen == len) {
            np -= namelen;
            wp = adr;
            while (namelen--) {
                if (*np++ != *wp++) {
                    break;
                }
            }
            if (namelen == -1) {
                return (link);
            }
        }
        link = (u32 *)*link;
    }
    return ((u32 *)0);
}

void
simulate(u8 *mem, u32 start, u32 header, u32 syscall_vec,
         u32 memtop, u32 argc, u32 argv)
{
    // register u32 instruction;
    register u32 res;
    register u32 cond;
    register u32 temp;
    u32 indent = 0;
    u32 name;
    u32 namelen;
    // u32 last_pc;

	signal(SIGBUS, simhandler);
	signal(SIGSEGV, simhandler);

    APSR.all = 0;
    PC = start + 8;  // Stupid ARM.
    r[0] = header;
    r[1] = 0;        // Tell Forth it is using the simulator
    r[2] = memtop;
    r[3] = argc;
    SP = memtop;
    *((u32 *)SP) = argv;

    while (1) {
        instruction = MEM(u32, PC - 8);
        last_pc = PC;
#if TRACE
        if (trace)
            regdump(instruction, last_pc, 0);
#endif
        EVAL_COND(COND);
        if (cond == 0xf)
                UNIMP("unconditional");
        switch (OP) {
case 0x00: if (OP1 == 0 || OP2 == 0) {
               INSTR("and"); SHFT(res); RD = RN & res; UPCC(RD); break;
           }
           switch (BXTYPE) {
           case 0x9: INSTR("mul"); RN = RS * RM; UPCC(RN); break;
    // P=0, U=0, bit22=0, W=0 - post-index, add offset, register, no writeback
           case 0xb:
               if (L) {
                   INSTR("ldrh");
                   RD = MEM(u16, RN);
                   RN = RN + RM;
               } else {
                   INSTR("strh");
                   MEM(u16, RN) = RD;
                   RN = RN + RM;
               }
               break;
           case 0xd:
               if (L) {
                   INSTR("ldrsb");
                   RD = MEM(s8, RN);
                   RN = RN + RM;
               } else {
                   UNIMP("ldrd");
               }
               break;
           case 0xf: if (L) {
                   INSTR("ldrsh");
                   RD = MEM(s16, RN);
                   RN = RN + RM;
               } else {
                   UNIMP("strd");
               }
               break;
           default:  UNIMP("BXTYPE"); break;
           } break;
case 0x01: if (OP1 == 0 || OP2 == 0) {
               INSTR("eor"); SHFT(res); RD = RN ^ res; UPCC(RD); break;
           }
           switch (BXTYPE) {
           case 0x9: UNIMP("mla"); break;
    // P=0, U=0, bit22=0, W=1 - post-index, add offset, register, writeback - UNPREDICTABLE (P=0, W=1)
           case 0xb: UNIMP("ldrh"); break;  // UNPREDICTABLE
           case 0xd: UNIMP("ldrd"); break;  // UNPREDICTABLE
           case 0xf: UNIMP("ldrsh"); break; // UNPREDICTABLE
           } break;
case 0x02: if (OP1 == 0 || OP2 == 0) {
               INSTR("sub"); SHFT(res); SBB(RD, RN, res, 1); break;
           }
           switch (BXTYPE) {
    // P=0, U=0, bit22=1, W=0 - post-index, add offset, immediate, no writeback
           case 0xb:
               if (L) {
                   INSTR("ldrh");
                   RD = MEM(u16, RN);
                   RN = RN + IMMHL;
               } else {
                   INSTR("strh");
                   MEM(u16, RN) = RD;
                   RN = RN + IMMHL;
               }
               break;
           case 0xd:
               if (L) {
                   INSTR("ldrsb");
                   RD = MEM(s8, RN);
                   RN = RN + IMMHL;
               } else {
                   UNIMP("ldrd");
               }
               break;
           case 0xf: if (L) {
                   INSTR("ldrsh");
                   RD = MEM(s16, RN);
                   RN = RN + IMMHL;
               } else {
                   UNIMP("strd");
               }
               break;
           default:  UNIMP("BXTYPE"); break;
           } break;
case 0x03: if (OP1 == 0 || OP2 == 0) {
               INSTR("rsb"); SHFT(res); SBB(RD, res, RN, 1); break;
           } else {
               switch (BXTYPE) {
               case 0x1:
               case 0x3:
               case 0x5:
               case 0x7: INSTR("rsb"); SHFT(res); SBB(RD, res, RN, 1); break;
               case 0x9: UNIMP("mls"); break;
    // P=0, U=0, bit22=1, W=1 - post-index, add offset, immediate, writeback - UNPREDICTABLE (P=0, W=1)
               case 0xb: UNIMP("ldrh"); break;  // UNPREDICTABLE
               case 0xd: UNIMP("ldrd"); break;  // UNPREDICTABLE
               case 0xf: UNIMP("ldrsh"); break; // UNPREDICTABLE
               } break;
           } break;
case 0x04: if (OP1 == 0 || OP2 == 0) {
               INSTR("add"); SHFT(res); ADC(RD, RN, res, 0); break;
           }
           switch (BXTYPE) {
    // P=0, U=1, bit22=0, W=0 - post-index, subtract offset, register, no writeback
           case 0xb:
               if (L) {
                   INSTR("ldrh");
                   RD = MEM(u16, RN);
                   RN = RN - RM;
               } else {
                   INSTR("strh");
                   MEM(u16, RN) = RD;
                   RN = RN - RM;
               }
               break;
           case 0xd:
               if (L) {
                   INSTR("ldrsb");
                   RD = MEM(s8, RN);
                   RN = RN - RM;
               } else {
                   UNIMP("ldrd");
               }
               break;
           case 0xf: if (L) {
                   INSTR("ldrsh");
                   RD = MEM(s16, RN);
                   RN = RN - RM;
               } else {
                   UNIMP("strd");
               }
               break;
           default:  UNIMP("BXTYPE"); break;
           } break;
case 0x05: if (OP1 == 0 || OP2 == 0) {
               INSTR("adc"); SHFT(res); ADC(RD, RN, res, C); break;
           }
           switch (BXTYPE) {
    // P=0, U=1, bit22=0, W=1 - post-index, subtract offset, register, writeback - UNPREDICTABLE (P=0, W=1)
           case 0xb: UNIMP("ldrh"); break;  // UNPREDICTABLE
           case 0xd: UNIMP("ldrd"); break;  // UNPREDICTABLE
           case 0xf: UNIMP("ldrsh"); break; // UNPREDICTABLE
           default:  UNIMP("BXTYPE"); break;
           } break;
case 0x06: if (OP1 == 0 || OP2 == 0) {
               INSTR("sbc"); SHFT(res); 
//               printf("sbc RN %x res %x ~res %x C %x -- ", RN, res, ~(res), C);
//               ADC(RD, RN, ~(res), C); 
//               printf("res %x\n", RD);
//               printf("sbc RN %x res %x ~res %x C %x -- ", RN, res, ~(res), C);
               SBB(RD, RN, res, C); 
//               printf("res %x\n", RD);
break;
           } else {
               switch (BXTYPE) {
               case 0x1:
               case 0x3:
               case 0x5:
               case 0x7: INSTR("sbc"); SHFT(res); SBB(RD, res, RN, C); break;
               case 0x9: UNIMP("smull"); break;
    // P=0, U=1, bit22=1, W=0 - post-index, subtract offset, immediate, no writeback
           case 0xb:
               if (L) {
                   INSTR("ldrh");
                   RD = MEM(u16, RN);
                   RN = RN - IMMHL;
               } else {
                   INSTR("strh");
                   MEM(u16, RN) = RD;
                   RN = RN - IMMHL;
               }
               break;
           case 0xd:
               if (L) {
                   INSTR("ldrsb");
                   RD = MEM(s8, RN);
                   RN = RN - IMMHL;
               } else {
                   UNIMP("ldrd");
               }
               break;
           case 0xf: if (L) {
                   INSTR("ldrsh");
                   RD = MEM(s16, RN);
                   RN = RN - IMMHL;
               } else {
                   UNIMP("strd");
               }
               break;
               default:  UNIMP("BXTYPE"); break;
               } break;
           } break;
case 0x07: if (OP1 == 0 || OP2 == 0) {
               INSTR("rsc"); SHFT(res); SBB(RD, res, RN, C); break;
           } else {
               switch (BXTYPE) {
               case 0x1:
               case 0x3:
               case 0x5:
               case 0x7: INSTR("rsc"); SHFT(res); SBB(RD, res, RN, C); break;
               case 0x9: UNIMP("smlal"); break;
    // P=0, U=1, bit22=1, W=1 - post-index, subtract offset, immediate, writeback - UNPREDICTABLE (P=0, W=1)
               case 0xb: UNIMP("ldrh"); break;  // UNPREDICTABLE
               case 0xd: UNIMP("ldrd"); break;  // UNPREDICTABLE
               case 0xf: UNIMP("ldrsh"); break; // UNPREDICTABLE
               default:  UNIMP("BXTYPE"); break;
               } break;
           } break;
case 0x08: switch (BXTYPE) {
           case 0x0: INSTR("mrs"); RD = APSR.all; break;
           case 0x5: UNIMP("qadd"); break;
           case 0x8:
           case 0xa:
           case 0xc:
           case 0xe: UNIMP("smlabb"); break;
    // P=1, U=0, bit22=0, W=0 - offset/pre-index, subtract offset, register, no writeback
           case 0xb:
               if (L) {
                   INSTR("ldrh");
                   RD = MEM(u16, RN - RM);
               } else {
                   INSTR("strh");
                   MEM(u16, RN - RM) = RD;
               }
               break;
           case 0xd:
               if (L) {
                   INSTR("ldrsb");
                   RD = MEM(s8, RN - RM);
               } else {
                   UNIMP("ldrd");
               }
               break;
           case 0xf: if (L) {
                   INSTR("ldrsh");
                   RD = MEM(s16, RN - RM);
               } else {
                   UNIMP("strd");
               }
               break;
           default:  UNIMP("BXTYPE"); break;
           } break;
case 0x09: switch (BXTYPE) {
           case 0x0: UNIMP("msr"); break;
           case 0x1: INSTR("bx"); PC = RM; break;
           case 0x2: INSTR("bxj"); PC = RM; break;
           case 0x3: INSTR("blx"); if (LINK) LR = PC - 4; PC = RM; break;
           case 0x5: UNIMP("qsub"); break;
           case 0x7: UNIMP("bkpt"); break;
           case 0x8:
           case 0xa:
           case 0xc:
           case 0xe: UNIMP("smlawb"); break;
    // P=1, U=0, bit22=0, W=1 - offset/pre-index, subtract offset, register, writeback
           case 0xb:
               if (L) {
                   INSTR("ldrh");
                   temp = RN - RM;
                   RD = MEM(u16, temp);
                   RN = temp;
               } else {
                   INSTR("strh");
                   temp = RN - RM;
                   MEM(u16, temp) = RD;
                   RN = temp;
               }
               break;
           case 0xd:
               if (L) {
                   INSTR("ldrsb");
                   temp = RN - RM;
                   RD = MEM(s8, temp);
                   RN = temp;
               } else {
                   UNIMP("ldrd");
               }
               break;
           case 0xf: if (L) {
                   INSTR("ldrsh");
                   temp = RN - RM;
                   RD = MEM(s16, temp);
                   RN = temp;
               } else {
                   UNIMP("strd");
               }
               break;
           default: UNIMP("BXTYPE"); break;
           } break;
case 0x0a: if (OP1 == 0 || OP2 == 0) {
               INSTR("cmp"); SHFT(res); SBB(res, RN, res, 1); break;
           }
           switch (BXTYPE) {
           case 0x5: UNIMP("qdadd"); break;
           case 0x8:
           case 0xa:
           case 0xc:
           case 0xe: UNIMP("smlalbb"); break;
    // P=1, U=0, bit22=1, W=0 - offset/pre-index, subtract offset, immediate, no writeback
           case 0xb:
               if (L) {
                   INSTR("ldrh");
                   RD = MEM(u16, RN - IMMHL);
               } else {
                   INSTR("strh");
                   MEM(u16, RN - IMMHL) = RD;
               }
               break;
           case 0xd:
               if (L) {
                   INSTR("ldrsb");
                   RD = MEM(s8, RN - IMMHL);
               } else {
                   UNIMP("ldrd");
               }
               break;
           case 0xf: if (L) {
                   INSTR("ldrsh");
                   RD = MEM(s16, RN - IMMHL);
               } else {
                   UNIMP("strd");
               }
               break;
           default:  UNIMP("BXTYPE"); break;
           } break;
case 0x0b: if (OP1 == 0 || OP2 == 0) {
               if (S) {
                   INSTR("cmn"); SHFT(res); ADC(res, RN, res, 0); break;
               } else {
                   // "You don't need this instruction anyway."
                   //                      --mjterave@gmail.com
                   UNIMP("clz"); break;
               }
           }
           switch (BXTYPE) {
           case 0x5: UNIMP("qdsub"); break;
           case 0x8:
           case 0xa:
           case 0xc:
           case 0xe: UNIMP("smulbb"); break;
    // P=1, U=0, bit22=1, W=1 - offset/pre-index, subtract offset, immediate, writeback
           case 0xb:
               if (L) {
                   INSTR("ldrh");
                   temp = RN - IMMHL;
                   RD = MEM(u16, temp);
                   RN = temp;
               } else {
                   INSTR("strh");
                   temp = RN - IMMHL;
                   MEM(u16, temp) = RD;
                   RN = temp;
               }
               break;
           case 0xd:
               if (L) {
                   INSTR("ldrsb");
                   temp = RN - IMMHL;
                   RD = MEM(s8, temp);
                   RN = temp;
               } else {
                   UNIMP("ldrd");
               }
               break;
           case 0xf: if (L) {
                   INSTR("ldrsh");
                   temp = RN - IMMHL;
                   RD = MEM(s16, temp);
                   RN = temp;
               } else {
                   UNIMP("strd");
               }
               break;
           default:  UNIMP("BXTYPE"); break;
           } break;
case 0x0c: if (OP1 == 0 || OP2 == 0) {
               INSTR("orr"); SHFT(res); RD = RN | res; UPCC(res); break;
           } else {
               switch (BXTYPE) {
               case 0x1:
               case 0x3:
               case 0x5:
               case 0x7: INSTR("orr"); SHFT(res); RD = RN | res; UPCC(res);
                         break;
               case 0x9: UNIMP("ldrex"); break;
    // P=1, U=0, bit22=0, W=0 - offset/pre-index, subtract offset, register, no writeback
           case 0xb:
               if (L) {
                   INSTR("ldrh");
                   RD = MEM(u16, RN + RM);
               } else {
                   INSTR("strh");
                   MEM(u16, RN + RM) = RD;
               }
               break;
           case 0xd:
               if (L) {
                   INSTR("ldrsb");
                   RD = MEM(s8, RN + RM);
               } else {
                   UNIMP("ldrd");
               }
               break;
           case 0xf: if (L) {
                   INSTR("ldrsh");
                   RD = MEM(s16, RN + RM);
               } else {
                   UNIMP("strd");
               }
               break;
               default:  UNIMP("BXTYPE"); break;
               } break;
           } break;
case 0x0d: switch (BXTYPE) {
           case 0x0:
               if (instruction == 0xe1a00000) {
                   INSTR("nop"); break;
               } else if (IMM5 == 0) {
                   if (instruction == 0xe1a0f009) {  // mov pc,up  i.e. the part of NEXT at the end of each code word
                       INSTR("NEXT");
                   } else {
                       INSTR("mov");
                   }
                   RD = RM; UPCC(RD); break;
               } /* else fall through */
           case 0x8:
           case 0x1: INSTR("lsl"); SHFT(RD); UPCC(RD); break;
           case 0x2:
           case 0xa:
           case 0x3: INSTR("lsr"); SHFT(RD); UPCC(RD); break;
           case 0x4: 
           case 0xc:
           case 0x5: INSTR("asr"); SHFT(RD); UPCC(RD); break;
           case 0x6:
           case 0xe:
           case 0x7: INSTR("ror"); SHFT(RD); UPCC(RD); break;
           case 0x9: UNIMP("ldrexd"); break;
    // P=1, U=1, bit22=0, W=1 - offset/pre-index, add offset, register, writeback
           case 0xb:
               if (L) {
                   INSTR("ldrh");
                   temp = RN + RM;
                   RD = MEM(u16, temp);
                   RN = temp;
               } else {
                   INSTR("strh");
                   temp = RN + RM;
                   MEM(u16, temp) = RD;
                   RN = temp;
               }
               break;
           case 0xd:
               if (L) {
                   INSTR("ldrsb");
                   temp = RN + RM;
                   RD = MEM(s8, temp);
                   RN = temp;
               } else {
                   UNIMP("ldrd");
               }
               break;
           case 0xf: if (L) {
                   INSTR("ldrsh");
                   temp = RN + RM;
                   RD = MEM(s16, temp);
                   RN = temp;
               } else {
                   UNIMP("strd");
               }
               break;
           default:  UNIMP("BXTYPE"); break;
           }; break;
case 0x0e: if (OP1 == 0 || OP2 == 0) {
               INSTR("bic"); SHFT(res); RD = RN & ~res; UPCC(RD); break;
           }
           switch (BXTYPE) {
           case 0x9: UNIMP("ldrexb"); break;
    // P=1, U=1, bit22=1, W=0 - offset/pre-index, add offset, immediate, no writeback
           case 0xb:
               if (L) {
                   INSTR("ldrh");
                   RD = MEM(u16, RN + IMMHL);
               } else {
                   INSTR("strh");
                   MEM(u16, RN + IMMHL) = RD;
               }
               break;
           case 0xd:
               if (L) {
                   INSTR("ldrsb");
                   RD = MEM(s8, RN + IMMHL);
               } else {
                   UNIMP("ldrd");
               }
               break;
           case 0xf: if (L) {
                   INSTR("ldrsh");
                   RD = MEM(s16, RN + IMMHL);
               } else {
                   UNIMP("strd");
               }
               break;
           } break;
case 0x0f: if (OP1 == 0 || OP2 == 0) {
               INSTR("mvn"); SHFT(res); RD = ~res; UPCC(RD); break;
           } else {
               switch (BXTYPE) {
               case 0x9: UNIMP("ldrexh"); break;
    // P=1, U=1, bit22=1, W=1 - offset/pre-index, add offset, immediate, writeback
           case 0xb:
               if (L) {
                   INSTR("ldrh");
                   temp = RN + IMMHL;
                   RD = MEM(u16, temp);
                   RN = temp;
               } else {
                   INSTR("strh");
                   temp = RN + IMMHL;
                   MEM(u16, temp) = RD;
                   RN = temp;
               }
               break;
           case 0xd:
               if (L) {
                   INSTR("ldrsb");
                   temp = RN + IMMHL;
                   RD = MEM(s8, temp);
                   RN = temp;
               } else {
                   UNIMP("ldrd");
               }
               break;
           case 0xf: if (L) {
                   INSTR("ldrsh");
                   temp = RN + IMMHL;
                   RD = MEM(s16, temp);
                   RN = temp;
               } else {
                   UNIMP("strd");
               }
               break;
               default:  UNIMP("BXTYPE"); break;
               } break;
           } break;
case 0x10: INSTR("and"); RD = RN & IMM32; UPCC(RD); break;
case 0x11: INSTR("eor"); RD = RN ^ IMM32; UPCC(RD); break;
case 0x12: INSTR("sub"); SBB(RD, RN, IMM32, 1); break;
case 0x13: INSTR("rsb"); SBB(RD, IMM32, RN, 1); break;
case 0x14: /* if (instruction == 0xe2809020) trace = 0; */
           INSTR("add"); ADC(RD, RN, IMM32, 0); break;
case 0x15: INSTR("adc"); ADC(RD, RN, IMM32, C); break;
case 0x16: INSTR("sbc"); SBB(RD, IMM32, RN, C); break;
case 0x17: INSTR("rsc"); SBB(RD, IMM32, RN, C); break;
case 0x18: INSTR("mov"); RD = IMM16; break;
case 0x19: switch (BXTYPE) {
           case 0x0: INSTR("nop"); break;
           case 0x1:
           INSTR("wrc");
           if (RN == -2) {
               printf("Tracing on\n");
               trace = 1;
           } else if (RN == -1) {
//               trace = 1;
//               printf("find %x %x %x %x\n",r[2], r[1], r[0], r[3]);
               // alf = find(u8 *adr, u32 len, u32 *link, void *origin);
               r[0] = (u32)find((u8 *)r[2], r[1], (u32 *)r[0], (u8 *)r[3]);
//               printf("returns %x\n", r[0]);
           } else {
               /* Handle Forth wrapper calls - the call# is in RN */
               r[0] = (*(long (*) ())(*(long *)(syscall_vec + RN)))
                   (r[0],r[1],r[2],r[3],r[4],r[5]);
           }
           break;

           case 0xf: UNIMP("dbg"); break;
           default:  UNIMP("msr"); break;
           } break;
case 0x1a: if (S) {
               INSTR("cmp"); SBB(res, RN, IMM32, 1); break;
           } else {
               INSTR("movt"); RD = (IMM16 << 16) | (RD & 0xffff); break;
           }
case 0x1b: INSTR("cmn"); ADC(res, RN,  IMM32, 0); break;
case 0x1c: INSTR("orr"); RD = RN | IMM32; UPCC(RD); break;
case 0x1d: INSTR("mov"); RD = IMM32; UPCC(RD); break;
case 0x1e: INSTR("bic"); RD = RN & (~IMM32); UPCC(RD); break;
case 0x1f: INSTR("mvn"); RD = ~IMM32; UPCC(RD); break;
case 0x20:
case 0x21: if (L) {
               INSTR("ldr"); RD = MEM(u32, RN); RN -= IMM12;
           } else {
               INSTR("str"); MEM(u32, RN) = RD; RN -= IMM12;
           } break;
case 0x22:
case 0x23: if (L) {
               INSTR("ldrb"); RD = MEM(u8, RN); RN -= IMM12;
           } else {
               INSTR("strb"); MEM(u8, RN) = RD; RN -= IMM12;
           } break;
case 0x24: if (L) {
               if (UFIELD(19, 4) == 0xd) {
                   INSTR("pop"); RD = MEM(u32, RN); RN += IMM12;
               } else {
                   if (instruction == 0xe49cf004) {  // ldr pc,[ip],#4   i.e. the guts of NEXT
                       INSTR("DONEXT");
                   } else if (instruction == 0xe49ca004) {  // ldr tos,[ip],#4  i.e. the guts of (lit) and (')
                       INSTR("DOLIT");
                   } else {
                       if (instruction == 0xe49bc004) { indent--; if (indent < 0) indent = 0; }
                       INSTR("ldr");
                   }
                   RD = MEM(u32, RN); RN += IMM12;
                   if (trace) {
                       // If NEXT or ('), show the name of the word
                       if ((instruction == 0xe49cf004) || (instruction == 0xe49ca004)) {
                           name = RD - 5;
                           // If name is not in the dictionary area, it is probably a numeric literal
                           if (name >= r[9] && ((name - r[9]) < 0x100000)) {
                               namelen = *(char *)name & 0x3f;
                               name = name - namelen;
                               // Indent with * for EMACS outline mode - handy for hiding subordinate calls
//                               for (temp = 0; temp < indent; temp++)
//                                   putchar('*');
                               while (namelen--)
                                   putchar(*(char *)name++);
                               printf("  Stack: %x %x %x %x indent %x\n" ,
                                      ((u32 *)r[13])[2], ((u32 *)r[13])[1], ((u32 *)r[13])[0], r[10], indent);
                           }
                       }
                   }
               }
           } else {
               INSTR("str"); MEM(u32, RN) = RD; RN += IMM12;
           } break;
case 0x25: if (L) {
               INSTR("ldr"); RD = MEM(u32, RN); RN += IMM12;
           } else {
               INSTR("str"); MEM(u32, RN) = RD; RN += IMM12;
           } break;
case 0x26:
case 0x27: if (L) {
               INSTR("ldrb"); RD = MEM(u8, RN); RN += IMM12;
           } else {
               INSTR("strb"); MEM(u8, RN) = RD; RN += IMM12;
           } break;
case 0x28: if (L) {
               INSTR("ldr"); RD = MEM(u32, RN - IMM12); break;
           } else {
               INSTR("str"); MEM(u32, RN - IMM12) = RD; break;
           } break;
case 0x29: if (L) {
               INSTR("ldr"); RN -= IMM12; RD = MEM(u32, RN); break;
           } else {
               if (instruction == 0xe52bc004) indent++;  // DOCOLON
               INSTR("str"); RN -= IMM12; MEM(u32, RN) = RD; 
               break;
           } break;
case 0x2a: if (L) {
               INSTR("ldrb"); RD = MEM(u8, RN - IMM12); break;
           } else {
               INSTR("strb"); MEM(u8, RN - IMM12) = RD; break;
           } break;
case 0x2b: if (L) {
               INSTR("ldrb"); RN -= IMM12; RD = MEM(u8, RN); break;
           } else {
               INSTR("strb"); RN -= IMM12; MEM(u8, RN) = RD; break;
           } break;
case 0x2c: if (L) {
               INSTR("ldr"); RD = MEM(u32, RN + IMM12); break;
           } else {
               INSTR("str"); MEM(u32, RN + IMM12) = RD; break;
           } break;
case 0x2d: if (L) {
               INSTR("ldr"); RN += IMM12; RD = MEM(u32, RN); break;
           } else {
               INSTR("str"); RN += IMM12; MEM(u32, RN) = RD; break;
           } break;
case 0x2e: if (L) {
               INSTR("ldrb"); RD = MEM(u8, RN + IMM12); break;
           } else {
               INSTR("strb"); MEM(u8, RN + IMM12) = RD; break;
           } break;
case 0x2f: if (L) {
               INSTR("ldrb"); RN += IMM12; RD = MEM(u8, RN); break;
           } else {
               INSTR("strb"); RN += IMM12; MEM(u8, RN) = RD; break;
           } break;
case 0x30:
case 0x31: if (OP1) {
               UNIMP("mcr"); break;
           } else if (L) {
               INSTR("ldr"); SHFT(res); RD = MEM(u32, RN); RN -= res; break;
           } else {
               INSTR("str"); SHFT(res); MEM(u32, RN) = RD; RN -= res; break;
           } break;
case 0x32:
case 0x33: if (OP1) {
               UNIMP("mcr"); break;
           } else if (L) {
               INSTR("ldrb"); SHFT(res); RD = MEM(u8, RN); RN -= res; break;
           } else {
               INSTR("strb"); SHFT(res); MEM(u8, RN) = RD; RN -= res; break;
           } break;
case 0x34:
case 0x35: if (OP1) {
               UNIMP("mcr"); break;
           } else if (L) {
               INSTR("ldr"); SHFT(res); RD = MEM(u32, RN); RN += res; break;
           } else {
               INSTR("str"); SHFT(res); MEM(u32, RN) = RD; RN += res; break;
           } break;
case 0x36:
case 0x37: if (OP1) {
               UNIMP("mcr"); break;
           } else if (L) {
               INSTR("ldrb"); SHFT(res); RD = MEM(u8, RN); RN += res; break;
           } else {
               INSTR("strb"); SHFT(res); MEM(u8, RN) = RD; RN += res; break;
           } break;
case 0x38: if (OP1) {
               UNIMP("smlad"); break;
           } else if (L) {
               INSTR("ldr"); SHFT(res); RD = MEM(u32, RN - res); break;
           } else {
               INSTR("str"); SHFT(res); MEM(u32, RN - res) = RD; break;
           } break;
case 0x39: if (L) {
               INSTR("ldr"); SHFT(res); RN -= res; RD = MEM(u32, RN); break;
           } else {
               INSTR("str"); SHFT(res); RN -= res; MEM(u32, RN) = RD; break;
           } break;
case 0x3a: if (OP1) {
               UNIMP("smlald"); break;
           } else if (L) {
               INSTR("ldrb"); SHFT(res); RD = MEM(u8, RN - res); break;
           } else {
               INSTR("strb"); SHFT(res); MEM(u8, RN - res) = RD; break;
           } break;
case 0x3b: if (L) {
               INSTR("ldrb"); SHFT(res); RN -= res; RD = MEM(u8, RN); break;
           } else {
               INSTR("strb"); SHFT(res); RN -= res; MEM(u8, RN) = RD; break;
           }
case 0x3c: if (L) {
               INSTR("ldr"); SHFT(res); RD = MEM(u32, RN + res); break;
           } else {
               INSTR("str"); SHFT(res); MEM(u32, RN + res) = RD; break;
           }
case 0x3d: if (OP1) {
               UNIMP("sbfx"); break;
           } else if (L) {
               INSTR("ldr"); SHFT(res); RN += res; RD = MEM(u32, RN); break;
           } else {
               INSTR("str"); SHFT(res); RN += res; MEM(u32, RN) = RD; break;
           } break;
case 0x3e: if (OP1) {
               if (UFIELD(3, 4) == 0xf) {
                   INSTR("bfc"); RD &= ~BF(MSB, LSB);
               } else {
                   INSTR("bfi");
                   RD &= ~BF(MSB, LSB);
                   RD |= RN & ~BF(MSB, LSB);
               }
           } else if (L) {
               INSTR("ldrb"); SHFT(res); RD = MEM(u8, RN + res);
           } else {
               INSTR("strb"); SHFT(res); MEM(u8, RN + res) = RD;
           } break;
case 0x3f: if (L) {
               INSTR("ldrb"); SHFT(res); RN += res; RD = MEM(u8, RN); break;
           } else {
               INSTR("strb"); SHFT(res); RN += res; MEM(u8, RN) = RD; break;
           } break;
case 0x40:
case 0x41: {   u32 base = RN;
               u32 reglist = UFIELD(15, 16);
               s32 reg;
               if (L) {
                   INSTR("ldmda");
               } else {
                   INSTR("stmda");
               }
               for (reg = 15; reg >= 0; reg--) {
                   if ((1 << reg) & reglist) {
                       if (L) {
                           r[reg] = MEM(u32, base);
                       } else {
                           MEM(u32, base) = r[reg];
                       }
                       base -= 4;
                   }
               }
               if (W) RN = base;
           } break;
case 0x42: UNIMP("xxx");
case 0x43: UNIMP("xxx");
case 0x44: 
case 0x45: {   u32 base = RN;
               u32 reglist = UFIELD(15, 16);
               s32 reg;
               if (L) {
                   INSTR("ldm");
               } else {
                   INSTR("stm");
               }
               for (reg = 0; reg < 16; reg++) {
                   if ((1 << reg) & reglist) {
                       if (L) {
                           r[reg] = MEM(u32, base);
                       } else {
                           MEM(u32, base) = r[reg];
                       }
                       base += 4;
                   }
               }
               if (W) RN = base;
           } break;
case 0x46: UNIMP("xxx");
case 0x47: UNIMP("xxx");
case 0x48:
case 0x49: {   u32 base = RN;
               u32 reglist = UFIELD(15, 16);
               s32 reg;
               if (L) {
                   INSTR("ldmdb");
               } else {
                   INSTR("stmdb");
               }
               for (reg = 15; reg >= 0; reg--) {
                   if ((1 << reg) & reglist) {
                       base -= 4;
                       if (L) {
                           r[reg] = MEM(u32, base);
                       } else {
                           MEM(u32, base) = r[reg];
                       }
                   }
               }
               if (W) RN = base;
           } break;
case 0x4a: UNIMP("xxx"); break;
case 0x4b: UNIMP("xxx"); break;
case 0x4c:
case 0x4d: {   u32 base = RN + 4;
               u32 reglist = UFIELD(15, 16);
               s32 reg;
               if (L) {
                   INSTR("ldmib");
               } else {
                   INSTR("stmib");
               }
               for (reg = 0; reg < 16; reg++) {
                   if ((1 << reg) & reglist) {
                       if (L) {
                           r[reg] = MEM(u32, base);
                       } else {
                           MEM(u32, base) = r[reg];
                       }
                       base += 4;
                   }
               }
               if (W) RN = base;
           } break;
case 0x4e: UNIMP("xxx"); break;
case 0x4f: UNIMP("xxx"); break;
case 0x50:
case 0x51:
case 0x52:
case 0x53:
case 0x54:
case 0x55:
case 0x56:
case 0x57: INSTR("b"); BTGT; break;
case 0x58:
case 0x59:
case 0x5a:
case 0x5b:
case 0x5c:
case 0x5d:
case 0x5e:
case 0x5f: INSTR("bl"); LR = PC - 4; BTGT; break;
case 0x60:
case 0x61: UNIMP("stc"); break;
case 0x62: UNIMP("mcrr"); break;
case 0x63:
case 0x64:
case 0x65:
case 0x66:
case 0x67:
case 0x68:
case 0x69:
case 0x6a:
case 0x6b:
case 0x6c:
case 0x6d:
case 0x6e: UNIMP("stc"); break;
case 0x6f: UNIMP("ldc"); break;
case 0x70:
case 0x71:
case 0x72:
case 0x73:
case 0x74:
case 0x75:
case 0x76:
case 0x77: UNIMP("cdp"); break;
case 0x78:
case 0x79:
case 0x7a:
case 0x7b:
case 0x7c:
case 0x7d:
case 0x7e:
case 0x7f: UNIMP("svc"); break;
        } // switch (OP)
        if (PC == last_pc)
            PC += 4;
        else // branch or move
            PC += 8;
    } // while (1)
}

// LICENSE_BEGIN
// Copyright (c) 2007 FirmWorks
// Copyright 2010 Apple, Inc. All rights reserved.
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
