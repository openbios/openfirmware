\ See license at end of file
purpose: PCI bus package

[ifdef] addresses-assigned
\   patch false true master-probe
: nonvirtual-probe-state?  ( -- flag )
   my-space virtual-pci-slot?  if  false  else  probe-state?  then
;
patch nonvirtual-probe-state? probe-state? map-in

\  patch noop assign-all-addresses prober
: assign-pci-addr  ( phys.lo phys.mid phys.hi len | -1 -- phys.hi paddr size )
   2dup -1 <>  swap virtual-pci-slot?  and  if  ( phys.lo phys.mid phys.hi len )
      2swap 2drop    >r                         ( phys.hi r: len )
      dup config-l@  1 invert and  r>           ( phys.hi paddr len )
      exit
   then
   assign-pci-addr
;

: ?clear-addresses  ( -- )
   my-space virtual-pci-slot?  if  exit  then  clear-addresses
;
patch ?clear-addresses clear-addresses populate-device-node
patch ?clear-addresses clear-addresses populate-device-node

: ?temp-assign-addresses  ( -- )
   my-space virtual-pci-slot?  if  exit  then  temp-assign-addresses
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

 " 2,3,4,5,6,7,8,9,a,b,c,d,e,f" dup  config-string pci-probe-list

previous definitions

h# b000.0000 to first-mem
h# c000.0000 to mem-space-top
h# 0000.8000 to first-io		\ Avoid mappings established by BIOS

\ Determine the parent interrupt information (the "interrupt line" in PCI
\ parlance) from the child's "interrupt pin" and the child's address,
\ returning "int-line true" if the child's interrupt line register should
\ be set or "false" otherwise.
: assign-int-line  ( phys.hi.func INTx -- irq true )
   \ Reiterate the value that is already in the int line register,
   \ which was placed there by lower level init code
   drop  h# 3c +  config-b@  true
;

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
