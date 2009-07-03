\ Make some ACPI descriptor tables

h# 0. 2constant xsdt-adr

: set-acpi-table-length  ( table-adr -- )
   here over -  swap la1+ l!
;

create fadt
( 000 4 )  " FACP"     $, \ Signature
( 004 4 )  h#   84     l, \ Length
( 008 1 )  h#   02     c, \ Revision (supports reset adr)
( 009 1 )  h#   00     c, \ Checksum
( 00A 6 )  " OLPC  "   $, \ Oem ID
( 010 8 )  " OLPC_000" $, \ Oem Table ID
( 018 4 )  " 0000"     $, \ Oem Revision
( 01C 4 )  " OLPC"     $, \ Asl Compiler ID
( 020 4 )  " 0000"     $, \ Asl Compiler Revision
( 024 4 )  facs-adr l,    \ FACS Address
( 028 4 )  dsdt-adr l,    \ DSDT Address
( 02C 1 )  h#   00 c,     \ Was Model, now reserved
( 02D 1 )  h#   00 c,     \ PM Profile
( 02E 2 )  h# 000a w,     \ SCI Interrupt

\ Setting all of these to 0 tells the OS that the system is always in ACPI mode
( 030 4 )  h#    0 l,     \ SMI Command Port
( 034 1 )  h#    0 c,     \ ACPI Enable Value
( 035 1 )  h#    0 c,     \ ACPI Disable Value

( 036 1 )  h#   00 c,     \ S4BIOS Command
( 037 1 )  h#   00 c,     \ P-State Control
( 038 4 )  h#  400 l,     \ PM1A Event Block Address
( 03C 4 )  h#    0 l,     \ PM1B Event Block Address
( 040 4 )  h#  404 l,     \ PM1A Control Block Address
( 044 4 )  h#    0 l,     \ PM1B Control Block Address
( 048 4 )  h#   22 l,     \ PM2 Control Block Address
( 04C 4 )  h#  408 l,     \ PM Timer Block Address
( 050 4 )  h#  420 l,     \ GPE0 Block Address
( 054 4 )  h#    0 l,     \ GPE1 Block Address
( 058 1 )  h#    4 c,     \ PM1 Event Block Length
( 059 1 )  h#    2 c,     \ PM1 Control Block Length
( 05A 1 )  h#    1 c,     \ PM2 Control Block Length
( 05B 1 )  h#    4 c,     \ PM Timer Block Length
( 05C 1 )  h#    4 c,     \ GPE0 Block Length
( 05D 1 )  h#    0 c,     \ GPE1 Block Length
( 05E 1 )  h#   10 c,     \ GPE1 Base Offset
( 05F 1 )  h#   85 c,     \ _CST Support
( 060 2 )  d#   10 w,     \ C2 Latency (guess)
( 062 2 )  d#  100 w,     \ C3 Latency (guess)
( 064 2 )  h#    0 w,     \ CPU Cache Size
( 066 2 )  h#    0 w,     \ Cache Flush Stride
( 068 1 )  h#    0 c,     \ Duty Cycle Offset
( 069 1 )  h#    4 c,     \ Duty Cycle Width
( 06A 1 )  h#   7d c,     \ RTC Day Alarm Index
( 06B 1 )  h#   7e c,     \ RTC Month Alarm Index
( 06C 1 )  h#   7f c,     \ RTC Century Index
( 06D 2 )  h#    0 w,     \ Boot Architecture Flags
( 06F 1 )  h#    0 c,     \ Reserved
( 070 4 )  h#  5a5 l,     \ Flags - see below for bit definitions
( 074 12 ) 1 c, 8 c, 0 c, 1 c,  h# 92. d,   \ Reset register - I/O, 8 bits, 0 offset, byte access

( 080 1 )  h#    1 c,     \ Reset value
( 081 3 )  0 c, 0 c, 0 c, \ Reserved
fadt set-acpi-table-length

\ FADT Flags:
\      WBINVD is operational : 1
\ WBINVD does not invalidate : 0
\        All CPUs support C1 : 1
\      C2 works on MP system : 0
\    Power button is generic : 0 ??
\    Sleep button is generic : 1 ??
\       RTC wakeup not fixed : 0
\ RTC wakeup/S4 not possible : 1
\            32-bit PM Timer : 1
\          Docking Supported : 0
\    Reset Register Supported: 1

