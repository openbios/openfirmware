fc20.0000 value chip
: cl@  chip + rl@  ;
: cw@  chip + rw@  ;
: cb@  chip + rb@  ;
: cl!  chip + rl!  ;
: cw!  chip + rw!  ;
: cb!  chip + rb!  ;
: reg-set   dup cl@ rot or  swap cl!  ;
: reg-clr   dup cl@ rot invert and  swap cl!  ;

: lvds@  ( -- l )  h# 61180 cl@  ;  \ high bit is enable
h# 8000.0000 constant hibit

0 value err-max
0 value err-target
0 value div-max
0 value p-inc
0 value clock

\ This relies on the fact that p is always a multiple of 5
\ If p is a multiple of 10, i.e. even, p1 is p/10 and p2 is 0
\ Otherwise p1 is p/5 and p2 is 1
: splitp  ( p -- p1 p2 )  dup 1 and  if  5 /  1  else  d# 10 /  0  then  ;

\ We are looking for a solution to m = 5 * (m1 + 2) + (m2 + 2)
\ where 5 <= m2 <= 9.  If we substitute m3 = 5 + m2 and do so
\ algebra, we get   m - 17 = 5 * m1 + m3  where m3 is in the
\ right range to be a remainder mod 5.  IMHO, this is rather
\ an improvement over the linuxfb driver code, which uses a doubly
\ nested loop to search for a solution.
: splitm  ( m -- m1 m2 )
   d# 17 -  5  /mod   ( m3 m1 )
   swap 5 +           ( m1 m2 )
;

d# 96000 constant ref-clk

\ PLL parameters
\ m - 75..120  m1 - 10..20  m2 - 5..9  n - 4..7  p - 5..80  p1 - 1..8
\ vco - 1400000-2800000  p_transition_clk -  200000
\ ref_clk - 96000  p_inc_lo - 10   p_inc_hi - 5
0 value f-out
0 value f-vco
0 value err-best
0 value m-best
0 value n-best
0 value p-best

0 value f-best
0 value f-err
0 value p

