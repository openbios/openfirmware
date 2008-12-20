purpose: System Control Coprocessor access words
\ See license at end of file

hex
code scc-id@            ( -- n )   psh tos,sp  mrc p15,0,tos,cr0,cr0,0  c;
code control@           ( -- n )   psh tos,sp  mrc p15,0,tos,cr1,cr0,0  c;
code ttbase@            ( -- n )   psh tos,sp  mrc p15,0,tos,cr2,cr0,0  c;
code domain-access@     ( -- n )   psh tos,sp  mrc p15,0,tos,cr3,cr0,0  c;
code fault-status@      ( -- n )   psh tos,sp  mrc p15,0,tos,cr5,cr0,0  c;
code fault-address@     ( -- n )   psh tos,sp  mrc p15,0,tos,cr6,cr0,0  c;

code control!           ( n -- )   mcr p15,0,tos,cr1,cr0,0  pop tos,sp  c;
code ttbase!            ( n -- )   mcr p15,0,tos,cr2,cr0,0  pop tos,sp  c;
code domain-access!     ( n -- )   mcr p15,0,tos,cr3,cr0,0  pop tos,sp  c;
code fault-status!      ( n -- )   mcr p15,0,tos,cr5,cr0,0  pop tos,sp  c;
code fault-address!     ( n -- )   mcr p15,0,tos,cr6,cr0,0  pop tos,sp  c;
code flush-i&d$         ( -- )     mcr p15,0,r0,cr7,cr7,0  c;
code flush-i$           ( -- )     mcr p15,0,r0,cr7,cr5,0  c;
code flush-d$           ( -- )     mcr p15,0,r0,cr7,cr6,0  c;
code flush-d$-entry     ( va -- )  mcr p15,0,tos,cr7,cr6,1   pop tos,sp  c;
code clean-d$-entry     ( va -- )  mcr p15,0,tos,cr7,cr10,1  pop tos,sp  c;
code drain-write-buffer ( -- )     mcr p15,0,r0,cr7,cr10,4  c;
code flush-i&d-tlb      ( -- )     mcr p15,0,r0,cr8,cr7,0  c;
code flush-i-tlb        ( -- )     mcr p15,0,r0,cr8,cr5,0  c;
code flush-d-tlb        ( -- )     mcr p15,0,r0,cr8,cr6,0  c;
code flush-d-tlb-entry  ( va -- )  mcr p15,0,tos,cr8,cr6,1  pop tos,sp  c;

code enable-odd-lfsr    ( -- )     mcr p15,0,r0,cr15,cr1,1  c;
code enable-even-lfsr   ( -- )     mcr p15,0,r0,cr15,cr2,1  c;
code clear-lfsr         ( -- )     mcr p15,0,r0,cr15,cr4,1  c;
code lfsr-to-r14        ( -- )     mcr p15,0,r0,cr15,cr8,1  c;
code fast-clock         ( -- )     mcr p15,0,r0,cr15,cr1,2  c;
code slow-clock         ( -- )     mcr p15,0,r0,cr15,cr2,2  c;
code disable-mclk       ( -- )     mcr p15,0,r0,cr15,cr4,2  c;
code wait-for-interrupt ( -- )     mcr p15,0,r0,cr15,cr8,2  c;

: ttbase  ( -- n )  ttbase@ h# 3ff invert and  ;

: .control  ( -- )  control@  " i..rsb...wcam" show-bits  ;

d# 32 constant /cache-line
: cache-bounds  ( adr len -- end start )
   bounds  swap /cache-line round-up  swap /cache-line round-down
;
: invalidate-cache-range  ( adr len -- )
   dup  if  flush-i$  then
   cache-bounds  ?do  i flush-d$-entry  /cache-line +loop
;
d# 32 constant /cache-line
: flush-d$-range  ( adr len -- )
   bounds  swap /cache-line round-up  swap /cache-line round-down   ?do
      i clean-d$-entry  i flush-d$-entry
   /cache-line +loop
;

\ System-dependent function to flush the entire cache
\ (In normal ARM nomenclature, as used by most of the words in this file,
\ "flush" means "invalidate without ensuring that cached data has been
\ written to memory", while "clean" means "ensure that cached data has been
\ written to memory".  In normal Open Firmware parlance, "invalidate" means
\ the former and "flush" the latter.  "flush-cache" is a generic Open Firmware
\ operation, so it uses the Open Firmware nomenclature.
defer flush-cache  ' noop to flush-cache

: icache-on   ( -- )  flush-i$  control@  h# 1000 or          control!  ;
: icache-off  ( -- )            control@  h# 1000 invert and  control!  ;
: dcache-on   ( -- )  flush-d$  control@        4 or          control!  ;
: dcache-off  ( -- )
   control@  dup 4 and  if
      flush-cache
      4 invert and  control!
   else
      drop
   then
;

: write-buffer-on   ( -- )  control@  8 or          control!  ;
: write-buffer-off  ( -- )
   drain-write-buffer control@  8 invert and  control!
;

: stand-sync-cache  ( adr len -- )
   cache-bounds  ?do  i clean-d$-entry  /cache-line +loop
   drain-write-buffer
   flush-i$
;
: stand-init-io  ( -- )
   stand-init-io
   ['] stand-sync-cache to sync-cache
;

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
