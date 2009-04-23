\ See license at end of file
purpose: PCI bus package

: preassigned-pci-slot?  ( my-space -- flag )
   h# f.f800 and
   dup h# 800 =  if  drop true exit  then
   drop false
;

0 [if]
   \ Suppress PCI address assignment; use the addresses the BIOS assigned
   patch false true master-probe
   patch noop assign-all-addresses prober
   patch noop clear-addresses populate-device-node
   patch noop clear-addresses populate-device-node
   patch noop temp-assign-addresses find-fcode?
   patch 2drop my-w! populate-device-node
   : or-w!  ( bitmask reg# -- )  tuck my-w@  or  swap my-w!  ;
   patch or-w! my-w! find-fcode?
   patch 2drop my-w! find-fcode?
[then]

[ifdef] addresses-assigned
\   patch false true master-probe
: nonvirtual-probe-state?  ( -- flag )
   my-space preassigned-pci-slot?  if  false  else  probe-state?  then
;
patch nonvirtual-probe-state? probe-state? map-in

\  patch noop assign-all-addresses prober
warning @ warning off
: assign-pci-addr  ( phys.lo phys.mid phys.hi len | -1 -- phys.hi paddr size )
   2dup -1 <>  swap preassigned-pci-slot?  and  if  ( phys.lo phys.mid phys.hi len )
      2swap 2drop    >r                         ( phys.hi r: len )
      dup config-l@  1 invert and  r>           ( phys.hi paddr len )
      exit
   then
   assign-pci-addr
;
warning !

: ?clear-addresses  ( -- )
   my-space preassigned-pci-slot?  if  exit  then  clear-addresses
;
patch ?clear-addresses clear-addresses populate-device-node
patch ?clear-addresses clear-addresses populate-device-node

: ?temp-assign-addresses  ( -- )
   my-space preassigned-pci-slot?  if  exit  then  temp-assign-addresses
;

patch ?temp-assign-addresses temp-assign-addresses find-fcode?

\ These patches leave devices turned on
\ patch 2drop my-w! populate-device-node
\ : or-w!  ( bitmask reg# -- )  tuck my-w@  or  swap my-w!  ;
\ patch or-w! my-w! find-fcode?
\ patch 2drop my-w! find-fcode?
[then]

h# 0000 encode-int  " slave-only" property
h# 0000 encode-int			\ Mask of implemented add-in slots
" slot-names" property

also forth definitions

: pci-probe-list  ( -- adr len )
   " 1,c,f,10,13,14"
;
\    " c,f" dup  config-string pci-probe-list

previous definitions

h# b000.0000 to first-mem
h# c000.0000 to mem-space-top
h# 0000.8000 to first-io		\ Avoid mappings established by BIOS

0 [if]
\ These are here for completeness, but won't be used because we don't
\ do dynamic address assignment on this system.
h# 1000.0000 to first-mem		\ Avoid RAM at low addresses
h# 2000.0000 to mem-space-top
h# 0000.8000 to first-io		\ Avoid mappings established by BIOS
[then]

\ Determine the parent interrupt information (the "interrupt line" in PCI
\ parlance) from the child's "interrupt pin" and the child's address,
\ returning "int-line true" if the child's interrupt line register should
\ be set or "false" otherwise.
: assign-int-line  ( phys.hi.func INTx -- irq true )
   \ Reiterate the value that is already in the int line register,
   \ which was placed there by lower level init code
   drop  h# 3c +  config-b@  true
;

0 value interrupt-parent

1  " #interrupt-cells" integer-property
0 0 encode-bytes  0000.ff00 +i  0+i  0+i  7 +i  " interrupt-map-mask" property

: +map  ( adr len dev# int-pin# int-level -- adr' len' )
   >r >r                  ( $ dev# R: level pin )
   +i                     ( $' R: level pin )
   0+i 0+i  r> +i         ( $' R: level )
   interrupt-parent +i    ( $' R: level )
   r> +i  0 +i            ( $' )   \ 0 is active low, level senstive for ISA
;

external

: make-interrupt-map  ( -- )
   " /isa/interrupt-controller" find-package  0=  if  exit  then  to interrupt-parent

   0 0 encode-bytes                    ( prop$ )

   h# 10000 0  do                      ( prop$ )
      i h# 3d + config-b@              ( prop$ pin# )
      dup 0<>  over h# ff <>  and  if  ( prop$ pin# )
         i h# 3c + config-b@           ( prop$ pin# level )
         i -rot  +map                  ( prop$' )
      else                             ( prop$ pin# )
         drop                          ( prop$ )
      then                             ( prop$ )
   h# 100 +loop                        ( prop$ )
   " interrupt-map" property           ( )
;

also known-int-properties definitions
\ In some systems the number of interrupt-map ints is variable,
\ but on OLPC, the only node with an interrupt-map is PCI.
: interrupt-map  7  ;
: interrupt-map-mask  4  ;
previous definitions

\ Just use the global versions
warning @ warning off
: config-b@  ( config-adr -- b )  config-b@  ;
: config-w@  ( config-adr -- w )  config-w@  ;
: config-l@  ( config-adr -- l )  config-l@  ;
: config-b!  ( b config-adr -- )  config-b!  ;
: config-w!  ( w config-adr -- )  config-w!  ;
: config-l!  ( l config-adr -- )  config-l!  ;
warning !

\ The io-base handling really ought to be in the root node, but
\ that would require more changes than I'm willing to do at present.
warning @ warning off
: map-out  ( vaddr size -- )
   over io-base u>=  if  2drop exit  then  ( vaddr size )
   map-out                                 ( )
;   
warning !

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
