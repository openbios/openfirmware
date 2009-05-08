purpose: Advanced Programmable Interrupt Controller driver
\ See license at end of file

0 0  " fee00000"  " /" begin-package

" apic" name

\ Docs:
\ "Intel Architecture Software Developer's Manual", Volume 3, chapter 7.5:
\ "Advanced Programmable Interrupt Controller (APIC)"
\  See linux/include/asm-i386/i82489.h for further details.

: apic-base-msr!  ( l -- )  0  h# 1b msr!  ;  \ High 32 bits are unused
: apic-base-msr@  ( -- l )  h# 1b msr@ drop  ;

: apic-on  ( -- )  apic-base-msr@  h# fff and  h# 800 or  apic-mmio-base or  apic-base-msr!  ;
: apic-off  ( -- )  apic-base-msr@  h# 800 invert and  apic-base-msr!  ;

0 value apic-base  \ Needs to be mapped and set

: apic!  ( l reg -- )  apic-base + l!  ;
: apic@  ( reg -- l )  apic-base + l@  ;
: apic-set  ( mask reg -- )  dup apic@ rot or  swap apic!  ;
: apic-clr  ( mask reg -- )  dup apic@ rot invert and  swap apic!  ;

\ Support

code cpu-capabilities  ( -- n )
   1 # ax mov
   cpuid
   dx push
c;
: apic-present?  ( -- flag )  cpu-capabilities h# 200 and  0<>  ;
: soft-on  ( -- )
   h# f0 apic@
   h# 100 or          \ APIC on
   h# 200 invert and  \ Focus processor checking
   h#  ff or          \ Spurious IRQ vector ff
   h# f0 apic!
;

\ Methods

: id!  ( id -- )  d# 24 lshift  d# 20 apic!  ;
: id@  ( -- id )  d# 20 apic@  d# 24 rshift  ;
: lvt0-disable-irq  ( -- )  h# 10000 h# 350 apic-set  ;  \ Disable LINT0
: lvt0-enable-irq   ( -- )  h# 10000 h# 350 apic-clr  ;  \ Enable LINT0
: lvt1-disable-irq  ( -- )  h# 10000 h# 360 apic-set  ;  \ Disable LINT1
: lvt1-enable-irq   ( -- )  h# 10000 h# 360 apic-clr  ;  \ Enable LINT1
: timer!  ( l -- )  h# 380 apic@ drop  h# 380 apic!  ;
: timer@  ( -- l )  h# 390 apic@  ;
: timer-disable-irq  ( -- )  h# 10000 h# 320 apic-set  ;  \ Dis IRQ when timer passes 0
: timer-enable-irq   ( -- )  h# 10000 h# 320 apic-clr  ;  \ Dis IRQ when timer passes 0
: timer-periodic  ( -- )  h# 30000  h# 320 apic-set  ;
: timer-one-shot  ( -- )  h# 320 apic@  h# 20000 invert and h# 10000 or  h# 320 apic!  ;
: timer-irq!  ( vector -- )  h# 320 apic@ h# ff invert and  or  h# 10000 or  h# 320 apic!  ;
: perf-disable-irq  ( -- )  h# 10000 h# 340 apic-set  ;  \ Dis IRQ when perf timer passes 0
: perf-enable-irq   ( -- )  h# 10000 h# 340 apic-clr  ;  \ Dis IRQ when perf timer passes 0
: perf-irq!  ( vector -- )  h# 340 apic@ h# ff invert and  or  h# 10000 or  h# 340 apic!  ;

: ack-irq  ( -- )  h# f0 apic@ drop  0 h# b0 apic!  ;  \ b0 is eoi

: open  ( -- okay? )
   apic-base  0=  if
      apic-mmio-base h# 400 " map-in" $call-parent to apic-base
      apic-on
   then
   true
;
: close  ( -- )  ;

end-package

0 0  " fec00000"  " /" begin-package

" io-apic" name

0 value io-apic-base
: io-apic@  ( index -- l )  io-apic-base c!  io-apic-base h# 10 + l@  ;
: io-apic!  ( l index -- )  io-apic-base c!  io-apic-base h# 10 + l!  ;

\ Debugging

: .apic-mode  ( low -- )
   8 rshift 7 and  case
      0 of  ." Fixed  "  endof
      1 of  ." LowPri "  endof
      2 of  ." SMI    "  endof
      3 of  ." Res3   "  endof
      4 of  ." NMI    "  endof
      5 of  ." Init   "  endof
      6 of  ." Res6   "  endof
      7 of  ." Ext    "  endof
   endcase
