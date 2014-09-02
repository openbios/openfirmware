purpose: Driver for National PC87307 "Super IO" chip with Plug 'n Play
\ See license at end of file

hex
: sio-b@  ( index -- b )  h# 15c pc!  h# 15d pc@  ;
: sio-b!  ( b index -- )  h# 15c pc!  h# 15d pc!  ;
: select-sio-dev  ( device# -- )  7 sio-b!  ;

nuser superio-node

0 0 " i15c" " /isa" begin-package	\ SuperI/O configuration registers
" configuration" device-name
" NSM,PC87307" model
my-address my-space 2  reg
" configuration" device-type

0 0 encode-bytes
   " NSM,PC87307-configuration" encode-string encode+
   " pnp-configuration"         encode-string encode+
" compatible" property

headerless
: enable-sio-dev  ( device# -- )  select-sio-dev  1 h# 30 sio-b!  ;

: ps2-floppy   ( -- )  h# 21 sio-b@  4 invert and  h# 21 sio-b!  ;
\ : at-floppy   ( -- )  h# 21 sio-b@  4 or  h# 21 sio-b!  ;

\ Doubly-indirect access to programmable chip select control registers
: pcs@  ( index -- data )  h# 23 sio-b!  h# 24 sio-b@  ;
: pcs!  ( data index -- )  h# 23 sio-b!  h# 24 sio-b!  ;

headers

\ This table converts the "interrupt type" field in Open Firmware ISA
\ "interrupts" property to the corresponding code for Plug N Play
\ interrupt configuration registers.
    \ OFW#/type  0/low level  1/high level  2/falling edge  3/rising edge
create int-map   1 c,         3 c,          0 c,            2 c,

: set-interrupt  ( level mode int# device# -- )
   select-sio-dev                ( level mode int# )
   h# 70 swap wa+                ( level mode pnp-reg# )
   swap  int-map + c@  swap      ( level pnp-mode pnp-reg# )
   tuck 1+ sio-b!  sio-b!        ( )
;

: set-dma  ( channel dma# device# -- )
   select-sio-dev                ( channel dma# )
   h# 74 swap ca+                ( channel pnp-reg# )
   sio-b!                        ( )
;

: set-reg  ( address space size port# device# -- )
   select-sio-dev                      ( address space size port# )
   h# 60 swap wa+ >r                   ( address space size r: pnp-reg# )
   swap  1 and  if  \ I/O space        ( address size r: pnp-reg# )
      drop                             ( address r: pnp-reg# )
      wbsplit r@ sio-b!  r> 1+ sio-b!  ( )
   else             \ Memory space     ( address size r: pnp-reg# )
      \ XXX implement me
      \ The Memory configuration registers are at 40-44, 48-4d, 50-54, 58-5d
      \ See /fw/doc/standards/pnp/isapnp.{doc,ps}
      true abort" ISA memory space configuration not yet supported"
   then
;

[ifdef] notdef
: set-memory  ( address size device# -- )
\ XXX implement me
;
[then]

0 value device#
: set-configuration  ( -- )
   " device#" get-property  if  exit  then        ( adr len )
   get-encoded-int to device#                     ( )

   " reg" get-property  0=  if                    ( adr len )
      \ XXX we must maintain a separate count of I/O and memory descriptors
      \ There can be up to 8 I/O ports and up to 4 memory ranges
      d# 12 0  do                                 ( adr len )
         dup 3 /l* <  if  leave  then             ( adr len )
         decode-phys 2>r  decode-int  2r> rot     ( adr len phys.lo,hi size )
         i device#  " set-reg" superio-node @ $call-method
      loop                                        ( adr len )
      2drop                                       ( )
   then                                           ( )

   " interrupts" get-property  0=  if             ( adr len )
      2 0  do                                     ( adr len )
         dup 2 /l* <  if  leave  then             ( adr len )
         2 decode-ints  swap                      ( adr' len' level mode )
         i device#  " set-interrupt" superio-node @ $call-method
      loop                                        ( adr len )
      2drop                                       ( )
   then                                           ( )

   " dma" get-property  0=  if                    ( adr len )
      2 0  do                                     ( adr len )
         dup 5 /l* <  if  leave  then             ( adr len )
         decode-int  i device#  " set-dma" superio-node @ $call-method
         4 0  do  decode-int drop  loop           ( adr' len' )
      loop                                        ( adr len )
      2drop                                       ( )
   then                                           ( )

   device# " enable-sio-dev" superio-node @ $call-method
;

: open  ( -- okay? )  true  ;
: close  ( -- )  ;

also forth definitions
: configure-superio  ( -- )
   " /isa/configuration" open-dev superio-node !
   " /isa"  ['] set-configuration  scan-subtree
;
warning @ warning off
: stand-init-io
   stand-init-io
   configure-superio
;
warning !
previous definitions

end-package

fload ${BP}/dev/pci/isaall.fth			\ The usual ISA devices

\ Declare the Super-I/O chip type in the child nodes
dev /isa/parallel
" NSM,PC87307" model
4 " device#" integer-property
\ XXX We should configure this device in ECP mode so we can set
\ it to level sensitive
7 encode-int  3 encode-int encode+    " interrupts" property
device-end

[ifndef] no-com1-node
dev /isa/serial@3f8
" NSM,PC87307" model
6 " device#" integer-property
4 encode-int  1 encode-int encode+    " interrupts" property
device-end
[then]

[ifndef] no-com2-node
dev /isa/serial@2f8
" NSM,PC87307" model
5 " device#" integer-property
3 encode-int  1 encode-int encode+    " interrupts" property
device-end
[then]

[ifndef] no-floppy-node
dev /isa/fdc
" NSM,PC87307" model
3 " device#" integer-property
6 encode-int  1 encode-int encode+    " interrupts" property
device-end
[then]

dev /isa/8042
0 " device#" integer-property
" NSM,PC87307" model
" interrupts" delete-property
device-end

dev /isa/8042/keyboard
0 " device#" integer-property
1 encode-int  1 encode-int encode+    " interrupts" property
device-end

dev /isa/8042/mouse
1 " device#" integer-property
d# 12 encode-int  1 encode-int encode+    " interrupts" property
device-end

\ Driver for the power management device on the pc87308 sio chip. 

0 0  " i380"  " /isa" begin-package          \ power management node

headerless
" power" device-name
" power" device-type

my-address     my-space  2 encode-reg  " reg" property

8 " device#" integer-property
0 0 encode-bytes
   " NSM,PC87307-power" encode-string encode+
   " pnpNSC,c0f"        encode-string encode+
   " pnpPNP,c02"        encode-string encode+
" compatible" property

0 value power-base

\ Indirect access to power management control registers
: pm@  ( index -- data )  power-base rb!  power-base 1+ rb@  ;
: pm!  ( data index -- )  power-base rb!  power-base 1+ rb!  ;

: open  ( -- flag )
   power-base  0=  if
      my-address my-space 2 " map-in" $call-parent  is power-base
   then
   true
;
: close  ( -- )  ;

also forth definitions

0 value power-node

stand-init: Power
   " /power" open-dev  to power-node
;

previous definitions

end-package

0 0  " i3e0"  " /isa" begin-package          \ gpio node

headerless
" gpio" device-name
" gpio" device-type

my-address     my-space  2 encode-reg  " reg" property

7 " device#" integer-property

0 0 encode-bytes
   " dnard,gpio"       encode-string encode+
   " NSM,PC87307-gpio" encode-string encode+
   " pnpNSC,c02"       encode-string encode+
   " pnpPNP,c02"       encode-string encode+
" compatible" property

0 value gpio-base 

: map-gpio  ( -- )
   my-address my-space 8 " map-in" $call-parent  is gpio-base
;

: gpio@  ( index -- n )  gpio-base + rb@  ;
: gpio!  ( n index -- )  gpio-base + rb!  ;

0 constant gpio-data
1 constant gpio-direction
2 constant output-type
3 constant pull-up-control

: open  ( -- flag )   
   gpio-base 0=  if
      map-gpio

      \ This lets "reset-all" work even in the early phases of stand-init
      power-node 0=  if  " /power" open-dev to power-node  then

      \ init the power management to turn on gpio
      h# 01 " pm@" power-node $call-method   h# 80 or
      h# 01 " pm!" power-node $call-method
   then
   true
;
: close  ( -- )   ;
: init  ( -- )  ;   \ Redefine as needed
 
0 encode-int  " #size-cells" property
0 encode-int  " #address-cells" property
: decode-unit  ( adr len -- )  ;
: encode-unit  ( -- adr len )  " "  ;

also forth definitions

0 value gpio-node

stand-init: GPIO
   " /gpio" open-dev  to gpio-node
   " init" gpio-node $call-method
;

previous definitions

end-package


0 0  " i70"  " /isa" begin-package   	\ Real-time clock node
fload ${BP}/dev/ds1385r.fth
2 " device#" integer-property
8 encode-int  0 encode-int encode+    " interrupts" property

also forth definitions
stand-init: RTC
   " /rtc" open-dev  clock-node !
;
previous definitions

end-package
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
