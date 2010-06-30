\ Make SMBIOS tables


0 [if]
h# ffbc0 constant 'pciirq
\ http://www.microsoft.com/whdc/archive/pciirq.mspx
\ create pciirq-header
\    h# 52495024 l, \ $PIR
\    h# 0100 w,     \ version 1.0
\    h# 0040 w,     \ Total size
\ 
\    0 c,  0 c,     \ Bus#, DevFunc#
\    0 w,           \ Exclusive IRQs
\    0 l,           \ Compatible router
\    0 l,           \ miniport data
\    0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c,  \ res
\    h# b0 c,       \ checksum
\    \ Table data goes here

: make-pciirq-table  ( -- )
   'pciirq h# 40 erase
   h# 52495024  'pciirq l!            \ $PIR
   h# 0100      'pciirq la1+ w!       \ version
   h# 0040      'pciirq la1+ wa1+ w!  \ total size
   h# b0        'pciirq h# 1f + c!    \ checksum
   \ The rest of the table is 0 because the actual routing
   \ is now done by ACPI
;
[then]

: c$,  $, 0 c, ;

0 value #smbios-tables
: copy-smbios-table  ( dst-adr table -- dst-adr' )
   #smbios-tables 1+ to #smbios-tables
   2dup 1+ c@       ( dst-adr  table dst-adr len )
   dup >r  move     ( dst-adr  r: len )
   r> +             ( dst-adr' )
;

: smbios-c,  ( dst-adr b -- dst-adr' )  over c!  1+  ;
: smbios-w,  ( dst-adr w -- dst-adr' )  over le-w!  wa1+  ;
: smbios-l,  ( dst-adr l -- dst-adr' )  over le-l!  la+  ;
: smbios-null  ( dst-adr -- dst-adr' )  0 smbios-c,  ;
: end-smbios-table  ( dst-adr -- dst-adr' )  smbios-null  ;
: +smbios$  ( dst-adr adr len -- dst-adr' )
   3dup rot  swap move   ( dst-adr adr len )
   nip +  smbios-null
;

0 value uuid-adr

create smbios-entry
( 00 )   " _SM_" $,
( 04 )        0  c,  \ Byte checksum - structure must sum to 0 SETME
( 05 )    h# 1f  c,  \ Entry structure length
( 06 )    h# 02  c,  \ Major version
( 07 )    h# 01  c,  \ Minor version
( 08 )   h# 100  w,  \ Maximum size of a structure
( 0a )    h# 00  c,  \ Entry point revision
( 0b )  0 c, 0 c, 0 c, 0 c, 0 c,  \ Formatted area
( 10 )  " _DMI_" $,  \ Intermediate anchor string
( 15 )        0  c,  \ Intermediate checksum  SETME
( 16 )        0  w,  \ Structure table length SETME
( 18 )        0  l,  \ Structure table address SETME
\ ( 1c )    d# 11  w,  \ Number of structures
( 1c )    d# 12  w,  \ Number of structures
( 1e )    h# 21  c,  \ BCD revision

create bios-info
( 00 )         0 c,  \ BIOS info type code
( 01 )     h# 13 c,  \ Length (one BIOS characteristic extension byte)
( 02 )   h# 0000 w,  \ Handle
( 04 )         1 c,  \ Vendor string index
( 05 )         2 c,  \ Version string index
( 06 )   h# f000 w,  \ BIOS starting address segment
( 08 )         3 c,  \ Release date index
( 09 )     h# 0f c,  \ BIOS ROM size in 64K chunks, minus 1
( 0a )  h# 99880 l,  \ BIOS characteristics - PCI, Reflash, shadowing, CD boot, selectable boot, EDD
( 0e )         0 l,  \ Vendor and system specific BIOS characteristics
( 12 )         1 c,  \ ACPI is supported
\        " OLPC" c$,  \ Vendor string
\       " Q2E00" c$,  \ Version string
\  " 04/01/2008" c$,  \ Release date string
\               0 c,  \ End

create system-info
( 00 )         1 c,  \ System info type code
( 01 )     h# 19 c,  \ Length (for v2.1)
( 02 )   h# 0100 w,  \ Handle
( 04 )         1 c,  \ Manufacturer string index
( 05 )         2 c,  \ Product name string index
( 06 )         3 c,  \ Version string index
( 07 )         4 c,  \ Serial number string index
( 08 )  here to uuid-adr  h# 10 allot  \ SETME
( 18 )         6 c,  \ Wake up type
\       " OLPC" c$,  \ 1: Manufacturer
\         " XO" c$,  \ 2: Product Name
\          " 1" c$,  \ 3: Version
\       " <sn>" c$,  \ 4: Serial number
\              0 c,

create base-board-info
( 00 )         2 c,  \ System info type code
( 01 )     h#  8 c,  \ Length (for v2.1)
( 02 )   h# 0200 w,  \ Handle
( 04 )         1 c,  \ Manufacturer string index
( 05 )         2 c,  \ Product string index
( 06 )         3 c,  \ Version string index
( 07 )         4 c,  \ Serial number string index
\     " QUANTA" c$,  \ 1: Manufacturer
\         " XO" c$,  \ 2: Product Name
\          " 1" c$,  \ 3: Version


create system-enclosure
( 00 )         3 c,  \ System enclosure type code
( 01 )     h# 0d c,  \ Length (for v2.1)
( 02 )   h# 0300 w,  \ Handle
( 04 )         1 c,  \ Manufacturer string index
( 05 )         9 c,  \ Type - laptop
( 06 )         2 c,  \ Version number string index
( 07 )         0 c,  \ Serial number string index
( 08 )         0 c,  \ Asset tag string index
( 09 )         3 c,  \ Boot-up state
( 0a )         3 c,  \ Power Supply State
( 0b )         3 c,  \ Thermal State
( 0c )         5 c,  \ Security Status - XXX set to 4 in secure mode
\       " OLPC" c$,  \ 2: Manufacturer
\          " 1" c$,  \ 3: Version
\              0 c,

create processor-info
( 00 )         4 c,  \ Processor info type code
( 01 )     h# 20 c,  \ Length (for v2.1)
( 02 )   h# 0400 w,  \ Handle
( 04 )         0 c,  \ Reference designator string index
( 05 )         3 c,  \ Type - CPU
( 06 )         1 c,  \ Family - other
( 07 )         1 c,  \ Manufacturer
( 08 )  h# 5a2 l,  h# 88a93d l,  \ CPUID results - Set dynamically later
( 10 )         2 c,  \ Processor version string index
( 11 )     h# 8c c,  \ Processor voltage (h# 80 + 1.2V/10)
( 12 )    d#  33 w,  \ External clock (main bus clock)
( 14 )    d# 433 w,  \ Max speed
( 16 )    d# 433 w,  \ Current speed
( 18 )     h# 41 c,  \ CPU present and enabled
( 19 )         6 c,  \ Processor upgrade - None
( 1a )   h# 0701 w,  \ L1 Cache Handle
( 1c )   h# 0703 w,  \ L2 Cache Handle
( 1e )   h# ffff w,  \ L3 Cache Handle
\        " AuthenticAMD" c$,  \ 1: Manufacturer
\              0 c,

create l1-icache-info
( 00 )        7 c,   \ Cache info type code
( 01 )    h# 13 c,   \ Length
( 02 )  h# 0701 w,   \ Handle
( 04 )        0 c,   \ Socket string index
( 05 )   h# 180 w,   \ Writeback, enabled, internal, not socketed, L1
( 07 )  h# 8002 w,   \ Max size - 128K
( 09 )  h# 8002 w,   \ Installed size - 128K
( 0b )        1 w,   \ Supported SRAM type - unknown
( 0d )        1 w,   \ Installed SRAM type - unknown
( 0f )        0 c,   \ Speed (NS)
( 10 )        1 c,   \ ECC - other
( 11 )        5 c,   \ Type - Unified (actually it is split I and D but they are coherent)
( 12 )        5 c,   \ Associativity - 4-way set-associative
\             0 w,

0 [if]
create l1-dcache-info
( 00 )        7 c,   \ Cache info type code
( 01 )    h# 13 c,   \ Length
( 02 )  h# 0702 w,   \ Handle
( 04 )        0 c,   \ Socket string index
( 05 )   h# 180 w,   \ Writeback, enabled, internal, not socketed, L1
( 07 )  h# 8001 w,   \ Max size - 64K
( 09 )  h# 8001 w,   \ Installed size - 64K
( 0b )        1 w,   \ Supported SRAM type - unknown
( 0d )        1 w,   \ Installed SRAM type - unknown
( 0f )        0 c,   \ Speed (NS)
( 10 )        3 c,   \ ECC - none
( 11 )        4 c,   \ Type - Data
( 12 )        8 c,   \ Associativity - 16-way set-associative
\             0 w,
[then]

create l2-cache-info
( 00 )        7 c,   \ Cache info type code
( 01 )    h# 13 c,   \ Length
( 02 )  h# 0703 w,   \ Handle
( 04 )        0 c,   \ Socket string index
( 05 )   h# 181 w,   \ Writeback, enabled, internal, not socketed, L2
( 07 )  h# 8002 w,   \ Max size - 128K
( 09 )  h# 8002 w,   \ Installed size - 128K
( 0b )        1 w,   \ Supported SRAM type - unknown
( 0d )        1 w,   \ Installed SRAM type - unknown
( 0f )        0 c,   \ Speed (NS)
\ ( 10 )        3 c,   \ ECC - none
( 10 )        1 c,   \ ECC - other
( 11 )        5 c,   \ Type - Unified
( 12 )     h# a c,   \ Associativity - 32-way set-associative
\             0 w,

0 value portinfo#
: make-smbios-port  ( dst-adr connectortype porttype name$ -- dst-adr' )
   #smbios-tables 1+ to #smbios-tables
   2>r >r >r
   8 smbios-c,  9 smbios-c,
   portinfo# h# 800 + smbios-w,  portinfo# 1+ to portinfo#
   0 smbios-c,  0 smbios-c,  \ Internal Refdes and Internal Connector Type
   1 smbios-c,               \ String index
   r> smbios-c,              \ Connector type
   r> smbios-c,              \ Port type
   2r> +smbios$              \ Reference designator string
   end-smbios-table
;

create sd-slot-array
( 00 )    d#  9 c,   \ physical-memory-array type code
( 01 )    h# 0d c,   \ Length
( 02 )  h#  d01 w,   \ Handle
( 04 )        1 c,   \ Refdes
( 05 )     h# b c,   \ Slot type - proprietary
( 06 )        1 c,   \ Bus width - other
( 07 )        4 c,   \ Usage - in use
( 08 )        3 c,   \ Length - short
( 09 )  h# 0000 w,   \ ID - meaningless
( 0b )        4 c,   \ Characteristics 1 - 3.3V
( 0c )        2 c,   \ Characteristics 2 - hot plug

create video-array
( 00 )    d# 10 c,   \ onboard device type code
( 01 )    h# 06 c,   \ Length
( 02 )  h#  a01 w,   \ Handle
( 04 )    h# 83 c,   \ Enabled, type 3 (video)
( 05 )        1 c,   \ Description string

create bios-lang-array
( 00 )    d# 13 c,   \ BIOS language type code
( 01 )    h# 16 c,   \ Length
( 02 )  h#  d01 w,   \ Handle
( 04 )        1 c,   \ Number of languages
( 05 )        1 c,   \ Flags - abbreviated format
( 06 )   0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c,  \ Res
( 15 )        1 c,   \ Currrent language string

create main-memory-array
( 00 )    d# 16 c,   \ physical-memory-array type code
( 01 )    h# 0f c,   \ Length
( 02 )  h# 1001 w,   \ Handle
( 04 )        3 c,   \ Location - onboard
( 05 )        3 c,   \ Use - system memory
( 06 )        3 c,   \ ECC - none
( 07 ) h# 100000 l,   \ Maximum size - 1024K KiB (1 GiB)
( 0b )  h# fffe w,   \ Memory Error Info Handle - not provided
( 0d )        1 w,   \ Number of devices
\             0 w,

create memory-device
( 00 )    d# 17 c,   \ physical-memory-array type code
( 01 )    h# 15 c,   \ Length
( 02 )  h# 1101 w,   \ Handle
( 04 )  h# 1001 w,   \ Handle of "parent" memory array
( 06 )  h# fffe w,   \ Memory Error Info Handle - not provided
( 08 )    d# 64 w,   \ Total width
( 0a )    d# 64 w,   \ Data width
( 0c )   h# 400 w,   \ Size - 1024 MB
( 0e )    h# 0b c,   \ Form factor - row of chips
( 0f )        0 c,   \ Set - not part of a set
( 10 )        1 c,   \ Device Locator string index
( 11 )        0 c,   \ Bank Locator string index
( 12 )    h# 13 c,   \ Memory type - DDR3
( 13 )  h# 0080 w,   \ Memory type detail - Synchronous
\  " Soldered" c$,
\             0 w,

create ma-mapped-address
( 00 )    d# 19 c,   \ memory-array-mapped-address type code
( 01 )    h# 0f c,   \ Length
( 02 )  h# 1301 w,   \ Handle
( 04 )        0 l,   \ Starting address - first KiB
( 08 ) h# fffff l,   \ Ending address - last KiB
( 0c )    h# 31 w,   \ Handle of "parent" memory array
( 0e )    h#  1 c,   \ Partition width
\             0 w,

create pointing-device
( 00 )    d# 21 c,   \ system boot info type code
( 01 )    h# 07 c,   \ Length
( 02 )  h# 1501 w,   \ Handle
( 04 )        7 c,   \ Type - touchpad
( 05 )        4 c,   \ Interface - PS/2
( 06 )        2 c,   \ #buttons - 2


create system-boot-info
( 00 )    d# 32 c,   \ system boot info type code
( 01 )    h# 0b c,   \ Length
( 02 )  h# 2000 w,   \ Handle
( 04 )  0 l,  0 w,   \ 6 reseved bytes
( 0a )        0 c,   \ Boot status - no errors
\             0 w,

create end-array
( 00 )    h# 7f c,   \ End type code
( 01 )    h# 04 c,   \ Length
( 02 )  h# 7f01 w,   \ Handle


: test-name$  ( -- $ )  "  IE8y2D ScD%g4r2bAIFA."  ;
: test-version$  ( -- $ )  " OLPC Ver 1.00.15"  ;
: fw-version$  ( -- $ )
   " /openprom" find-package if
      " model" rot get-package-property  0=  if
         get-encoded-string   ( adr len )
         dup d# 16 =  if
            \ We just want the "Q2E00" part
            drop 6 +  5  exit
         then
         2drop
      then
   then
   " Unknown"
;
d# 10 buffer: fw-date-buf

\ Convert build-date format "2008-04-14" to SMBIOS format "04/14/2008"
: fw-date$  ( -- $ )
   " xx/xx/xxxx" fw-date-buf swap move
   " build-date" evaluate drop   ( adr )
   dup      fw-date-buf 6 +  4 move  ( adr )  \ Year
   dup 5 +  fw-date-buf      2 move  ( adr )  \ Month
   8 +      fw-date-buf 3 +  2 move  ( )      \ Day
   fw-date-buf d# 10
;
: get-tag$  ( tag$ -- value$ )  find-tag  0=  if  " Not Available"  then  ?-null  ;

: too-long?  ( dst-adr -- dst-adr flag )  dup pad - h# 10 >=  ;
: (uuid)  ( -- true | adr len false )
   " U#" find-tag   if     ( adr len )
      ?-null               ( adr len' )
      pad  -rot            ( dst-adr adr len )
      bounds  ?do                      ( dst-adr )
         too-long?  if  drop true unloop exit  then
         i c@ h# 10 digit  if          ( dst-adr digith )
            i 1+ c@  h# 10 digit  if   ( dst-adr digith digitl )
               swap 4 lshift or        ( dst-adr byte )
               over c!  1+             ( dst-adr' )
               2                       ( dst-adr advance )
            else                       ( dst-adr digith char )
               3drop true unloop exit
            then                       ( dst-adr )
         else                          ( dst-adr char )
            [char] - <>  if  drop true unloop exit  then
            1                          ( dst-adr advance )
         then                          ( dst-adr advance )
      +loop                            ( dst-adr )
      pad tuck -                       ( adr len )
      dup h# 10 =  if                  ( adr len )
         false   \ Good UUID           ( adr len false )
      else                             ( adr len )
         2drop true                    ( true )
      then                             ( true | adr len false )
   else                                ( )
      true                             ( true )
   then                                ( true | adr len false )
;
: get-uuid  ( -- uuid$ )
   (uuid)  if  " "(00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff)"  then
;

code get-cpuid  ( code -- eax ebx ecx edx )
   ax pop  cpuid  ax push  bx push  cx push  dx push
c;
0 value ptr
: 0pad  ( -- )  pad to ptr  ;
: pad,  ( n -- )  ptr !  ptr na1+ to ptr  ;

: cpu-family$  ( -- adr len )
   0 get-cpuid  0pad  rot pad,  pad,  pad,  drop
   pad d# 12
;

: 4scramble  ( a b c d -- d c b a )  swap 2swap swap  ;
: cpu-name,  ( cpuid# -- )  get-cpuid  4scramble pad, pad, pad, pad,  ;

: cpu-name$  ( -- adr len )
   0pad
   h# 8000.0002 cpu-name,
   h# 8000.0003 cpu-name,
   h# 8000.0004 cpu-name,
   pad h# 30 -leading -trailing
;

: +OEM  ( adr -- adr' )  " QUANTACOMPUTER" +smbios$  ;
: setup-smbios  ( -- )
   0 to #smbios-tables
   0 to portinfo#

   smbios-entry  smbios-adr  h# 1f  move
   smbios-adr h# 1f +                   ( adr )

   bios-info copy-smbios-table       ( adr )
      test-name$ +smbios$
      test-version$ +smbios$
\      +OEM
\      fw-version$ +smbios$
      fw-date$    +smbios$
   end-smbios-table

   dup >r                            ( adr  r: adr )
   system-info copy-smbios-table     ( adr  r: adr )
      get-uuid  r> 8 +  swap move    ( adr )   
      +OEM
      " XO" +smbios$
      " 1.5" +smbios$    \ Version
      " SN" get-tag$ +smbios$
   end-smbios-table

   base-board-info copy-smbios-table        ( adr )
      " QUANTA" +smbios$
      " XO" +smbios$
      " 1.5" +smbios$    \ Version
      " SN" get-tag$ +smbios$
   end-smbios-table

   \ XXX might need to amend the security status field
   system-enclosure copy-smbios-table       ( adr )
      +OEM
      " 1.5" +smbios$    \ Version
   end-smbios-table

   dup >r                                   ( adr  r: adr )
   processor-info copy-smbios-table         ( adr' r: adr )
      1 get-cpuid  nip nip                  ( adr' eax edx r: adr )
      r@ h# c + l!  r> 8 + l!               ( adr' )
      cpu-family$ +smbios$
      cpu-name$ +smbios$
   end-smbios-table

   l1-icache-info copy-smbios-table  smbios-null  end-smbios-table
\   l1-dcache-info copy-smbios-table  smbios-null  end-smbios-table
   l2-cache-info  copy-smbios-table  smbios-null  end-smbios-table

[ifdef] notdef  \ Why bother - XP doesn't collect these
   h# 1f h# 1d " Microphone" make-smbios-port
   h# 1f h# 1d " Headphone"  make-smbios-port
   h# 12 h# 10 " USB1" make-smbios-port
   h# 12 h# 10 " USB2" make-smbios-port
   h# 12 h# 10 " USB3" make-smbios-port

   sd-slot-array      copy-smbios-table  " SD Slot" +smbios$   end-smbios-table
   bios-lang-array    copy-smbios-table  " enUS"    +smbios$   end-smbios-table
[then]
   video-array        copy-smbios-table  " CON"     +smbios$   end-smbios-table

   main-memory-array  copy-smbios-table  smbios-null           end-smbios-table
   memory-device      copy-smbios-table  " Soldered" +smbios$  end-smbios-table
   ma-mapped-address  copy-smbios-table  smbios-null           end-smbios-table

\ XP ignores it
\  pointing-device    copy-smbios-table  smbios-null           end-smbios-table

   \ PORTABLE BATTERY (TYPE 22)

\ XP ignores it
\   system-boot-info   copy-smbios-table  smbios-null           end-smbios-table

   end-array          copy-smbios-table  smbios-null           end-smbios-table   ( adr' )

   \ Fixup the entry structure
   smbios-adr h# 1f +   tuck -         ( tables-adr tables-len )
   smbios-adr h# 16 +  w!              ( tables-adr )
   smbios-adr h# 18 +  l!              ( )
   #smbios-tables smbios-adr h# 1c + w!

   smbios-adr          h# 1f  4  fix-checksum  \ Overall checksum
   smbios-adr h# 10 +  h# 0f  5  fix-checksum  \ Intermediate checksum
;