create madt  \ Multiple APIC Descriptor Table
( 000 4 )  " APIC"     $, \ Signature
( 004 4 )  h#   5a     l, \ Length
( 008 1 )  h#   01     c, \ Revision
( 009 1 )  h#   00     c, \ Checksum
( 00A 6 )  " OLPC  "   $, \ Oem ID
( 010 8 )  " OLPC_000" $, \ Oem Table ID
( 018 4 )  " 0000"     $, \ Oem Revision
( 01C 4 )  " OLPC"     $, \ Asl Compiler ID
( 020 4 )  " 0000"     $, \ Asl Compiler Revision
( 024 4 )  apic-mmio-base l,  \ APIC base address
( 028 4 )  1           l, \ Flags - 1 means that an 8259 PIC is present too

( 02c 1 )  0           c, \ Processor-local APIC
( 02d 1 )  8           c, \ length
( 02e 1 )  0           c, \ processor ID
( 02f 1 )  0           c, \ ACPI ID
( 030 4 )  1           l, \ Flags - 1 means this processor is usable

( 034 1 )  1           c, \ I/O APIC
( 035 1 )  d# 12       c, \ length
( 036 1 )  1           c, \ I/O APIC ID
( 037 1 )  0           c, \ reserved
( 038 4 )  io-apic-mmio-base l, \ I/O APIC base address
( 03c 4 )  0           l, \ Global system interrupt base

( 040 1 )  4           c, \ local APIC NMI
( 041 1 )  6           c, \ length
( 042 1 )  0           c, \ processor ID
( 043 2 )  5           w, \ flags - edge-triggered, active high
( 045 1 )  1           c, \ Local APIC LINT#
        
( 046 1 )  2           c, \ Int src override (for PIT timer)
( 047 1 )  d# 10       c, \ length
( 048 1 )  0           c, \ Bus - ISA
( 049 1 )  0           c, \ Bus-relative IRQ
( 04a 4 )  2           l, \ Interrupt # that this source will trigger
( 04e 2 )  5           w, \ flags - edge-triggered, active high

( 050 1 )  2           c, \ Int src override
( 051 1 )  d# 10       c, \ length
( 052 1 )  0           c, \ Bus - ISA
( 053 1 )  9           c, \ Bus-relative IRQ
( 054 4 )  9           l, \ Interrupt # that this source will trigger
( 058 2 )  h# f        w, \ Flags - active low, level triggered
madt set-acpi-table-length

create hpet  \ High Precision Event Timer table
( 000 4 )  " HPET"     $, \ Signature
( 004 4 )  h#   38     l, \ Length
( 008 1 )  h#   01     c, \ Revision
( 009 1 )  h#   00     c, \ Checksum
( 00A 6 )  " OLPC  "   $, \ Oem ID
( 010 8 )  " OLPC_000" $, \ Oem Table ID
( 018 4 )  " 0000"     $, \ Oem Revision
( 01C 4 )  " OLPC"     $, \ Asl Compiler ID
( 020 4 )  " 0000"     $, \ Asl Compiler Revision

( 024 4 )  h# 11068201 l, \ Hardware ID of event timer block - 1106 is PCI VID, rest are misc, see HPET spec
( 028 1 )  0           c, \ ID
( 029 1 )  0           c, \ Bit width
( 02a 1 )  0           c, \ Bit offset
( 02b 1 )  0           c, \ Access width
( 02c 8 )  hpet-mmio-base d, \ HPET base address
( 034 1 )  0           c, \ Sequence
( 035 2 )  0           w, \ Min tick
( 037 1 )  0           c, \ flags
hpet set-acpi-table-length

