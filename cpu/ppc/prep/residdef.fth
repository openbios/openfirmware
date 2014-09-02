purpose: Definitions of residual data structures and field values
\ See license at end of file

[ifdef] create-resid-field-names
alias res-field field
: rfield  ( offset size "name" -- offset' )
   create  over , +  does>  @ residual-data +
;
[else]
: res-field  ( offset size "name" -- offset' )  safe-parse-word 2drop  +  ;
alias rfield res-field  ( offset size "name" -- offset' )
[then]

d#  32 constant res#cpus	\ Number of CPU slots in residual data
d#  64 constant max#mems
d# 256 constant max#devices
d#  32 constant /pnp-avg
d#  64 constant max#mem-segs

: bfield  ( offset "name" -- offset' )  /c res-field  ;
: wfield  ( offset "name" -- offset' )  /w res-field  ;
: lfield  ( offset "name" -- offset' )  /l res-field  ;

struct ( cpu )
   lfield >cpu-type	\ PVR@
   bfield >cpu#		\ The interrupt cookie for MP interrupts - 0 for UP
   bfield >cpu-state	\ 0:good  1:running FW  2:inactive  3: failed
   2 +  \ reserved
constant /cpu

struct ( mem-seg )
   lfield >usage
	\ 1: FW stack  2: FW heap  4: FW code  8: Boot image  10: free mem
	\ 20: Unpopulated mem  40: ISA  80: PCI config  100: PCI
	\ 200: system regs  400: system I/O  800: I/O memory
	\ 1000: unpopulated ROM  2000: ROM  4000: resume block  8000: other
   lfield >base-page
   lfield >page-count
constant /mem-seg

struct ( mem )
   lfield >simm-size	\ size in Mbytes.  0 means absent or bad
constant /mem

struct ( device )
   lfield >bus-id	\ 1: ISA  2: EISA  4: PCI  8: PCMCIA  10: PNPISA
			\ 20: MCA  40: MX  80: Processor bus  100: VME
   lfield >dev-id	\ bus-specific encoding
   lfield >serial#	\ logical unit number
   lfield >flags	\ 1: output  2: input  4: console out  8: console in
			\ 10: removable  20: R/O  40: power managed
			\ 80: disableable  100: configurable  200: bootable
			\ 400: on docking station  800: not configurable
			\ 1000: failed  2000: on motherboard  4000: enabled
   bfield >base-type
   bfield >sub-type
   bfield >interface
			\ 1:0 SCSI  1:1 IDE  1:1:1 ATA IDE
			\ 1:2 floppy 1:2:1 765  1:2:2 Super I/O floppy at 398
			\ 1:2:3 .. at 026e  1:2:4 .. at 15c  1:2:5 .. at 02e
			\ 1:3 IPI  1:80 other mass storage
			\ 2:0 Ethernet  2:1 Token Ring  2:2 FDDI 2:80 other net
			\ 3:0 VGA  3:1 SVGA  3:2 XGA  3:80 other display
			\ 4:0 video  4:1 audio  4:1:1 CS4232 audio
			\ 4:80 other multimedia
			\ 5:0 RAM  5:0:0 PCI mem ctlr  5:0:1 RS6K mem ctlr
			\ 5:1 FLASH  5:80 other memory
			\ 6:0 host bridge  6:1 ISA bridge  6:2 EISA bridge
			\ 6:3 MCA bridge  6:4:0 PCI w/ memory mapped config.
			\ 6:4:1 PCI with CF8/CFC config  6:4:2 RS6K PCI
			\ 6:5 PCMCIA bridge  6:6 VME bridge  6:80 other bridge
			\ 7:0 RS232  7:0:1 COMx  7:0:2 16450  7:0:3 16550
			\ 7:0:4 Super I/O serial @ 398  7:0:5 .. @ 26e
			\ 7:0:6 .. @ 15c  7:0:5 .. @ 02e
			\ 7:1 parallel  7:1:1 LPTx
			\ 7:1:2 Super I/O parallel @ 398  7:1:3 .. at 26e
			\ 7:1:4 .. at 15c  7:1:5 .. at 02e
			\ 7:80 other communications device
			\ 8:0 interrupt controller  8:0:1 ISA 8259
			\ 8:0:2 EISA PIC  8:0:3 MPIC  8:0:4 RS6K PIC
			\ 8:1 DMA  8:1:1 ISA DMA  8:1:2 EISA DMA
			\ 8:2 timer  8:2:1 ISA timer  8:2:2 EISA timer
			\ 8:3 RTC  8:3:1 ISA RTC
			\ 8:4 L2 cache  8:4:1 write-through-only L2 cache
			\ 8:4:2 copyback-enabled L2 cache  8:4:3 RS6K L2 cache
			\ 8:5:0 NVRAM at ports 74-76  8:5:1 direct mapped NVRAM
			\ 8:5:2 24-bit indirect NVRAM at ports 73-76
			\ 8:6 power management  8:6:1 emerg. power-off warning
			\ 8:6:2 software power on/off
			\ 8:7 CMOS RAM
			\ 8:8 operator panel  8:8:1 hard disk light
			\ 8:8:2 CDROM light  8:8:3 power light  8:8:4 key lock
			\ 8:8:5 alphanumeric display  8:8:6 system status LED
			\ 8:9 service processor class 1
			\ 8:a service processor class 2
			\ 8:b service processor class 3
			\ 8:c graphics assist 8:c:0 none 8:c:1 transfer data
			\ 8:c:2 IGM32  8:c:3 IGM64
			\ 8:80 other system peripheral
   bfield >spare
   lfield >bus-access	\ Processor bus:  bus#:byte  BUID:byte  reserved:short
			\ ISA bus:  slot#:byte  log dev#:byte  reserved:short
			\ PCI bus:  bus#:byte  DevFunc#:byte  reserved:short
			\ etc.  PCI DevFunc# is bits 15:8 of conf. addr. reg
   lfield >allocated-offset	\ Offset into PnP heap
   lfield >possible-offset	\ Offset into PnP heap
				\ usually points to a PnP terminator byte
   lfield >compatible-offset	\ Offset into PnP heap
				\ usually points to a PnP terminator byte
constant /device

struct ( residual-data )
   4 rfield r-length			\ constant
   1 rfield r-version			\ constant
   1 rfield r-revision			\ constant
   2 rfield r-ec			\ constant

   \ VPD section

   d# 32 rfield r-printable-model	\ from "banner-name" property in "/'
   d# 16 rfield r-serial# 		\ from NVRAM or IDPROM
   d# 48 +   \ reserved
   4 rfield r-fw-supplier		\ fixed
   4 rfield r-fw-supports		\ fixed
   4 rfield r-nvram-size		\ from "size" method in "/nvram"
   4 rfield r-#simm-slots		\ Code in probemem.fth
   2 rfield r-endian-switch-method	\ depends on bridge chip
   2 rfield r-spread-io-method		\ depends on bridge chip
   4 rfield r-smpiar			\ ??
   4 rfield r-ram-err-log-offset	\ computed after setting up PnP heap
   d# 8 +    \ reserved
   4 rfield r-processor-hz		\ "clock-frequency" prop. in CPU node
   4 rfield r-processor-bus-hz		\ "clock-frequency" prop. in "/"
   d# 4 +    \ reserved
   4 rfield r-timebase-divisor		\ CPU-dependent 1000 * bus-clocks/tick
   4 rfield r-wordwidth			\ 32 for 60x, 64 for 620
   4 rfield r-pagesize			\ constant
   4 rfield r-coherence-block-size	\ from "cache-line-size" in CPU node
   4 rfield r-granule-size		\ "
   4 rfield r-cache-size		\ sum of i$ + d$ in Kbytes - 16 for 603, 32 for 604
   4 rfield r-cache-attrib		\ 1 for split - from "cache-unified" property
   4 rfield r-cache-assoc		\ 0 for 603, 603e, 604
   4 rfield r-cache-line-size		\ 0
   4 rfield r-icache-size		\ from cpu-node prop
   4 rfield r-icache-assoc		\ 2 for 603, 4 for 603e, 604
   4 rfield r-icache-line-size		\ 32
   4 rfield r-dcache-size		\ 8 for 603, 16 for 604
   4 rfield r-dcache-assoc		\ 2 for 603, 4 for 603e, 604
   4 rfield r-dcache-line-size		\ 32
   4 rfield r-tlb-size			\ 128
   4 rfield r-tlb-attrib		\ 1 for split
   4 rfield r-tlb-assoc			\ 0
   4 rfield r-itlb-size			\ 64
   4 rfield r-itlb-assoc		\ 2
   4 rfield r-dtlb-size			\ 64
   4 rfield r-dtlb-assoc		\ 2
   4 rfield r-extended-vpd		\ NULL pointer

   \ CPU section

   2                         rfield r-max#cpus		\ system-dependent
   2                         rfield r-actual#cpus	\ # of cpu nodes
   /cpu res#cpus *           rfield r-cpus

   \ Memory section

   4                         rfield r-total-memory	\ "reg" in "memory"
   4                         rfield r-good-memory	\ "reg" in "memory"
   4                         rfield r-actual#mem-segs	\ "reg" & "avail"
   /mem-seg max#mem-segs *   rfield r-mem-segs
   4                         rfield r-actual#memories
   /mem max#mems *           rfield r-mems

   \ Device section

   4                         rfield r-actual#devices
   /device  max#devices *    rfield r-devices

dup constant pnp-heap-offset

   /pnp-avg max#devices * 2* rfield r-pnp-heap

constant /residual-data

\ : >mem      ( mem# -- adr )  /mem     * r-mems     +  ;
\ : >mem-seg  ( seg# -- adr )  /mem-seg * r-mem-segs +  ;
\ : >cpu      ( cpu# -- adr )  /cpu     * r-cpus     +  ;
\ : >devices  ( dev# -- adr )  /device  * r-devices  +  ;


\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
\
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END

