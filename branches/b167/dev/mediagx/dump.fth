\ See license at end of file
0 value dump-virt
0 value dump-adr

: ll  ( idx -- )  dup f and 0=  if  cr u. ."   "  else  drop  then  ;
: dump-pci  ( cfg-adr len -- )  bounds do i ll i config-l@ u. 4  +loop  ;
: dump-mio  ( mio-base tbl-adr len -- )
   0 do  dup i + c@ 2 pick + dup u. rl@ u. cr  loop  2drop
;

: gx-cfg-table  ( -- adr len )
   " "(20 b0 b1 b2 b3 b8 b9 ba bb bc bd c1 c2 c3 cd ce cf e8 eb fe ff)"
;
: gx-ibiur-table  ( -- adr len )
   " "(00 04 08 0c)"
;
: gx-gpr1-table  ( -- adr len )
   " "(00 04 08 0c 10 14 20 24 28 2c 40 44)"
;
: gx-gpr2-table  ( -- adr len )
   " "(00 04 08 0c 10 14)"
;
: gx-dcr-table  ( -- adr len )
   " "(00 04 08 0c 10 14 18 20 24 28 30 34 38 3c 40 44 48 4c 50 54 58 5c 60 68 70 74 78 7c)"
;
: gx-mcr-table  ( -- adr len )
   " "(00 04 08 0c 14 18 1c)"
;
: gx-pmr-table  ( -- adr len )
   " "(00 04 08 0c)"
;

: dump-gx  ( -- )
   cr ." MediaGX PCI config registers:" cr
   0 50 dump-pci
   cr ." MediaGX config registers:" cr
   gx-cfg-table 0  do  dup i + c@ dup u. cfg@ u. cr  loop  drop
   cr ." MediaGX internal bus unit registers:" cr
   ibiur-base gx-ibiur-table  dump-mio
   cr ." MediaGX graphics pipeline registers:" cr
   gpr-base gx-gpr1-table  dump-mio
   gpr-base 100 + gx-gpr2-table  dump-mio
   cr ." MediaGX display controller registers:" cr
   dcr-base gx-dcr-table  dump-mio
  cr ." MediaGX memory controller registers:" cr
   mcr-base gx-mcr-table  dump-mio
   cr ." MediaGX power management registers:" cr
   pmr-base gx-pmr-table  dump-mio
;

: dump-io-regs  ( len bar -- )
   config-l@ fff0 and swap bounds  do  i ll i pc@ u.  loop
;
: dump-mio-regs  ( len offset bar -- )
   config-l@ ffff.fff0 and + dup to dump-adr
   over root-map-in to dump-virt
   dump-adr f and 0<>  if  cr dump-adr u. ."   "  then
   dup 0  ?do  dump-adr i + ll dump-virt i + rl@ u. 4  +loop
   dump-virt swap root-map-out
;

: dump-5520  ( -- )
   cr ." 5520 PCI config registers:" cr
   9000 100 dump-pci
   cr ." Audio interface registers:" cr
   60 9010 dump-io-regs
   cr ." SMI registers:" cr
   20 9014 dump-io-regs
   cr ." IDE registers:" cr
   10 9018 dump-io-regs
   cr ." Video registers:" cr
   24 0 901c dump-mio-regs
   cr ." Clock registers:" cr
   28 e00 901c dump-mio-regs
;

: dump-5530  ( -- )
   cr ." 5530 PCI config registers:" cr
   9000 100 dump-pci

   cr ." 5530 Function 1: SMI status and ACPI timer:" cr
   9100 14 dump-pci
   cr ." SMI status and ACPI timer registers:" cr
   50 0 9110 dump-mio-regs

   cr ." 5530 Function 2: IDE controller:" cr
   9200 24 dump-pci
   cr ." IDE controller registers:" cr
   40 9220 dump-io-regs

   cr ." 5530 Function 3: VSA audio:" cr
   9300 14 dump-pci
   cr ." VSA audio registers:" cr
   50 0 9310 dump-mio-regs

   cr ." 5530 Function 4: Video controller:" cr
   9400 14 dump-pci
   cr ." Video controller registers:" cr
   20 0 9410 dump-mio-regs
   0c 24 9410 dump-mio-regs
;

: dump-usb  ( -- )
   cr ." USB PCI config registers:" cr
   9800 50 dump-pci
;

warning @ warning off
: dump-all  ( -- )
[ifdef] dump-all  dump-all  [then]
   dump-gx
   9000 config-l@ case
      0002.1078 of  dump-5520  endof
      0100.1078 of  dump-5530  endof
   endcase
   dump-usb
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