create rsdt
( 00 4 )  " RSDT"     $,  \ Signature
( 04 4 )  h#   34     l,  \ Length
( 08 1 )        1     c,  \ Revision
( 09 1 )       00     c,  \ Checksum
( 0a 6 )  " OLPC  "   $,  \ Oem Id
( 10 8 )  " OLPC_000" $,  \ Oem Table Id
( 18 4 )  " 0000"     $,  \ Oem revision
( 1c 4 )  " OLPC"     $,  \ Creator ID
( 20 4 )  " 0000"     $,  \ Creator revision
( 24 4 )  fadt-adr    l,  \ FADT Address
( 28 4 )  dsdt-adr    l,  \ DSDT Address
( 2c 4 )  madt-adr    l,  \ MADT Address
( 30 4 )  hpet-adr    l,  \ HPET Address
\ ( 2c 4 )  dbgp-adr    l,  \ DBGP Address
\ ( 30 4 )  ssdt-adr    l,  \ SSDT Address
\ ( 30 4 )  prtn-adr    l,  \ PRTN Address
rsdt set-acpi-table-length

0 [if]
create dbgp
( 00 4 )  " DBGP"     $,  \ Signature
( 04 4 )  d#   52     l,  \ Length
( 08 1 )        1     c,  \ Revision
( 09 1 )       00     c,  \ Checksum
( 0a 6 )  " OLPC  "   $,  \ Oem Id
( 10 8 )  " OLPC_000" $,  \ Oem Table Id
( 18 4 )  " 0000"     $,  \ Oem revision
( 1c 4 )  " OLPC"     $,  \ Creator ID
( 20 4 )  " 0000"     $,  \ Creator revision
( 24 1 )       0      c,  \ Full 16550 interface
( 25 3 )  0 c, 0 c, 0 c,  \ reserved
( 28 c )  1 c, 8 c, 0 c, 1 c,  h# 3f8 l, 0 l,   \ Port base address (generic register descriptor)
dbgp set-acpi-table-length
[then]

create facs
( 00 4 )  " FACS"     $,  \ Signature
( 04 4 )  h#   40     l,  \ Length
( 08 4 )  h# 1234     l,  \ Hardware signature
( 0c 4 )        0     l,  \ Waking vector
( 10 4 )        0     l,  \ Global lock
( 14 4 )        0     l,  \ Flags
( 18 8 )        0.    d,  \ 64-bit waking vector
( 20 1 )        1     c,  \ Version
( 21 1f )  here  d# 31 dup allot  erase
facs set-acpi-table-length

create rsdp
( 00 8 )  " RSD PTR " $,  \ Signature
( 08 1 )       00     c,  \ Checksum
( 09 6 )  " OLPC  "   $,  \ Oem Id
( 0f 1 )        2     c,  \ ACPI revision (3.0b)
( 10 4 )  rsdt-adr    l,  \ RSDT Address

( 14 4 )    d# 36     l,  \ Length for extended version
( 18 8 )  xsdt-adr    d,  \ XSDT Address
( 20 1 )        0     c,  \ extended checksum
( 21 3 )  0 c, 0 c, 0 c,  \ reserved
here rsdp - constant /rsdp

: fix-checksum  ( table /table checksum-offset -- )
   >r over >r      ( table /table r: cksum-offset table )
   0 -rot   bounds  ?do  i c@ +  loop   ( sum )
   negate h# ff and  r> r> + c!
;

