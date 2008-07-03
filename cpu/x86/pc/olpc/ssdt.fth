purpose: Make dynamic SSDT with NAND partition info

h# 1.0000.0000. 2constant nand-size

h# 100 circular-stack: acpi-stack

: acpi-nameseg  ( $ -- )
   4 min
   tuck  bounds ?do  i c@ c,  loop   ( len )
   4 swap  ?do  [char] _ c,  loop
;
: acpi-name  ( $ -- )  8 c, acpi-nameseg  ;

\needs le-w,  : le-w,  ( w -- )  wbsplit  swap c, c,  ;
: acpi-byte  ( b -- )  h# a c,  c,  ;
: acpi-word  ( w -- )  h# b c,  le-w,  ;
: acpi-dword  ( l -- )  h# c c,  le-l,  ;
: acpi-qword  ( l -- )  h# e c,  swap le-l, le-l,  ;
: acpi-string  ( $ -- )  h# d c,  bounds  ?do  i c@ c,  loop  0 c,  ;

\ This always uses the 2-byte form of pkglen (max len 4K) and
\ a 2-byte buffer size.  That potentially wastes a couple of
\ bytes for short buffers, but the code to optimize it would
\ cost more space than the typical savings.
: buffer{  ( n -- )
   h# 11 c,
   here acpi-stack push
   0 le-w,    \ PkgLength (2-byte form, max 4K bytes)
   h# b c,    \ Word Prefix for Buffer Size 
   0 le-w,    \ Buffer Size
;
: }buffer  ( -- )
   acpi-stack pop                    ( pkg-len-adr )
   here over -                       ( pkg-len-adr pkg-len )
   \ Set first byte containing pkglen byte count and low 4 bits
   2dup h# f and h# 40 or  swap c!   ( pkg-len-adr pkg-len )
   \ Set second byte containing bits 11..4
   2dup 4 rshift  swap 1+ c!         ( pkg-len-adr pkg-len )
   \ Set buffer size word
   5 -  swap 3 + le-w!
;

: pkg3{  ( -- )
   here acpi-stack push
   0 c, 0 c, 0 c,   \ 3-byte length
;

: }pkg3  ( -- )
   acpi-stack pop          ( start )
   here over -                      ( start len )
   2dup h# f and h# 80 or  swap c!  ( start len )
   4 rshift swap 1+ le-w!           ( )