;

: .apic-irq  ( int# -- )
   2* h# 10 + dup io-apic@
   ." Vec: "  dup h# ff and 2 u.r space
   dup .apic-mode
   dup h#  800 and  if  ." Logical  "  else  ." Physical "  then
   dup h# 1000 and  if  ." Pending "  else  ." Idle    "  then
   dup h# 2000 and  if  ." Low  "  else  ." High "  then
   dup h# 8000 and  if
      ." Level "  dup h# 4000 and  if  ." IRR "  else  ." EOI "  then
   else  ." Edge      "  then
   h# 10000 and  if  ." Masked "  else  ." Open   "  then
   1+ io-apic@
   ." EDID: " dup d# 16 rshift h# ff and  2 u.r
   ."  Dest: " d# 24 rshift h# ff and 2 u.r
   cr
;
: .apic-irqs  ( -- )
   push-hex
   1 io-apic@ d# 16 rshift h# ff and 1+  0  do
      i 2 u.r space  i .apic-irq
   loop
   pop-base
;

\ Methods

: trigger-irq  ( irq# -- )  io-apic-base h# 20 + c!  ;
: eoi  ( vector -- )  io-apic-base h# 40 + c!  ;

: open  ( -- okay? )
   io-apic-base  0=  if
      io-apic-mmio-base h# 80 " map-in" $call-parent to io-apic-base
   then
   true
;
: close  ( -- )  ;

end-package

0 value apic-ih
0 value io-apic-ih
stand-init: APIC
   " /apic" open-dev to apic-ih
   " /io-apic" open-dev to io-apic-ih   
;

0 [if]
\ For tdcr (3e0):
\ Divisor:  1 2 4 8 16 32 64 128
\ Value  :  b 0 1 2  3  8  9   a 

\ Timer base low bit at bit 18
\ Timer base div is mask 2

\ Other regs:
\ LVR                    0x30  
\   GET_APIC_VERSION(x)         ((x)&0xFF)

\ TPR 80  Task Priority, 000000xx only service interrupts higher than this value
\ APR 90  Arbitration Priority, used during bus arbitration
\ PPR a0  Processor Priority, depends complexly on TPR and incoming interrupt

\ LDR                    0xD0  Logical Destination Register  II000000  II is logical APIC ID
\ DFR                    0xE0  Destination Format Register   M0000000  M is the model (F:flat or 0:cluster)
\ LVTERR                 0x370
\ TDCR                   0x3E0
\ ICR                    0x310 Generate local interrupt by writing

\ IRR  200 - 270 (8 registers - 256 bits) Request - bit is set if interrupt pending
\ ISR  100 - 170 (8 registers - 256 bits) Service - INTA latches highest priority bit
\ TMR  180 - 1F0 (8 registers - 256 bits) Bit is set for level, clear for edge.  EOI commands sends EOI msg to all IOAPIC

20 0
30 50014
80 f0
d0 0
e0 ffffffff
f0 10f
320 10000 Timer Masked off
340 10000 PCINT Masked off
350 700  LINT0 vector 0  mode ExtINT (111)  Edge Trigger  Active High
360 400  LINT1 vector 0  mode NMI (100)  Edge Trigger   Active High
370 10000 ERROR Masked off
380 0
390 0

Io apic
259  9 (def 08)  bit 0=1 enabe MSI Flat Mode Support

25c 10  APIC D11 is masked to 1, cluster mode disabled
268-26f 0 .. 0  Priority of all CPUs = 0
296 a  - bit 0 = 0  Assert HDPWR# for both read / write cycles (other bits are enable V4 fast TRDY, dynamic HDPWR#)
297 1  - bit 1 = 0  Don't pipeline APIC requests, bit 0 = 1 enable redirect low priority apic reqs to CPU 0
386 3f - bit 5 ena apic low interrupt arb, bit 4 io apic fec80000 - fecf.ffff to PCI2, bit 3 host snoop, 2 enable top sm mem, 1 enable sdio support for using system memory 4kbytes, 1 enable compatible smm
485 5 - bit 1 = 0 free-running apic clock (not dynamic) [Reserved in 855]
488 0 - bits 1 and 0 free running apic clocks [Reserved in 855]
4a2 d6 - bit 3 = 0  disable apic interface power management  [Reserved in 855]

-- Following registers in D0F5 are [Reserved in 855]
540 4c (default) - bit 7 disable legacy apic, c is irrelevant if disabled
541 0 (def) - irrelevant if 540 disabled
542 3 (def) - bit 3 disable intx transparent mode, bit 2 dis apic nonshare mode, bit 1 ena APIC interrupt disable, bit 0 enabe boot interrupt function
544 0 (def) - bit 7 boring, bit 1 dis pcie dev uses msi cycle wake up system from c3, bit 0 apic data voltage 2.5v
-- End reserved


io apic regs: fec0.0000
00  index register for indirect regs
10  data  register for indirect regs
20 write the IRQ #
40 EOI WO

indirect io apic regs
00 1000000 IOAPIC ID is 1
01 178003  (RO)  version
02 1000000 Arb ID is 1
03 1  Front side bus message delivery
10,11  0100.0000  . 0001.0000  DD00  . 0000 . 000 ooom . tips MVV
..
3e,3f  0100.0000  . 0001.0000
   DD is destination APIC ID in physical mode (since bit 11 = 0)
   m = 1 means masked
   

8848 0  bit 7 = 0 address bit 2 of FSBis not force low (default)
884d 1  bit 3=0  disable some funny thing about APCI Ch0 ext interrupt delivery (def), bit 2=0 dis ser irq always shared in APIC mode (def)

PnP routing
8854 00 non-inverted PCI INT#
8855 a0 INTA IRQ10
8856 b9 INTC IRQ11, INTB IRQ9
8857 a0 INTD IRQ10

APIC Mode  INTA-H
PIRQ16     A
PIRQ17     B
PIRQ18     C
PIRQ19     D
PIRQ20     E
PIRQ21     F
PIRQ22     G
PIRQ23     H

8858 60 (def 40) bit 6 ena Internal APIC
885b 53 (def 01) bit 6 port 80 to LPC, bit 4 ena APIC clock gating, bit 3=0 dis bypass apic de-assert Msg, bit 1 res, bit 0 ena dynamic clock stop
886c 00 (def)    bit 3 dis apic positive decode
88b0 30 (def 08) bits 5,4 ena uart 2,1, bit 3=0 disable apic C4P State Mode Control
88e7 80 (def 00) bit 7 enable apic cycle reflect to all bus master activity effective signal
88ec 00 (def 00) bits 7:4=0 disable V1 interrupt routing

PMIO+65  bit 7 set to 1 to enable APIC interrupt wake up system from C4P state

8f73 01 (def 00) bit4=0 enable APIC cycle block p2c write cycle (def), bit 0=1 enable pci broken master timer
8f74 0c (def 00) bit3=1 lock cycle issued by cpu block p2c cycles, bit2=1 APIC FSB directly up through CCA (not PCI) and 7c[1] must also be set [Bit 2 is reserved in 855]
8f7c 02 (def 02) bit2=1 APIC FSB directly up through CCA (not PCI) and 74[2] must also be set

8f80 07 (def 00) bit0=1 APIC cycle blocks HDAC upstream write

8fe0 93 (def 40) various.  bit 3=0 dis APIC cycle flush HDAC Upstream Write Cycle [Reserved in 855]
8fe6 3f (def 01) bit5 supposedly reserved, bit4=1 split fecxx.xxxx range btw PCI1 and PCI2, bit3=1 processor MSI support enable, bit2=1 Top SMM enable, bit1=1 High SMM enable, bit0=1 Compatible SMM enable



When enable internal APIC, PCI devices and internal function IRQ routing are:

IRQ16 HPET IRQ   
IRQ17 HPET IRQ
IRQ18 HPET IRQ
IRQ19 HPET IRQ
IRQ20 UHCI Port 0-1 IRQ and Card Boot IRQ
IRQ21 EIDE IRQ and UHCI Port 4-5 IRQ
IRQ22 UHCI Port 2-3 and SDIO
IRQ23 Card Reader, EHCI Port 0-5

HPET IRQs

Mode     Timer0         Timer1            Timer2
--------------------------------------------
Legacy  0(PIC)/2(APIC)  8(PIC)/8(APIC)    -
NonLeg  16-19 APIC      16-19 APIC        11,16-19 APIC


 83c 0a  display IRQ 10
603c 0a  SDIO IRQ 10
683c 09  card controller IRQ 9
803c 0a  UHCI 01 IRQ 10  INTA
813c 09  UHCI 23 IRQ 9   INTB
823c 0b  UHCI 45 IRQ 11  INTC
843c 0a  EHCI IRQ 10     INTD
a03c 09  HDAC IRQ 9

[then]
