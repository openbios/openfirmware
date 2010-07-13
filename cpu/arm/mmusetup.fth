\ See license at end of file
purpose: Establish the initial values for the MMU and virtual lists

\ The code in this file depends in detail on the initial MMU setup
\ established by initmmu.fth

dev /mmu
: st-section  ( -- va )  st-va /section round-down  ;

: st-end  ( -- )  st-va h# 4000 +  ;

: >p  ( va -- pa )
   dup section@ h# fff0.0000 and  ( va pa-base )
   swap h# f.f000 and  or
;

: (initial-mmu-setup)  ( -- )	\ Locate the section table
   fw-virt-base h# 1f.c000 +  to st-va
\   fw-virt-base h# ef.c000 +  to st-va
;
' (initial-mmu-setup) to initial-mmu-setup

: (initial-claim)  ( -- )
   0              pagesize          claim-virtual drop   \ Trap table
   fw-virt-base   memtop @ over -   claim-virtual drop   \ Firmware region
   st-va          st-end over -     claim-virtual drop   \ Section table
;
' (initial-claim) to initial-claim

: (initial-map)  ( -- )
   0 >p            0            pagesize          h# c map   \ Trap vectors R/O
\  fw-virt-base >p fw-virt-base memtop @ over -     -1 map   \ Firmware 
   fw-virt-base >p fw-virt-base /section            -1 map   \ Firmware 

   \ Formally establish the pre-existing mapping so it can be released later
   st-va >p       st-section   /section         h# c00 map   \ section table

   \ Move the section table virtual address to the pocket just above the
   \ Forth stacks; typically f70f.c000.
   st-section                                     ( old-st-va-bas )
   st-va >p       memtop @     h# 4000          h# c00 map   \ section table
   memtop @ to st-va                              ( old-st-va-bas )
   ( old-st-va )               /section     unmap   	 \ Release old mapping

[ifdef] io-base
   io-base  io-base  /section -1  map
[then]
;
' (initial-map) to initial-map

: vectors-rw  ( -- )  0 >p  0  pagesize  h# c0c  modify  ;
: vectors-ro  ( -- )  0 >p  0  pagesize  h#   c  modify  ;
: mmu-install-handler  ( handler trap# -- )
   vectors-rw hw-install-handler vectors-ro
;

also forth definitions
: unmap-temp-io  ( virt -- )
   dup io-base =  if  drop  else  /section  unmap  then
;
previous definitions
device-end


\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