: pll-calc  ( clock -- m1 m2 n p1 p2 clock' )
   to clock
   clock 5 * d# 1000 / to err-max
   clock d# 1000 / to err-target
   d# 10000000 to err-best
   0 to m-best
   0 to n-best
   0 to p-best

   clock d# 200000 <=  if  d# 10  else  d# 5  then  to p-inc
   d# 2800000 clock /  p-inc round-down  d# 80 min   ( p-max )

   1+  p-inc  do   \ Loop over P possibilities (i at this level is P)
      i to p
      i clock *  to f-vco  \ p * clock -> target VCO output frequency
      8 4 do               \ Loop over N values (i at this level is N)
         \ ceil of quotient
         i f-vco *  ref-clk /mod  swap  0<> -   ( approx-m )
         dup d# 120 min 1+   swap 1- d# 75 max  ( high+1 low )
         ?do  \ Loop over M values (i at this level is M)
            \ Calculate resultant clock frequency from this M,N,P
            ref-clk i * j / p /   to f-out               ( )
            \ Slightly bias the error to prefer generated clocks
            \ slightly lower than the target frequency
            clock f-out -  dup 0<=  if  negate 1+  then  ( f-err )
            dup err-best >=  if                          ( f-err )
               drop                                      ( )
            else                                         ( f-err )
               to f-err  f-out to f-best                 ( )
               i to m-best  j to n-best  p to p-best     ( )
            then
         loop
         f-out clock <  if  leave  then
      loop
   p-inc +loop
   m-best 0=  abort" Can't find parameters for clock"
   m-best splitm    ( m1 m2 )
   n-best 2-        ( m1 m2 n )
   p-best splitp    ( m1 m2 n p1 p2 )
   ref-clk m-best *  n-best / p-best /
;


: flush-pipe  ( -- )
   0 0
   d# 2000 0  do
      i d# 200 mod 0=  if
         hibit  h# 71008  reg-clr   \ Pipe B disable
      then
      h# 70000 cl@               ( n2 n1 n0 )
      2dup =  2over =  and  if   ( n2 n1 n0 )
         leave
      then
      rot drop
   loop
   3drop
;

: set-pll-a  ( -- )
   h# abcd0000 h# 61204 cl!  \ Unlock PLL

   hibit  h# 06014 reg-clr   \ Disable PLL A - value was 94.04.00.03
   h# 1004.0003 h# 06014 cl!
\ p2 << 24  |  (1 << (p1 - 1)) << 16   (p2 is 0 or 1, p1 is 0..1f)  
\ p2 = 0, p1 = 3 so p = 30
\ n << 16 | m1 << 8 | m2   n=4  m1=0x15(21)  m2=5  so m=5(21+2)+(5+2) = 122
\ clk = 96000 * 122 / 4 / 30 = 97600 kHz = 97.6 MHz
   h# 41505  h# 06040 cl!    \ FPA0
   h# 31108  h# 06044 cl!    \ FPA1
   hibit  h# 06014 reg-set   \ Enable PLL A

   \ saved-dvob  h# 61140 cl!   \ Restore DVO B  48.0000
   \ saved-dvoc  h# 61160 cl!   \ Restore DVO C  48.0000
   0 h# 61204 cl!  \ Relock PLL
;

: set-pll-b  ( -- )
   h# abcd0000 h# 61204 reg-set  \ Unlock PLL

   hibit  h# 06018 reg-clr   \ Disable PLL B - value was 98.02.60.03
   h# 1802.6003 h# 06018 cl!
\ p2 << 24  |  (1 << (p1 - 1)) << 16   (p2 is 0 or 1, p1 is 0..1f)  
\ p2 = 0, p1 = 2 so p = 20
\ n << 16 | m1 << 8 | m2   n=4  m1=0x16(22)  m2=6  so m=5(22+2)+(6+2) = 128
\ clk = 96000 * 128 / 4 / 20 = 153600 kHz = 153.6 MHz
\   h# 31108  h# 06040 cl!    \ FPA0
\   h# 31108  h# 06044 cl!    \ FPA1
   h# 41606  h# 06048 cl!    \ FPB0
   h# 31108  h# 0604c cl!    \ FPB1
   hibit  h# 06018 reg-set   \ Enable PLL B

   \ saved-dvob  h# 61140 cl!   \ Restore DVO B  48.0000
   \ saved-dvoc  h# 61160 cl!   \ Restore DVO C  48.0000
   h# abcd0000 h# 61204 reg-clr  \ Relock PLL
;

: lcd-graphics-mode
   hibit  h# 71400 reg-set   \ VGA OFF
   flush-pipe
   hibit  h# 61100 reg-clr   \ DAC OFF
   hibit  h# 70180 reg-clr   \ Disable Plane A
   hibit  h# 71180 reg-clr   \ Disable Plane B
   d# 20 ms   \ Wait at least 1 vblank interval
   hibit  h# 61140 reg-clr   \ Disable DVO B
   hibit  h# 61160 reg-clr   \ Disable DVO C
   \ hibit  h# 61100 reg-clr   \ DAC OFF
   h# c00 h# 61100 reg-set   \ DPMS D3 (disable sync)

\ noop
   set-pll-b

   hibit h# 61100 reg-set    \ Enable DAC
   h# 4000.8c18 h# 61100 cl! \ 8000.0000 enable DAC, 4000.0000:pipe B,
                          \ 8000:syncpolarity, 10:VSYNC on 8:Hsync on
                          \ C00:D3 state

   h# 5d5.0595  h# 61008 cl!  \ Hsync B
   h# 66a.0555  h# 61004 cl!  \ Hblank B
   h# 66a.0555  h# 61000 cl!  \ Htotal B
   h# 301.0300  h# 61014 cl!  \ Vsync B
   h# 303.02ff  h# 61010 cl!  \ Vblank B
   h# 303.02ff  h# 6100c cl!  \ Vtotal B
   h# 555.02ff  h# 6101c cl!  \ Src_size B

   hibit h# 71008 reg-set   \ Enable Pipe B
   h# c00 h# 61100 reg-clr  \ Enable sync

   h# 12 d# 26 <<           \ 8bpp w/gamma  (16 is 5, 24 is 6, 32 is 7)
   h# 100.0000 or           \ Pipe B
   h# 70180 cl!             \ Display Plane A control

   d# 1024 h# 70188 cl!     \ Plane A stride
   0 h# 70184 cl!           \ Plane a base (should be offset to skip stolen stuff I think)

   hibit  h# 70180 reg-set  \ Display Plane A control
   0 h# 70184 cl!           \ Plane A base (again)
;

: vga-graphics-mode
   h# 1010 config-l@ to chip  \ For desktop board

   hibit  h# 71400 reg-set   \ VGA OFF
   flush-pipe
   hibit  h# 61100 reg-clr   \ DAC OFF  (8000.0000)
   hibit  h# 70180 reg-clr   \ Disable Plane A (9400.0000)
   hibit  h# 71180 reg-clr   \ Disable Plane B (0100.0000)
   d# 20 ms   \ Wait at least 1 vblank interval
   hibit  h# 61140 reg-clr   \ Disable DVO B   (0048.0000)
   hibit  h# 61160 reg-clr   \ Disable DVO C   (0048.0000)
   h# c00 h# 61100 reg-set   \ DPMS D3 (disable sync)

   set-pll-a

   h# 8000.0c00 h# 61100 cl! \ 8000.0000 enable DAC, C00:D3 state

   h# 49f.0417  h# 60008 cl!  \ Hsync A
   h# 53f.03ff  h# 60004 cl!  \ Hblank A
   h# 53f.03ff  h# 60000 cl!  \ Htotal A
   h# 308.0302  h# 60014 cl!  \ Vsync A
   h# 325.02ff  h# 60010 cl!  \ Vblank A
   h# 325.02ff  h# 6000c cl!  \ Vtotal A
   h# 3ff.02ff  h# 6001c cl!  \ Src_size A

   hibit h# 70008 reg-set   \ Enable Pipe B
   hibit h# 71008 reg-set   \ Enable Pipe B
   h# c00 h# 61100 reg-clr  \ Enable sync

   d# 5 d# 26 <<            \ 8bpp w/gamma  (16 is 5, 24 is 6, 32 is 7)
   h# 70180 cl!             \ Display Plane A control

   h# 800 h# 70188 cl!      \ Plane A stride
   0 h# 70184 cl!           \ Plane a base (should be offset to skip stolen stuff I think)

   hibit  h# 70180 reg-set  \ Display Plane A control
   0 h# 70184 cl!           \ Plane A base (again)
;

0 [if]
In VGA mode, the beginning of the aperture contains an EGA style character map,
with char, attributes, and 6 bytes of something

function 0

1000  27a28086   900007  3000003   800000
1010  fc200000     1801 d0000008 fc300000
1020         0        0        0 900e104d
1030         0       90        0      10a
1040         0       48 71090009 a10a2523
1050    30000e       1b        0 3f800000
1060     20000        0        0        0
1070         0        0        0        0
1080         0        0        0        0
1090      d005        0        0        0
10a0         0        0        0        0
10b0         0        0        0        0
10c0       400        0        0        0
10d0    220001        0        0        0
10e0         0        0        0        0
10f0  34640000       ff    50f86        0

fc200000 BAR 0 size 80000 memory
    1800 BAR 1 size     8 I/O
d0000008 BAR 2 size 1000.0000 type 42  OFW has a bug in size handling when the 0x08 bit is set
fc300000 BAR 3 size 40000 memory

ok d000.0000 100 dump
           0  1  2  3  4  5  6  7   8  9  a  b  c  d  e  f  0123456789abcdef
d0000000  47 70 00 00 00 00 00 00  65 70 00 00 00 00 00 00  Gp......ep......
d0000010  6e 70 00 00 00 00 00 00  65 70 00 00 00 00 00 00  np......ep......
d0000020  72 70 00 00 00 00 00 00  69 70 00 00 00 00 00 00  rp......ip......
d0000030  63 70 00 00 00 00 00 00  20 70 00 00 00 00 00 00  cp...... p......
d0000040  50 70 00 00 00 00 00 00  43 70 00 00 00 00 00 00  Pp......Cp......
d0000050  2c 70 00 00 00 00 00 00  20 70 00 00 00 00 00 00  ,p...... p......
d0000060  53 70 00 00 00 00 00 00  65 70 00 00 00 00 00 00  Sp......ep......
d0000070  72 70 00 00 00 00 00 00  69 70 00 00 00 00 00 00  rp......ip......
d0000080  61 70 00 00 00 00 00 00  6c 70 7e 00 00 00 81 00  ap......lp~.....
d0000090  20 70 a5 00 00 00 81 00  23 70 81 00 00 00 bd 00   p%.....#p....=.
d00000a0  30 70 99 00 00 00 81 00  2c 70 81 00 00 00 7e 00  0p......,p....~.
d00000b0  20 70 00 00 00 00 00 00  31 70 00 00 00 00 00 00   p......1p......
d00000c0  30 70 00 00 00 00 00 00  31 70 00 00 00 00 00 00  0p......1p......
d00000d0  34 70 00 00 00 00 00 00  20 70 00 00 00 00 00 00  4p...... p......
d00000e0  4d 70 00 00 00 00 00 00  69 70 00 00 00 00 00 00  Mp......ip......
d00000f0  42 70 00 00 00 00 00 00  20 70 00 00 00 00 00 00  Bp...... p......

5555.5555 d000.0000 100 lfill  <<-- hangs system

function 1
BAR 0 says 0x80000  assigned address is fc280000
ok 0 bounds do  i config-l@ 9 u.r 4 +loop cr 10 +loop
1100  27a68086   900007  3800003   800000
1110  fc280000        0        0        0
1120         0        0        0 900e104d
1130         0       d0        0        0
1140         0       48 71090009 a10a2523
1150    30000e       1b        0 3f800000
1160     20000        0        0        0
1170         0        0        0        0
1180         0        0        0        0
1190         0        0        0        0
11a0         0        0        0        0
11b0         0        0        0        0
11c0       400        0        0        0
11d0    220001        0        0        0
11e0         0        0        0        0
11f0  34640000       ff    50f86        0

#ifndef _INTELFBHW_H
#define _INTELFBHW_H

/* $DHD: intelfb/intelfbhw.h,v 1.5 2003/06/27 15:06:25 dawes Exp $ */


/*** HW-specific data ***/

/* Information about the 852GM/855GM variants */
#define INTEL_85X_CAPID		0x44
#define INTEL_85X_VARIANT_MASK		0x7
#define INTEL_85X_VARIANT_SHIFT		5
#define INTEL_VAR_855GME		0x0
#define INTEL_VAR_855GM			0x4
#define INTEL_VAR_852GME		0x2
#define INTEL_VAR_852GM			0x5

/* Information about DVO/LVDS Ports */
#define DVOA_PORT  0x1
#define DVOB_PORT  0x2
#define DVOC_PORT  0x4
#define LVDS_PORT  0x8

/*
 * The Bridge device's PCI config space has information about the
 * fb aperture size and the amount of pre-reserved memory.
 */
#define INTEL_GMCH_CTRL		0x52   this is the config address in device 0
#define INTEL_GMCH_ENABLED		0x4
#define INTEL_GMCH_MEM_MASK		0x1
#define INTEL_GMCH_MEM_64M		0x1
#define INTEL_GMCH_MEM_128M		0

#define INTEL_830_GMCH_GMS_MASK		(0x7 << 4)
#define INTEL_830_GMCH_GMS_DISABLED	(0x0 << 4)
#define INTEL_830_GMCH_GMS_LOCAL	(0x1 << 4)
#define INTEL_830_GMCH_GMS_STOLEN_512	(0x2 << 4)
#define INTEL_830_GMCH_GMS_STOLEN_1024	(0x3 << 4)  
#define INTEL_830_GMCH_GMS_STOLEN_8192	(0x4 << 4)

#define INTEL_855_GMCH_GMS_MASK		(0x7 << 4)
#define INTEL_855_GMCH_GMS_DISABLED	(0x0 << 4)
#define INTEL_855_GMCH_GMS_STOLEN_1M	(0x1 << 4)
#define INTEL_855_GMCH_GMS_STOLEN_4M	(0x2 << 4)
#define INTEL_855_GMCH_GMS_STOLEN_8M	(0x3 << 4)
#define INTEL_855_GMCH_GMS_STOLEN_16M	(0x4 << 4)
#define INTEL_855_GMCH_GMS_STOLEN_32M	(0x5 << 4)

#define INTEL_915G_GMCH_GMS_STOLEN_48M	(0x6 << 4)
#define INTEL_915G_GMCH_GMS_STOLEN_64M	(0x7 << 4)

/* HW registers */

/* Fence registers */
#define FENCE			0x2000
#define FENCE_NUM			8

/* Primary ring buffer */
#define PRI_RING_TAIL		0x2030
#define RING_TAIL_MASK			0x001ffff8
#define RING_INUSE			0x1

#define PRI_RING_HEAD		0x2034
#define RING_HEAD_WRAP_MASK		0x7ff
#define RING_HEAD_WRAP_SHIFT		21
#define RING_HEAD_MASK			0x001ffffc

#define PRI_RING_START		0x2038
#define RING_START_MASK			0xfffff000

#define PRI_RING_LENGTH		0x203c
#define RING_LENGTH_MASK		0x001ff000
#define RING_REPORT_MASK		(0x3 << 1)
#define RING_NO_REPORT			(0x0 << 1)
#define RING_REPORT_64K			(0x1 << 1)
#define RING_REPORT_4K			(0x2 << 1)
#define RING_REPORT_128K		(0x3 << 1)
#define RING_ENABLE			0x1

/*
 * Tail can't wrap to any closer than RING_MIN_FREE bytes of the head,
 * and the last RING_MIN_FREE bytes need to be padded with MI_NOOP
 */
#define RING_MIN_FREE			64

#define IPEHR     		0x2088

#define INSTDONE		0x2090
#define PRI_RING_EMPTY			1

#define HWSTAM			0x2098
#define IER			0x20A0
#define IIR			0x20A4
#define IMR			0x20A8
#define VSYNC_PIPE_A_INTERRUPT		(1 << 7)
#define PIPE_A_EVENT_INTERRUPT		(1 << 4)
#define VSYNC_PIPE_B_INTERRUPT		(1 << 5)
#define PIPE_B_EVENT_INTERRUPT		(1 << 4)
#define HOST_PORT_EVENT_INTERRUPT	(1 << 3)
#define CAPTURE_EVENT_INTERRUPT		(1 << 2)
#define USER_DEFINED_INTERRUPT		(1 << 1)
#define BREAKPOINT_INTERRUPT		1

#define INSTPM			0x20c0
#define SYNC_FLUSH_ENABLE		(1 << 5)

#define INSTPS			0x20c4

#define MEM_MODE		0x20cc

#define MASK_SHIFT			16

#define FW_BLC_0		0x20d8
#define FW_DISPA_WM_SHIFT		0
#define FW_DISPA_WM_MASK		0x3f
#define FW_DISPA_BL_SHIFT		8
#define FW_DISPA_BL_MASK		0xf
#define FW_DISPB_WM_SHIFT		16
#define FW_DISPB_WM_MASK		0x1f
#define FW_DISPB_BL_SHIFT		24
#define FW_DISPB_BL_MASK		0x7

#define FW_BLC_1		0x20dc
#define FW_DISPC_WM_SHIFT		0
#define FW_DISPC_WM_MASK		0x1f
#define FW_DISPC_BL_SHIFT		8
#define FW_DISPC_BL_MASK		0x7

#define GPIOA             0x5010
#define GPIOB             0x5014
#define GPIOC             0x5018 // this may be external DDC on i830
#define GPIOD             0x501C // this is DVO DDC
#define GPIOE             0x5020 // this is DVO i2C
#define GPIOF             0x5024

/* PLL registers */
#define VGA0_DIVISOR		0x06000
#define VGA1_DIVISOR		0x06004
#define VGAPD			0x06010
#define VGAPD_0_P1_SHIFT		0
#define VGAPD_0_P1_FORCE_DIV2		(1 << 5)
#define VGAPD_0_P2_SHIFT		7
#define VGAPD_1_P1_SHIFT		8
#define VGAPD_1_P1_FORCE_DIV2		(1 << 13)
#define VGAPD_1_P2_SHIFT		15

#define DPLL_A			0x06014
#define DPLL_B			0x06018
#define DPLL_VCO_ENABLE			(1 << 31)
#define DPLL_2X_CLOCK_ENABLE		(1 << 30)
#define DPLL_SYNCLOCK_ENABLE		(1 << 29)
#define DPLL_VGA_MODE_DISABLE		(1 << 28)
#define DPLL_P2_MASK			1
#define DPLL_P2_SHIFT			23
#define DPLL_I9XX_P2_SHIFT              24
#define DPLL_P1_FORCE_DIV2		(1 << 21)
#define DPLL_P1_MASK			0x1f
#define DPLL_P1_SHIFT			16
#define DPLL_REFERENCE_SELECT_MASK	(0x3 << 13)
#define DPLL_REFERENCE_DEFAULT		(0x0 << 13)
#define DPLL_REFERENCE_TVCLK		(0x2 << 13)
#define DPLL_RATE_SELECT_MASK		(1 << 8)
#define DPLL_RATE_SELECT_FP0		(0 << 8)
#define DPLL_RATE_SELECT_FP1		(1 << 8)

#define FPA0			0x06040
#define FPA1			0x06044
#define FPB0			0x06048
#define FPB1			0x0604c
#define FP_DIVISOR_MASK			0x3f
#define FP_N_DIVISOR_SHIFT		16
#define FP_M1_DIVISOR_SHIFT		8
#define FP_M2_DIVISOR_SHIFT		0

/* PLL parameters (these are for 852GM/855GM/865G, check earlier chips). */
/* Clock values are in units of kHz */
#define PLL_REFCLK		48000
#define MIN_CLOCK		25000
#define MAX_CLOCK		350000

/* Two pipes */
#define PIPE_A			0
#define PIPE_B			1
#define PIPE_MASK		1

/* palette registers */
#define PALETTE_A		0x0a000
#define PALETTE_B		0x0a800
#ifndef PALETTE_8_ENTRIES
#define PALETTE_8_ENTRIES		256
#endif
#define PALETTE_8_SIZE			(PALETTE_8_ENTRIES * 4)
#define PALETTE_10_ENTRIES		128
#define PALETTE_10_SIZE			(PALETTE_10_ENTRIES * 8)
#define PALETTE_8_MASK			0xff
#define PALETTE_8_RED_SHIFT		16
#define PALETTE_8_GREEN_SHIFT		8
#define PALETTE_8_BLUE_SHIFT		0

/* CRTC registers */
#define HTOTAL_A		0x60000
#define HBLANK_A		0x60004
#define HSYNC_A			0x60008
#define VTOTAL_A		0x6000c
#define VBLANK_A		0x60010
#define VSYNC_A			0x60014
#define SRC_SIZE_A		0x6001c
#define BCLRPAT_A		0x60020

#define HTOTAL_B		0x61000
#define HBLANK_B		0x61004
#define HSYNC_B			0x61008
#define VTOTAL_B		0x6100c
#define VBLANK_B		0x61010
#define VSYNC_B			0x61014
#define SRC_SIZE_B		0x6101c
#define BCLRPAT_B		0x61020

#define HTOTAL_MASK			0xfff
#define HTOTAL_SHIFT			16
#define HACTIVE_MASK			0x7ff
#define HACTIVE_SHIFT			0
#define HBLANKEND_MASK			0xfff
#define HBLANKEND_SHIFT			16
#define HBLANKSTART_MASK		0xfff
#define HBLANKSTART_SHIFT		0
#define HSYNCEND_MASK			0xfff
#define HSYNCEND_SHIFT			16
#define HSYNCSTART_MASK			0xfff
#define HSYNCSTART_SHIFT		0
#define VTOTAL_MASK			0xfff
#define VTOTAL_SHIFT			16
#define VACTIVE_MASK			0x7ff
#define VACTIVE_SHIFT			0
#define VBLANKEND_MASK			0xfff
#define VBLANKEND_SHIFT			16
#define VBLANKSTART_MASK		0xfff
#define VBLANKSTART_SHIFT		0
#define VSYNCEND_MASK			0xfff
#define VSYNCEND_SHIFT			16
#define VSYNCSTART_MASK			0xfff
#define VSYNCSTART_SHIFT		0
#define SRC_SIZE_HORIZ_MASK		0x7ff
#define SRC_SIZE_HORIZ_SHIFT		16
#define SRC_SIZE_VERT_MASK		0x7ff
#define SRC_SIZE_VERT_SHIFT		0

#define ADPA			0x61100
#define ADPA_DAC_ENABLE			(1 << 31)
#define ADPA_DAC_DISABLE		0
#define ADPA_PIPE_SELECT_SHIFT		30
#define ADPA_USE_VGA_HVPOLARITY		(1 << 15)
#define ADPA_SETS_HVPOLARITY		0
#define ADPA_DPMS_CONTROL_MASK		(0x3 << 10)
#define ADPA_DPMS_D0			(0x0 << 10)
#define ADPA_DPMS_D2			(0x1 << 10)
#define ADPA_DPMS_D1			(0x2 << 10)
#define ADPA_DPMS_D3			(0x3 << 10)
#define ADPA_VSYNC_ACTIVE_SHIFT		4
#define ADPA_HSYNC_ACTIVE_SHIFT		3
#define ADPA_SYNC_ACTIVE_MASK		1
#define ADPA_SYNC_ACTIVE_HIGH		1
#define ADPA_SYNC_ACTIVE_LOW		0

#define DVOA			0x61120
#define DVOB			0x61140
#define DVOC			0x61160
#define LVDS			0x61180
#define PORT_ENABLE		        (1 << 31)
#define PORT_PIPE_SELECT_SHIFT	        30
#define PORT_TV_FLAGS_MASK              0xFF
#define PORT_TV_FLAGS                   0xC4  // ripped from my BIOS
                                              // to understand and correct

#define DVOA_SRCDIM		0x61124
#define DVOB_SRCDIM		0x61144
#define DVOC_SRCDIM		0x61164

#define PIPEACONF		0x70008
#define PIPEBCONF		0x71008             Normally 8000.0000 - set to 0 blanks panel
#define PIPECONF_ENABLE			(1 << 31)
#define PIPECONF_DISABLE		0
#define PIPECONF_DOUBLE_WIDE		(1 << 30)
#define PIPECONF_SINGLE_WIDE		0
#define PIPECONF_LOCKED			(1 << 25)
#define PIPECONF_UNLOCKED		0
#define PIPECONF_GAMMA			(1 << 24)
#define PIPECONF_PALETTE		0

#define DISPARB			0x70030
#define DISPARB_AEND_MASK		0x1ff
#define DISPARB_AEND_SHIFT		0
#define DISPARB_BEND_MASK		0x3ff
#define DISPARB_BEND_SHIFT		9

/* Desktop HW cursor */
#define CURSOR_CONTROL		0x70080
#define CURSOR_ENABLE			(1 << 31)
#define CURSOR_GAMMA_ENABLE		(1 << 30)
#define CURSOR_STRIDE_MASK		(0x3 << 28)
#define CURSOR_STRIDE_256		(0x0 << 28)
#define CURSOR_STRIDE_512		(0x1 << 28)
#define CURSOR_STRIDE_1K		(0x2 << 28)
#define CURSOR_STRIDE_2K		(0x3 << 28)
#define CURSOR_FORMAT_MASK		(0x7 << 24)
#define CURSOR_FORMAT_2C		(0x0 << 24)
#define CURSOR_FORMAT_3C		(0x1 << 24)
#define CURSOR_FORMAT_4C		(0x2 << 24)
#define CURSOR_FORMAT_ARGB		(0x4 << 24)
#define CURSOR_FORMAT_XRGB		(0x5 << 24)

/* Mobile HW cursor (and i810) */
#define CURSOR_A_CONTROL	CURSOR_CONTROL
#define CURSOR_B_CONTROL	0x700c0
#define CURSOR_MODE_MASK		0x27
#define CURSOR_MODE_DISABLE		0
#define CURSOR_MODE_64_3C		0x04
#define CURSOR_MODE_64_4C_AX		0x05
#define CURSOR_MODE_64_4C		0x06
#define CURSOR_MODE_64_32B_AX		0x07
#define CURSOR_MODE_64_ARGB_AX		0x27
#define CURSOR_PIPE_SELECT_SHIFT	28
#define CURSOR_MOBILE_GAMMA_ENABLE	(1 << 26)
#define CURSOR_MEM_TYPE_LOCAL		(1 << 25)

/* All platforms (desktop has no pipe B) */
#define CURSOR_A_BASEADDR	0x70084
#define CURSOR_B_BASEADDR	0x700c4
#define CURSOR_BASE_MASK		0xffffff00

#define CURSOR_A_POSITION	0x70088
#define CURSOR_B_POSITION	0x700c8
#define CURSOR_POS_SIGN			(1 << 15)
#define CURSOR_POS_MASK			0x7ff
#define CURSOR_X_SHIFT			0
#define CURSOR_Y_SHIFT			16

#define CURSOR_A_PALETTE0	0x70090
#define CURSOR_A_PALETTE1	0x70094
#define CURSOR_A_PALETTE2	0x70098
#define CURSOR_A_PALETTE3	0x7009c
#define CURSOR_B_PALETTE0	0x700d0
#define CURSOR_B_PALETTE1	0x700d4
#define CURSOR_B_PALETTE2	0x700d8
#define CURSOR_B_PALETTE3	0x700dc
#define CURSOR_COLOR_MASK			0xff
#define CURSOR_RED_SHIFT			16
#define CURSOR_GREEN_SHIFT			8
#define CURSOR_BLUE_SHIFT			0
#define CURSOR_PALETTE_MASK			0xffffff

/* Desktop only */
#define CURSOR_SIZE		0x700a0
#define CURSOR_SIZE_MASK		0x3ff
#define CURSOR_SIZE_H_SHIFT		0
#define CURSOR_SIZE_V_SHIFT		12

#define DSPACNTR		0x70180
#define DSPBCNTR		0x71180
#define DISPPLANE_PLANE_ENABLE		(1 << 31)
#define DISPPLANE_PLANE_DISABLE		0
#define DISPPLANE_GAMMA_ENABLE		(1<<30)
#define DISPPLANE_GAMMA_DISABLE		0
#define DISPPLANE_PIXFORMAT_MASK	(0xf<<26)
#define DISPPLANE_8BPP			(0x2<<26)
#define DISPPLANE_15_16BPP		(0x4<<26)
#define DISPPLANE_16BPP			(0x5<<26)
#define DISPPLANE_32BPP_NO_ALPHA 	(0x6<<26)
#define DISPPLANE_32BPP			(0x7<<26)
#define DISPPLANE_STEREO_ENABLE		(1<<25)
#define DISPPLANE_STEREO_DISABLE	0
#define DISPPLANE_SEL_PIPE_SHIFT	24
#define DISPPLANE_SRC_KEY_ENABLE	(1<<22)
#define DISPPLANE_SRC_KEY_DISABLE	0
#define DISPPLANE_LINE_DOUBLE		(1<<20)
#define DISPPLANE_NO_LINE_DOUBLE	0
#define DISPPLANE_STEREO_POLARITY_FIRST	0
#define DISPPLANE_STEREO_POLARITY_SECOND (1<<18)
/* plane B only */
#define DISPPLANE_ALPHA_TRANS_ENABLE	(1<<15)
#define DISPPLANE_ALPHA_TRANS_DISABLE	0
#define DISPPLANE_SPRITE_ABOVE_DISPLAYA	0
#define DISPPLANE_SPRITE_ABOVE_OVERLAY	1

#define DSPABASE		0x70184
#define DSPASTRIDE		0x70188

#define DSPBBASE		0x71184
#define DSPBSTRIDE		0x71188

#define VGACNTRL		0x71400
#define VGA_DISABLE			(1 << 31) This bit has to be 0 for VGA to be enabled
#define VGA_ENABLE			0
#define VGA_PIPE_SELECT_SHIFT		29        This bit has to be 1 for VGA to be on
#define VGA_PALETTE_READ_SELECT		23
#define VGA_PALETTE_A_WRITE_DISABLE	(1 << 22)
#define VGA_PALETTE_B_WRITE_DISABLE	(1 << 21)
#define VGA_LEGACY_PALETTE		(1 << 20)
#define VGA_6BIT_DAC			0
#define VGA_8BIT_DAC			(1 << 20)

#define ADD_ID			0x71408
#define ADD_ID_MASK			0xff

/* BIOS scratch area registers (830M and 845G). */
#define SWF0			0x71410
#define SWF1			0x71414
#define SWF2			0x71418
#define SWF3			0x7141c
#define SWF4			0x71420
#define SWF5			0x71424
#define SWF6			0x71428

/* BIOS scratch area registers (852GM, 855GM, 865G). */
#define SWF00			0x70410
#define SWF01			0x70414
#define SWF02			0x70418
#define SWF03			0x7041c
#define SWF04			0x70420
#define SWF05			0x70424
#define SWF06			0x70428

#define SWF10			SWF0
#define SWF11			SWF1
#define SWF12			SWF2
#define SWF13			SWF3
#define SWF14			SWF4
#define SWF15			SWF5
#define SWF16			SWF6

#define SWF30			0x72414
#define SWF31			0x72418
#define SWF32			0x7241c

/* Memory Commands */
#define MI_NOOP			(0x00 << 23)
#define MI_NOOP_WRITE_ID		(1 << 22)
#define MI_NOOP_ID_MASK			((1 << 22) - 1)

#define MI_FLUSH		(0x04 << 23)
#define MI_WRITE_DIRTY_STATE		(1 << 4)
#define MI_END_SCENE			(1 << 3)
#define MI_INHIBIT_RENDER_CACHE_FLUSH	(1 << 2)
#define MI_INVALIDATE_MAP_CACHE		(1 << 0)

#define MI_STORE_DWORD_IMM	((0x20 << 23) | 1)

/* 2D Commands */
#define COLOR_BLT_CMD		((2 << 29) | (0x40 << 22) | 3)
#define XY_COLOR_BLT_CMD	((2 << 29) | (0x50 << 22) | 4)
#define XY_SETUP_CLIP_BLT_CMD	((2 << 29) | (0x03 << 22) | 1)
#define XY_SRC_COPY_BLT_CMD	((2 << 29) | (0x53 << 22) | 6)
#define SRC_COPY_BLT_CMD	((2 << 29) | (0x43 << 22) | 4)
#define XY_MONO_PAT_BLT_CMD	((2 << 29) | (0x52 << 22) | 7)
#define XY_MONO_SRC_BLT_CMD	((2 << 29) | (0x54 << 22) | 6)
#define XY_MONO_SRC_IMM_BLT_CMD	((2 << 29) | (0x71 << 22) | 5)
#define TXT_IMM_BLT_CMD	        ((2 << 29) | (0x30 << 22) | 2)
#define SETUP_BLT_CMD	        ((2 << 29) | (0x00 << 22) | 6)

#define DW_LENGTH_MASK			0xff

#define WRITE_ALPHA			(1 << 21)
#define WRITE_RGB			(1 << 20)
#define VERT_SEED			(3 << 8)
#define HORIZ_SEED			(3 << 12)

#define COLOR_DEPTH_8			(0 << 24)
#define COLOR_DEPTH_16			(1 << 24)
#define COLOR_DEPTH_32			(3 << 24)

#define SRC_ROP_GXCOPY			0xcc
#define SRC_ROP_GXXOR			0x66

#define PAT_ROP_GXCOPY                  0xf0
#define PAT_ROP_GXXOR                   0x5a

#define PITCH_SHIFT			0
#define ROP_SHIFT			16
#define WIDTH_SHIFT			0
#define HEIGHT_SHIFT			16

/* in bytes */
#define MAX_MONO_IMM_SIZE		128


/*** Macros ***/

/* Ring buffer macros */
#define OUT_RING(n)	do {						\
	writel((n), (u32 __iomem *)(dinfo->ring.virtual + dinfo->ring_tail));\
	dinfo->ring_tail += 4;						\
	dinfo->ring_tail &= dinfo->ring_tail_mask;			\
} while (0)

#define START_RING(n)	do {						\
	if (dinfo->ring_space < (n) * 4)				\
		wait_ring(dinfo,(n) * 4);				\
	dinfo->ring_space -= (n) * 4;					\
} while (0)

#define ADVANCE_RING()	do {						\
	OUTREG(PRI_RING_TAIL, dinfo->ring_tail);                        \
} while (0)

#define DO_RING_IDLE()	do {						\
	u32 head, tail;							\
	do {								\
		head = INREG(PRI_RING_HEAD) & RING_HEAD_MASK;		\
		tail = INREG(PRI_RING_TAIL) & RING_TAIL_MASK;		\
		udelay(10);						\
	} while (head != tail);						\
} while (0)
#endif /* _INTELFBHW_H */
[then]
