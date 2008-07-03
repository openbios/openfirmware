\ Make some ACPI descriptor tables

h# 9.fc00 constant 'ebda  \ Extended BIOS Data Area, which we co-opt for our real-mode workspace

h# e0000 constant rsdp-adr
h# e0040 constant rsdt-adr
h# e0080 constant fadt-adr
h# e0180 constant facs-adr
h# e01c0 constant dbgp-adr

h# fc000 constant dsdt-adr
h# fd000 constant ssdt-adr
h# 0. 2constant xsdt-adr

create fadt
( 000 4 )  " FACP"     $, \ Signature
( 004 4 )  h#   84     l, \ Table Length
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
( 02E 2 )  h# 0003 w,     \ SCI Interrupt

\ These are the values that AMD uses
\ ( 030 4 )  h# 9c3c l,     \ SMI Command Port
\ ( 034 1 )  h#   a1 c,     \ ACPI Enable Value
\ ( 035 1 )  h#   a2 c,     \ ACPI Disable Value

\ These values appear to work, but aren't really necessary if we don't support Legacy SMI PM mode
\ ( 030 4 )  h# 9c08 l,     \ SMI Command Port
\ ( 034 1 )  h#    1 c,     \ ACPI Enable Value
\ ( 035 1 )  h#    0 c,     \ ACPI Disable Value

\ Setting all of these to 0 tells the OS that the system is always in ACPI mode
( 030 4 )  h#    0 l,     \ SMI Command Port
( 034 1 )  h#    0 c,     \ ACPI Enable Value
( 035 1 )  h#    0 c,     \ ACPI Disable Value

( 036 1 )  h#   00 c,     \ S4BIOS Command
( 037 1 )  h#   00 c,     \ P-State Control
( 038 4 )  h# 9c00 l,     \ PM1A Event Block Address
( 03C 4 )  h#    0 l,     \ PM1B Event Block Address
\ ( 040 4 )  h# 9c28 l,     \ PM1A Control Block Address
( 040 4 )  h# 9c08 l,     \ PM1A Control Block Address
( 044 4 )  h#    0 l,     \ PM1B Control Block Address
( 048 4 )  h# 9c0c l,     \ PM2 Control Block Address
\ ( 04C 4 )  h# 9c10 l,     \ PM Timer Block Address
( 04C 4 )  h# 1850 l,     \ PM Timer Block Address
( 050 4 )  h# 9c18 l,     \ GPE0 Block Address
( 054 4 )  h#    0 l,     \ GPE1 Block Address
( 058 1 )  h#    4 c,     \ PM1 Event Block Length
( 059 1 )  h#    2 c,     \ PM1 Control Block Length
( 05A 1 )  h#    2 c,     \ PM2 Control Block Length
( 05B 1 )  h#    4 c,     \ PM Timer Block Length
( 05C 1 )  h#    8 c,     \ GPE0 Block Length
( 05D 1 )  h#    0 c,     \ GPE1 Block Length
( 05E 1 )  h#    0 c,     \ GPE1 Base Offset
( 05F 1 )  h#    0 c,     \ _CST Support
( 060 2 )  h#   63 w,     \ C2 Latency
( 062 2 )  h# 9999 w,     \ C3 Latency
( 064 2 )  h#    0 w,     \ CPU Cache Size
( 066 2 )  h#    0 w,     \ Cache Flush Stride
( 068 1 )  h#    0 c,     \ Duty Cycle Offset
( 069 1 )  h#    4 c,     \ Duty Cycle Width
( 06A 1 )  h#   3d c,     \ RTC Day Alarm Index
( 06B 1 )  h#   3e c,     \ RTC Month Alarm Index
( 06C 1 )  h#   32 c,     \ RTC Century Index : 
( 06D 2 )  h#    0 w,     \ Boot Architecture Flags
( 06F 1 )  h#    0 c,     \ Reserved
( 070 4 )  h#  5a5 l,     \ Flags
( 074 12 ) 1 c, 8 c, 0 c, 1 c,  h# 92. d,   \ Reset register - I/O, 8 bits, 0 offset, byte access

( 080 1 )  h#    1 c,     \ Reset value
( 081 3 )  0 c, 0 c, 0 c, \ Reserved
here fadt - constant /fadt

\ FADT Flags:
\      WBINVD is operational : 1
\ WBINVD does not invalidate : 0
\        All CPUs support C1 : 1
\      C2 works on MP system : 0
\    Power button is generic : 0
\    Sleep button is generic : 1
\       RTC wakeup not fixed : 0
\ RTC wakeup/S4 not possible : 1
\            32-bit PM Timer : 1
\          Docking Supported : 0

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

create rsdt
( 00 4 )  " RSDT"     $,  \ Signature
\ ( 04 4 )  h#   34     l,  \ Length
( 04 4 )  h#   30     l,  \ Length
( 08 1 )        1     c,  \ Revision
( 09 1 )       00     c,  \ Checksum
( 0a 6 )  " OLPC  "   $,  \ Oem Id
( 10 8 )  " OLPC_000" $,  \ Oem Table Id
( 18 4 )  " 0000"     $,  \ Oem revision
( 1c 4 )  " OLPC"     $,  \ Creator ID
( 20 4 )  " 0000"     $,  \ Creator revision
( 24 4 )  fadt-adr    l,  \ FADT Address
( 28 4 )  dsdt-adr    l,  \ DSDT Address
( 2c 4 )  dbgp-adr    l,  \ DBGP Address
\ ( 30 4 )  ssdt-adr    l,  \ SSDT Address
\ ( 30 4 )  prtn-adr    l,  \ PRTN Address
here rsdt - constant /rsdt

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
here dbgp - constant /dbgp

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
here facs - constant /facs

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

: setup-acpi  ( -- )
   \ This has to agree with the _SB's _INI method, which gets the memory size
   \ from offset h# 180 in the EBDA
   memory-limit d# 10 rshift  'ebda h# 180 + l!

   \ Copy rsdt and fadt to low memory
   rsdp  rsdp-adr  /rsdp move  rsdp-adr h# 14 8 fix-checksum   rsdp-adr /rsdp h# 20 fix-checksum  
   rsdt  rsdt-adr  /rsdt move  rsdt-adr /rsdt 9 fix-checksum
   fadt  fadt-adr  /fadt move  fadt-adr /fadt 9 fix-checksum
   dbgp  dbgp-adr  /dbgp move  dbgp-adr /dbgp 9 fix-checksum
   facs  facs-adr  /facs move

   \ Copy in the DSDT
   \ I suppose we could point to it in FLASH - if so don't compress it,
   \ and fixup the address in the fadt and rechecksum the fadt
   " dsdt" find-drop-in  0= abort" No DSDT "  ( adr len )
   2dup dsdt-adr swap  move  free-mem

[ifdef] notdef
   \ Copy in the SSDT
   \ I suppose we could point to it in FLASH - if so don't compress it,
   \ and fixup the address in the fadt and rechecksum the fadt
   " ssdt" find-drop-in  0= abort" No SSDT "  ( adr len )
   2dup ssdt-adr swap  move  free-mem
[then]

   1 8 acpi-w!  \ Set SCI_EN bit
   h# ffffffff  h# 18 acpi-l!  \ Ack all leftover events
;

h# 6000 constant xp-smbus-base
: rm-platform-fixup  ( -- )
   xp-smbus-base h# f001   h# 5140.000b  3dup msr!  find-msr-entry  2!
   xp-smbus-base 1+  h# 10 isa-hdr  >hdr-value  l!
;
