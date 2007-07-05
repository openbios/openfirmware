purpose: System-specific portions of PCI bus package
\ See license at end of file

dev /pci

d# 66,666,666 encode-int " clock-frequency"  property

headers

\ These package methods use the global versions of the configuration
\ access words.  This is appropriate only for single-PCI-bus systems.

: config-l@  ( config-addr -- l )  config-l@  ;
: config-l!  ( l config-addr -- )  config-l!  ;
: config-w@  ( config-addr -- w )  config-w@  ;
: config-w!  ( w config-addr -- )  config-w!  ;
: config-b@  ( config-addr -- c )  config-b@  ;
: config-b!  ( c config-addr -- )  config-b!  ;

\  ------PCI Address-------  ---Host Address--  -- size --
\ phys.hi    .mid      .low   phys.hi   .lo     .hi    .lo

.( XXX - ranges properties for PCI node) cr
0 0 encode-bytes
0100.0000 +i  0+i         0+i  c800.0000 +i     0+i 0800.0000 +i  \ PCI I/O
0200.0000 +i  0+i         0+i  a000.0000 +i     0+i 2000.0000 +i  \ PCI Mem
   " ranges" property

headers

: init  ( -- )
   \ Could do interrupt routing here
;

[ifdef] notyet
headerless

\ Determine the parent interrupt information (the "interrupt line" in PCI
\ parlance) from the child's "interrupt pin" and the child's address,
\ returning "int-line true" if the child's interrupt line register should
\ be set or "false" otherwise.

\ This table describes the wiring of PCI interrupt pins at the PCI slots
\ to PIRQ inputs on the 82378zb chip.  The wiring varies from slot to slot.

create slot-map

\  Pin A  Pin B  Pin C  Pin D     Dev#

    2 c,  ff c,  ff c,  ff c,   \  c SCSI
   ff c,  ff c,  ff c,  ff c,   \  d nothing
    0 c,  ff c,  ff c,  ff c,   \  e Ethernet
    3 c,  ff c,  ff c,  ff c,   \  f Display
    0 c,   1 c,   2 c,   2 c,   \ 10 Slot 1  (the riser connects INTC and INTD)
    1 c,   2 c,   2 c,   0 c,   \ 11 Slot 2  (the riser connects INTC and INTD)
    2 c,   2 c,   0 c,   1 c,   \ 12 Slot 3  (the riser connects INTC and INTD)

: pin,dev>pirq  ( pin# dev# -- true | pirq# false )
   dup  c 12 between 0=  if  2drop true exit  then   ( int-pin dev# )

   c - 4 * +  slot-map + c@			     ( pirq#|ff )
   dup h# ff  =  if  drop true  else  false  then
;

headers

: assign-int-line  ( phys.hi.func int-pin -- false | int-line true )
   dup 0=  if  2drop false  exit  then               ( phys.hi.func int-pin# )
   1-  swap d# 11 rshift  h# 1f and                  ( int-pin0 dev# )

   \ Bail out for non-existent device IDs
   pin,dev>pirq  if  false exit  then                ( pirq# )

   pirq>irq                                          ( irq# )

   true
;

h# 700 encode-int				\ Mask of implemented slots
" PCI 1" encode-string encode+
" PCI 2" encode-string encode+
" PCI 3" encode-string encode+  " slot-names" property
[then]

device-end

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
