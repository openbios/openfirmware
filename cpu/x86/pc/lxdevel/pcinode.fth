\ See license at end of file
purpose: PCI bus package

h# 0000 encode-int  " slave-only" property
h# 0000 encode-int			\ Mask of implemented add-in slots
" slot-names" property

also forth definitions

 " f" dup  config-string pci-probe-list

previous definitions

\ These are here for completeness, but won't be used because we don't
\ do dynamic address assignment on this system.
h# 1000.0000 to first-mem		\ Avoid RAM at low addresses
h# 2000.0000 to mem-space-top
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