;
: acpi-namepath  ( path$ -- )
   dup 0=  if  2drop exit  then

   over c@  [char] \ =  if        ( path$ )
      [char] \ c,                 ( path$ )
      1 /string                   ( path$' )
   then                           ( path$ )

   begin                          ( path$ )
      dup 0=  if  2drop exit  then
      over c@  [char] ^  =
   while                          ( path$ )
      [char] ^ c,                 ( path$ )
      1 /string                   ( path$' )
   repeat                         ( path$ )

   dup 0=  if  2drop 0 c,  exit   then       \ NullName format

   [char] . left-parse-string     ( rem$ name0$ )
   2 pick 0=  if                  ( null$ name0$ )
      \ One name component
      acpi-nameseg  2drop exit  
   then                           ( rem$ name0$ )

   2>r                            ( rem$ r: name0$ )
   [char] . left-parse-string     ( rem$' name1$ r: name0$ )
   2 pick 0=  if                  ( rem$ name1$ r: name0$ )
      \ DualNamePath format
      h# 2e c,                    ( rem$ name1$ r: name0$ )
      2r> acpi-nameseg            ( rem$ name1$ )
      acpi-nameseg                ( rem$ )
      2drop exit  
   then                           ( rem$ name1$ r: name0$ )

   \ MultiNamePath format
   h# 2f c,                       ( rem$ name1$ r: name0$ )
   2r>                            ( rem$ name1$ name0$ )

   here >r                        ( rem$ name1$ name0$ r: 'segcount )
   2 c,                           ( rem$ name1$ name0$ r: 'segcount )
   acpi-nameseg acpi-nameseg      ( rem$ )
   begin  dup  while              ( rem$ )
      [char] . left-parse-string  ( rem$' name$ )
      dup  0=  abort" Bad ACPI Path" cr
      acpi-nameseg                ( rem$ )
      r@ c@ 1+ r@ c!              ( rem$ )
   repeat                         ( rem$ )
   2drop
   r> drop
;

: scope{  ( path$ -- )  h# 10 c,   pkg3{  acpi-namepath  ;
: }scope  ( -- )  }pkg3  ;
: device{  ( name$ -- )  h# 5b c, h# 82 c,  pkg3{  acpi-nameseg  ;
: }device  ( -- )  }pkg3  ;

: large-item{  ( type -- )
   h# 80 or c,
   here acpi-stack push  0 le-w,  
;
: }large-item  ( -- )
   acpi-stack pop  here over -  2-  swap le-w!  
;


: resource{  ( -- )
   buffer{
   here acpi-stack push
;

: }resource  ( -- )
   acpi-stack pop          ( start )
   here over -             ( start len )
   0 -rot  bounds ?do  i c@ +  loop  ( sum )
   negate h# ff and        ( checksum )
   h# 79 c,  c,            ( )
   }buffer
;

: acpi-unicode  ( $ -- )  buffer{  bounds  ?do  i c@ le-w,  loop  0 le-w,  }buffer  ;

: acpi-int  ( n -- )
   dup -1 1 between  if  c, exit  then
   dup h# 100 < if  acpi-byte exit  then
   dup h# 10000 <  if  acpi-word exit  then
   acpi-dword
;


0 value ssdt

: ssdt{  ( -- r: ssdt )
   here to ssdt
   " SSDT" $,      \ Signature
   h# 00000000 l,  \ Length, patched later
   3 c,            \ Revision
   0 c,            \ Checksum, patched later
   " OLPC  " $,    \ OEM ID
   " XO-1    " $,  \ OEM Table ID
   h# 00000100 l,  \ OEM Revision
   " OLPC" $,      \ Creator
   h# 00000100 l,  \ Creator Revision
;
: }ssdt  ( -- )
   ssdt  here over -   ( table-adr len )
   2dup swap 4 + l!    ( table-adr len )  \ Set length
   9 fix-checksum
;
: fixed-qword-space  ( d.begin d.len consumer? oem-id -- )
   c,                       ( d.begin d.len consumer? )
   1 and h# c or c,         ( d.begin d.len )
   0 c,                     ( d.begin d.len )  \ Type-specific flags
   0. d,                    ( d.begin d.len )  \ Granularity
   2over d,                 ( d.begin d.len )  \ Min
   2swap 2over d+ 1. d- d,  ( d.len )          \ Max
   0. d,                    ( d.len )          \ Offset
   d,                                          \ Length
;
h# c0 constant resource-id
0 constant producer
1 constant consumer
0 value next-partition#
: make-partition  ( d.start d.len name$ boot-status -- )
   next-partition# <# u# " PRT" hold$ u#> device{     ( d.s d.l name$ stat )
      dup 0>=  if                                     ( d.s d.l name$ stat )
         " BTS" acpi-name  acpi-int                   ( d.s d.l name$ )
      else                                            ( d.s d.l name$ stat )
         drop                                         ( d.s d.l name$ )
      then                                            ( d.s d.l name$ )
      " _ADR" acpi-name  next-partition# acpi-int     ( d.s d.l name$ )
      " _UID" acpi-name  acpi-unicode                 ( d.s d.l )
      " _CRS" acpi-name
      resource{   h# a large-item{                    ( d.s d.l )
         consumer  resource-id  fixed-qword-space     ( )
      }large-item  }resource                          ( )
   }device                                            ( )
   next-partition# 1+ to next-partition#
;
4 constant #bbt-blocks
h# 20000 value /eblock
: bbt-partition  ( -- d.start d.len )
   nand-size  #bbt-blocks /eblock um*  d-   ( d.start )
   #bbt-blocks /eblock um*                  ( d.len )
;
: win-partition  ( -- d.start d.len )     h# 0.0408.0000.  h# 0.a000.0000.  ;
: make-partitions  ( -- )
   \ XXX this should be automated from the partition map
   bbt-partition  " BadBlockTable"  -1  make-partition
   h#  10.0000.  h#  200.0000.  " WindowsBoot0"    1  make-partition
   h# 210.0000.  h#  200.0000.  " WindowsBoot1"    0  make-partition
   h# 410.0000.  h# a000.0000.  " WindowsSystem"  -1  make-partition
;
: make-ssdt  ( -- )
   0 to next-partition#
   ssdt{
      " \_SB.PCI0" scope{
         " NF0" device{
            " _ADR" acpi-name  h# c.0000 acpi-int
            " _STA" acpi-name  h# f acpi-int
            " _CRS" acpi-name
            resource{
               h# a large-item{
                  0.  nand-size  producer  resource-id  fixed-qword-space
               }large-item
            }resource

            make-partitions

         }device
      }scope
   }ssdt
;

make-ssdt
writing test.aml
ssdt  here over -  ofd @ fputs
ofd @ fclose
