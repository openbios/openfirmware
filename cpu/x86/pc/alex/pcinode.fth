\ See license at end of file
purpose: PCI bus package

\ XXX need slot-names property
[ifdef] notdef
h# 1000 encode-int  " slave-only" property
h# 1800 encode-int			\ Mask of implemented add-in slots
" PCI-1"           encode-string encode+
" PCI-2"           encode-string encode+
" PCI-3"           encode-string encode+

" slot-names" property
[then]

also forth definitions

" 0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f,10,11,12,13,14,15,16,17,18,19,1a,1b,1c,1d,1e,1f"
   dup  config-string pci-probe-list

previous definitions

h# 1000.0000 to first-mem		\ Avoid RAM at low addresses
h# 2000.0000 to mem-space-top
h# 0000.8000 to first-io		\ Avoid mappings established by BIOS

\ Configuration mechanism #1 as defined in the PCI spec.
: config-setup  ( config-adr -- vaddr )
   \ Bit 31 ("enable") must be 1, bits 30:24 ("reserved") must be 0,
   \ bits 1:0 must be 0.
   dup h# ff.fffc and  h# 8000.0000 or  h# cf8 pl!  ( config-adr )

   3 and  h# cfc +  \ Merge in the byte selector bits
;

: config-b@  ( config-adr -- b )  config-setup pc@  ;
: config-w@  ( config-adr -- w )  config-setup pw@  ;
: config-l@  ( config-adr -- l )  config-setup pl@  ;
: config-b!  ( b config-adr -- )  config-setup pc!  ;
: config-w!  ( w config-adr -- )  config-setup pw!  ;
: config-l!  ( l config-adr -- )  config-setup pl!  ;

: init  ( -- )  ;

\ Determine the parent interrupt information (the "interrupt line" in PCI
\ parlance) from the child's "interrupt pin" and the child's address,
\ returning "int-line true" if the child's interrupt line register should
\ be set or "false" otherwise.
: assign-int-line  ( phys.hi.func INTx -- irq true )
   \ Reiterate the value that is already in the int line register,
   \ which was presumably placed there by the BIOS
   drop  h# 3c +  config-b@  true
;

\ The io-base handling really ought to be in the root node, but
\ that would require more changes than I'm willing to do at present.
warning @ warning off
: map-out  ( vaddr size -- )
   over io-base u>=  if  2drop exit  then  ( vaddr size )
   map-out                                 ( )
;   
warning !

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