: memory-limit  ( -- limit )
   " /memory" find-package 0= abort" No /memory node"  ( phandle )
   " available" rot get-package-property abort" No available property"  ( $ )
   -1 >r                              ( $ )  ( r: limit )
   begin  dup 0>  while               ( $ )
      decode-int >r decode-int  r> +  ( $ piece-end )
      dup 1meg u<=  if  drop   else   ( $ piece-end )
         r> umin >r                   ( $ )  ( r: limit' )
      then                            ( $ )
   repeat                             ( $ )
   2drop  r>                          ( limit )
   h# 1000 -   \ Safety page
;

: >acpi-table-len  ( adr -- len )  la1+ l@  ;
: copy-acpi-table  ( src dst -- )
   tuck  over >acpi-table-len   move  ( dst )
   dup >acpi-table-len  9  fix-checksum
;

h# 18 constant ds32     \ Must agree with GDT in rmstart.fth
h# 20 constant cs16     \ Must agree with GDT in rmstart.fth
h# 28 constant ds16     \ Must agree with GDT in rmstart.fth

label do-acpi-wake
   \ This code must be copied to low memory
   \ Jump to this code (in low memory) with the linear target address in EAX
   \ Interrupts must be off.  We don't have a stack.
   \ We got here via a far jmp to a 16-bit code segment, so we are
   \ using the 16-bit instruction set, but we're not yet in real mode

   16-bit

   ahead
      0 w, 0 w,   \ Room for the segment:offset pointer
   then

   op: ax bx mov
   h# 0f # ax and  ax cx mov
   op: 4 # bx shr

   \ Set data segment for storing offset and segment below
   ax ax xor  ds16 #  al  mov  ax ds mov   \ 16-bit data segment
   cx  wake-adr wa1+ #)  mov  \ Offset
   bx  wake-adr la1+ #)  mov  \ Segment

   cr0 ax mov   h# fe # al and   ax cr0 mov   \ Enter real mode

   here 5 +  do-acpi-wake -  wake-adr  + lwsplit d# 12 lshift  #)  far jmp  \ Jump to set cs

   cs: wake-adr wa1+  lwsplit drop  s#)  far jmp
end-code
here do-acpi-wake - constant /do-acpi-wake

: setup-acpi  ( -- )
[ifdef] notdef
   \ This has to agree with the _SB's _INI method, which gets the memory size
   \ from offset h# 180 in the EBDA
   memory-limit d# 10 rshift  'ebda h# 180 + l!
[then]

   \ Copy tables to low memory
   fadt  fadt-adr  copy-acpi-table
   madt  madt-adr  copy-acpi-table
   hpet  hpet-adr  copy-acpi-table
\  dbgp  dbgp-adr  copy-acpi-table
   facs  facs-adr  facs >acpi-table-len  move
   rsdt  rsdt-adr  copy-acpi-table
   rsdp  rsdp-adr  /rsdp move  rsdp-adr h# 14 8 fix-checksum   rsdp-adr /rsdp h# 20 fix-checksum  

   \ Copy in the DSDT
   \ I suppose we could point to it in FLASH - if so don't compress it,
   \ and fixup the address in the fadt and rechecksum the fadt
   " dsdt" find-drop-in  0= abort" No DSDT "  ( adr len )
   2dup dsdt-adr swap  move  free-mem

   do-acpi-wake wake-adr  /do-acpi-wake  move

[ifdef] notdef
   \ Copy in the SSDT
   \ I suppose we could point to it in FLASH - if so don't compress it,
   \ and fixup the address in the fadt and rechecksum the fadt
   " ssdt" find-drop-in  0= abort" No SSDT "  ( adr len )
   2dup ssdt-adr swap  move  free-mem
[then]

   4 acpi-w@  1 or  4 acpi-w!  \ Set SCI_EN bit
   h# ffffffff  h# 20 acpi-l!  \ Ack all leftover events
;

stand-init: ACPI tables
   setup-acpi
;

\ Geode h# 6000 constant xp-smbus-base

defer more-platform-fixup  ' noop to more-platform-fixup
: rm-platform-fixup  ( -- )
[ifdef] Later
Geode   xp-smbus-base h# f001   h# 5140.000b  3dup msr!  find-msr-entry  2!
Geode   xp-smbus-base 1+  h# 10 isa-hdr  >hdr-value  l!

   begin  sci-queue@  0=  until   \ Clean out the SCI queue
   h# 20 acpi-w@  h# 20 acpi-w!   \ Ack outstanding events
Geode   h# 4e sci-mask!                \ Include in the mask only events we care about

Geode   0 h# 40 pm!                    \ Restore long delay for power-off button
[then]
   more-platform-fixup
;

0 [if]
=====
APIC @ 0x3beb6f32
  0000: 41 50 49 43 5a 00 00 00 01 3c 50 54 4c 54 44 20  APICZ....<PTLTD 
  0010: 09 20 41 50 49 43 20 20 00 00 04 06 20 4c 54 50  . APIC  .... LTP
  0020: 00 00 00 00
        00 00 e0 fe  address of local apic
        01 00 00 00  flags - 1 means that an ISA PIC is present too

        00 Processor-local APIC  08 length
        00 processor ID
        00 ACPI ID
  0030: 01 00 00 00  flags - 1 means usable

        01 I/O APIC  0c length
        01 I/O APIC ID
        00 reserved

        00 00 c0 fe  I/O APIC address MMIO Address
        00 00 00 00  Global system interrupt base

  0040: 04 local APIC NMI  06 length
        00 processor ID
        05 00 flags - edge-triggered, active high
        01 Local APIC LINT#
        
        02 Int src override  0a length
        00 Bus - ISA
        00 Bus-relative IRQ
        02 00 00 00  Interrupt # that this source will trigger
        05 00 flags - edge-triggered, active high

  0050: 02 Int src override  0a length
        00 Bus - ISA
        09 Bus-relative IRQ
        09 00 00 00  Interrupt # that this source will trigger
        0f 00 Flags - active low, level triggered

MCFG is for memory-mapped PCI config space - unnecessary for us
MCFG @ 0x3beb6f8c
  0000: 4d 43 46 47
     4  0000003c len
     8  01 rev
     9  67 csum
     a  "PTLTD " OEM ID
  0010: "  MCFG  " OEM Table ID
  0018: 00 00 04 06 OEM revision #
    1c: " LTP" Compiler ID
  0020: 00000000 compiler rev
    24: 00 00 00 00 00 00 00 00 reserved
    2c  e0000000 00000000 BaseAddress.64
    34: 0000 pci segment group #
    36: 00 start bus #
    37: 00 end bus #
    38: 00 00 00 00  res

HPET @ 0x3beb6fc8
  0000: 48 50 45 54 
     4: 00000038 length
     8: 01  rev
     9: 38 csum
     a: "PTLTD " OEM ID
  0010: "HPETTBL " OEM table ID
   00 00 04 06  OEM revision #
    1c: " LTP"  Compiler ID
  0020: 00000001 Compiler revision ID
    24: 01 82 06 11  hardware ID of event timer block
    28: 00 00 00 00  id bit_width bit_offset access_width
    2c: fed00000 00000000 address
    34: 00 0000 00 seq, min tick, flags

XSDT @ 0x3beb2a81
  0000: 58 53 44 54 4c 00 00 00 01 a2 50 54 4c 54 44 20  XSDTL.....PTLTD 
  0010: 09 20 58 53 44 54 20 20 00 00 04 06 20 4c 54 50  . XSDT  .... LTP
  0020: 00 00 00 00 
  Pointers:
84 69 eb 3b 00 00 00 00
78 6a eb 3b 00 00 00 00
32 6f eb 3b 00 00 00 00
8c 6f eb 3b 00 00 00 00
c8 6f eb 3b 00 00 00 00

FACP @ 0x3beb6910
  0000: 46 41 43 50 74 00 00 00 01 f6 56 58 38 35 35 20  FACPt.....VX855 
  0010: 50 54 4c 54 57 20 20 20 00 00 04 06 50 54 4c 5f  PTLTW   ....PTL_
  0020: 40 42 0f 00
        c0 7f eb 3b  &facs
        cd 2a eb 3b  &dsdt
        00 00  model, preferred profile
        0a 00  sci_interrupt !!!
  0030: 2f 40 00 00  sci_command port
    34  f0 acpi_enable
    35  f1 acpi_disable
    36  00 s4bios_request value
    37  80 pstate control
    38  00 40 00 00  pm1a event block
    3c  00 00 00 00  pm1b event block
  0040: 04 40 00 00  pm1a control block
        00 00 00 00  pm1b control block
        22 00 00 00  pm2 control block
        08 40 00 00  pm_timer block
  0050: 20 40 00 00  gpe0_block
        00 00 00 00  gpe1_block
        04  pm1 event block len
        02  pm1 control block len
        01  pm2 control block len
        04  pm timer block length
        04  gpe0 block len
        00  gpe1 block len
        10  gpe1 base offset
        85  _cst latency
  0060: 01 00 C2_latency
        01 00 C3_latency
        00 00 CPU cache size
        00 00 cache flus stride
        00 duty cycle offset
        04 duty cycle width
        7d rtc day alarm indes
        7e rtc month alarm index
        32 rtc century index
        00 00 boot architecture flags
        00 reserved
  0070: a5 00 00 00 flags
   
RSDT @ 0x3beb2a49
  0000: 52 53 44 54 38 00 00 00 01 1f 50 54 4c 54 44 20  RSDT8.....PTLTD 
  0010: 20 20 52 53 44 54 20 20 00 00 04 06 20 4c 54 50    RSDT  .... LTP
  0020: 00 00 00 00
  Pointers
    24  10 69 eb 3b
        78 6a eb 3b
        32 6f eb 3b
  0030: 8c 6f eb 3b
        c8 6f eb 3b

RSD PTR @ 0xf7c70
  0000: 52 53 44 20 50 54 52 20 9e 50 54 4c 54 44 20 02  RSD PTR .PTLTD .
  0010: 49 2a eb 3b  rsdt-adr
        24 00 00 00  len
        81 2a eb 3b 00 00 00 00  xdst-adr
  0020: 0b  ext-csum  res
        00 00 00                                      ....

FACS @ 0x3beb7fc0
  0000: 46 41 43 53  signature
        40 00 00 00  len
        00 00 00 00  HW signature
        00 00 00 00  waking vector
  0010: 00 00 00 00  global lock
        00 00 00 00  flags
        00 00 00 00 00 00 00 00  64-bit waking vector
  0020: 01 00 00 00  version
        00 00 00 00 00 00 00 00 00 00 00 00  working area
  0030: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  working area

FACP @ 0x3beb6984 (version 3, 244 bytes)
  0000: 46 41 43 50 f4 00 00 00 03 27 56 58 38 35 35 20  FACP.....'VX855 
  0010: 50 54 4c 54 57 20 20 20 00 00 04 06 50 54 4c 5f  PTLTW   ....PTL_
  0020: 40 42 0f 00
        c0 7f eb 3b facs-adr
        cd 2a eb 3b dsdt-adr
        00 res
        00 pm-profile
        0a 00  sci-interrupt
  0030: 2f 40 00 00
        f0
        f1
        00
        80
        00 40 00 00
        00 00 00 00  /@.......@......
  0040: 04 40 00 00
        00 00 00 00
        22 00 00 00
        08 40 00 00 
  0050: 20 40 00 00
        00 00 00 00
        04
        02
        01
        04
        04
        00
        10
        85
  0060: 01 00
        01 00
        00 00
        00 00
        00
        04
        7d
        7e
        32
        00 00
        00
  0070: a5 00 00 00

        00 00 00 00  00 00 00 00  00 00 00 00    reset register
  0080: 00 reset value
        00 00 00 res
        c0 7f eb 3b  00 00 00 00  facs-adr-64
        cd 2a eb 3b  00 00 00 00  dsdt-adr-64
    94: 01 20 00 00  00 40 00 00  00 00 00 00  pm1a-event-reg-block
  00a0: 00 00 00 00  00 00 00 00  00 00 00 00  pm1b-event-reg-block
        01 10 00 00  04 40 00 00  00 00 00 00  pm1a-cnt-block
    b8: 00 00 00 00  00 00 00 00  00 00 00 00  pm1b-cnt-block
        01 08 00 00  22 00 00 00  00 00 00 00  pm2-cnt-block
  00d0: 01 20 00 00  08 40 00 00  00 00 00 00  pm_tmr_block
        01 20 00 00  20 40 00 00  00 00 00 00  gpe0-block
        00 00 00 00  00 00 00 00  00 00 00 00  gpe1-block

SSDT @ 0x3beb6a78
  0000: 53 53 44 54 ba 04 00 00 01 3c 50 50 6d 6d 52 65  SSDT.....<PPmmRe
  0010: 50 50 6d 00 00 00 00 00 00 00 04 06 49 4e 54 4c  PPm.........INTL
  0020: 24 02 03 20 10 45 49 5c 2e 5f 50 52 5f 43 50 55  $.. .EI\._PR_CPU
  0030: 30 08 50 44 43 54 0a 00 08 50 44 43 52 0a 01 08  0.PDCT...PDCR...
  0040: 50 44 43 4d 0a 01 14 4c 06 5f 50 44 43 01 70 87  PDCM...L._PDC.p.
  0050: 68 60 08 50 44 43 42 11 03 0a 14 70 68 50 44 43  h`.PDCB....phPDC
  0060: 42 8a 50 44 43 42 0a 00 52 45 56 5f 8a 50 44 43  B.PDCB..REV_.PDC
  0070: 42 0a 04 53 49 5a 45 a0 0e 92 93 52 45 56 5f 50  B..SIZE....REV_P
  0080: 44 43 52 a4 0a 00 a0 0b 95 53 49 5a 45 0a 01 a4  DCR......SIZE...
  0090: 0a 00 8a 50 44 43 42 0a 08 44 41 54 30 a0 12 7b  ...PDCB..DAT0..{
  00a0: 44 41 54 30 50 44 43 4d 00 70 0a 01 50 44 43 54  DAT0PDCM.p..PDCT
  00b0: a4 0a 01 08 50 43 54 31 12 2c 02 11 14 0a 11 82  ....PCT1.,......
  00c0: 0c 00 7f 00 00 00 00 00 00 00 00 00 00 00 79 00  ..............y.
  00d0: 11 14 0a 11 82 0c 00 7f 00 00 00 00 00 00 00 00  ................
  00e0: 00 00 00 79 00 08 50 43 54 32 12 2c 02 11 14 0a  ...y..PCT2.,....
  00f0: 11 82 0c 00 01 08 00 00 2f 40 00 00 00 00 00 00  ......../@......
  0100: 79 00 11 14 0a 11 82 0c 00 01 08 00 00 80 00 00  y...............
  0110: 00 00 00 00 00 79 00 08 58 43 54 31 12 2c 02 11  .....y..XCT1.,..
  0120: 14 0a 11 82 0c 00 7f 40 00 00 99 01 00 00 00 00  .......@........
  0130: 00 00 79 00 11 14 0a 11 82 0c 00 7f 40 00 00 00  ..y.........@...
  0140: 00 00 00 00 00 00 00 79 00 14 37 5f 50 43 54 00  .......y..7_PCT.
  0150: a0 19 5c 5f 4f 53 49 0d 57 69 6e 64 6f 77 73 20  ..\_OSI.Windows 
  0160: 32 30 30 36 00 a4 58 43 54 31 a1 16 a0 0d 93 50  2006..XCT1.....P
  0170: 44 43 54 0a 00 a4 50 43 54 32 a1 06 a4 50 43 54  DCT...PCT2...PCT
  0180: 31 08 58 50 53 53 12 4b 1b 02 12 36 08 0c e8 03  1.XPSS.K...6....
  0190: 00 00 0c 10 27 00 00 0c 0a 00 00 00 0c 0a 00 00  ....'...........
  01a0: 00 11 07 0a 04 06 0a 00 00 11 07 0a 04 00 00 00  ................
  01b0: 00 11 07 0a 04 00 00 00 00 11 07 0a 04 06 0a 00  ................
  01c0: 00 12 36 08 0c 90 01 00 00 0c a0 0f 00 00 0c 0a  ..6.............
  01d0: 00 00 00 0c 0a 00 00 00 11 07 0a 04 06 04 00 00  ................
  01e0: 11 07 0a 04 00 00 00 00 11 07 0a 04 00 00 00 00  ................
  01f0: 11 07 0a 04 06 04 00 00 12 36 08 0c 90 01 00 00  .........6......
  0200: 0c a0 0f 00 00 0c 0a 00 00 00 0c 0a 00 00 00 11  ................
  0210: 07 0a 04 06 04 00 00 11 07 0a 04 00 00 00 00 11  ................
  0220: 07 0a 04 00 00 00 00 11 07 0a 04 06 04 00 00 12  ................
  0230: 36 08 0c 90 01 00 00 0c a0 0f 00 00 0c 0a 00 00  6...............
  0240: 00 0c 0a 00 00 00 11 07 0a 04 06 04 00 00 11 07  ................
  0250: 0a 04 00 00 00 00 11 07 0a 04 00 00 00 00 11 07  ................
  0260: 0a 04 06 04 00 00 12 36 08 0c 90 01 00 00 0c a0  .......6........
  0270: 0f 00 00 0c 0a 00 00 00 0c 0a 00 00 00 11 07 0a  ................
  0280: 04 06 04 00 00 11 07 0a 04 00 00 00 00 11 07 0a  ................
  0290: 04 00 00 00 00 11 07 0a 04 06 04 00 00 12 36 08  ..............6.
  02a0: 0c 90 01 00 00 0c a0 0f 00 00 0c 0a 00 00 00 0c  ................
  02b0: 0a 00 00 00 11 07 0a 04 06 04 00 00 11 07 0a 04  ................
  02c0: 00 00 00 00 11 07 0a 04 00 00 00 00 11 07 0a 04  ................
  02d0: 06 04 00 00 12 36 08 0c 90 01 00 00 0c a0 0f 00  .....6..........
  02e0: 00 0c 0a 00 00 00 0c 0a 00 00 00 11 07 0a 04 06  ................
  02f0: 04 00 00 11 07 0a 04 00 00 00 00 11 07 0a 04 00  ................
  0300: 00 00 00 11 07 0a 04 06 04 00 00 12 36 08 0c 90  ............6...
  0310: 01 00 00 0c a0 0f 00 00 0c 0a 00 00 00 0c 0a 00  ................
  0320: 00 00 11 07 0a 04 06 04 00 00 11 07 0a 04 00 00  ................
  0330: 00 00 11 07 0a 04 00 00 00 00 11 07 0a 04 06 04  ................
  0340: 00 00 08 50 50 53 31 12 43 0a 02 12 13 06 0b e8  ...PPS1.C.......
  0350: 03 0b 10 27 0b 0a 00 0a 0a 0b 06 0a 0b 06 0a 12  ...'............
  0360: 13 06 0b 90 01 0b a0 0f 0b 0a 00 0a 0a 0b 06 04  ................
  0370: 0b 06 04 12 13 06 0b 90 01 0b a0 0f 0b 0a 00 0a  ................
  0380: 0a 0b 06 04 0b 06 04 12 13 06 0b 90 01 0b a0 0f  ................
  0390: 0b 0a 00 0a 0a 0b 06 04 0b 06 04 12 13 06 0b 90  ................
  03a0: 01 0b a0 0f 0b 0a 00 0a 0a 0b 06 04 0b 06 04 12  ................
  03b0: 13 06 0b 90 01 0b a0 0f 0b 0a 00 0a 0a 0b 06 04  ................
  03c0: 0b 06 04 12 13 06 0b 90 01 0b a0 0f 0b 0a 00 0a  ................
  03d0: 0a 0b 06 04 0b 06 04 12 13 06 0b 90 01 0b a0 0f  ................
  03e0: 0b 0a 00 0a 0a 0b 06 04 0b 06 04 08 50 50 53 32  ............PPS2
  03f0: 12 43 0a 02 12 13 06 0b e8 03 0b 10 27 0b 26 02  .C..........'.&.
  0400: 0a 0a 0b b0 00 0b b0 00 12 13 06 0b 90 01 0b a0  ................
  0410: 0f 0b bc 02 0a 0a 0b b1 00 0b b1 00 12 13 06 0b  ................
  0420: 90 01 0b a0 0f 0b bc 02 0a 0a 0b b2 00 0b b2 00  ................
  0430: 12 13 06 0b 90 01 0b a0 0f 0b bc 02 0a 0a 0b b3  ................
  0440: 00 0b b3 00 12 13 06 0b 90 01 0b a0 0f 0b bc 02  ................
  0450: 0a 0a 0b b4 00 0b b4 00 12 13 06 0b 90 01 0b a0  ................
  0460: 0f 0b bc 02 0a 0a 0b b5 00 0b b5 00 12 13 06 0b  ................
  0470: 90 01 0b a0 0f 0b bc 02 0a 0a 0b b6 00 0b b6 00  ................
  0480: 12 13 06 0b 90 01 0b a0 0f 0b bc 02 0a 0a 0b b7  ................
  0490: 00 0b b7 00 14 1b 5f 50 53 53 00 a0 0d 93 50 44  ......_PSS....PD
  04a0: 43 54 0a 00 a4 50 50 53 32 a1 06 a4 50 50 53 31  CT...PPS2...PPS1
  04b0: 14 09 5f 50 50 43 00 a4 0a 00                    .._PPC....
[then]
    
