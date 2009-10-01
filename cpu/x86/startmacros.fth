\ See license at end of file

\ Some x86 assembler macros to make it easier to write x86 early
\ startup code.  There are macros to set MSRs to specific values,
\ to set and clear individual MSR bits, to read and write PCI
\ configuration registers with the common CF8/CFC mechanism,
\ and to read and write I/O ports.

\ The code keeps the MSR register number in %ecx, the low 32 bits
\ of the value in %eax, and the high 32 bits in %edx, consistent
\ with the way the rdmsr and wrmsr machine instructions work.

\ The bitset and bitclr operations work on %eax, and the -hi versions
\ work on %edx.

\ The I/O port operations also leave the data in %eax, so you can
\ use bitset and bitclr with them too.

-1 value last-cx
also 386-assembler definitions

\ If you do any direct manipulation of ECX in your startup code,
\ say "forget-msr" afterwards, so the MSR access macro will know
\ that ECX needs to be reloaded.

: forget-msr  -1 to last-cx  ;

\ set-cx is an internal implementation factor used by wmsr and rmsr.
\ It assembles code to put an MSR number in %ecx, optimizing out
\ unnecessary code by remembering what was last put there.

: set-cx  ( reg# -- )
   [ also forth ]
   dup last-cx =  if
      drop
   else
      \ This optimization is dangerous in the face of conditionals
      dup to last-cx
      forget-msr
      [ previous ] # cx mov  [ also forth ]
   then
   [ previous ]
;

\ Read/write an MSR to/from %edx,%eax
: rmsr  ( reg# -- )  set-cx   rdmsr  ;
: wmsr  ( reg# -- )  set-cx   wrmsr  ;

\ These bit operations can be used between "rmsr" and "wmsr"

\ Bit operations on the low 32-bit value in %eax
: bitset  ( mask -- )  # ax or  ;
: bitand  ( mask -- )  # ax and  ;
: bitclr  ( mask -- )  invert  bitand  ;

\ Bit operations on the high 32-bit value in %edx
: bitset-hi  ( mask -- )  # dx or  ;
: bitand-hi  ( mask -- )  # dx and  ;
: bitclr-hi  ( mask -- )  invert  bitand-hi  ;

\ Set an MSR to a verbatim 64-bit value
: set-msr    ( d.val reg# -- )   -rot # dx mov  # ax mov  wmsr  ;

\ Set or clear bits in an MSR (read-modify-write the register)
: bitset-msr ( mask reg# -- )  rmsr  bitset  wrmsr  ;
: bitclr-msr ( mask reg# -- )  rmsr  bitclr  wrmsr  ;

\ Some I/O port operations
\ These could be optimized to generate the immediate forms of in and out
\ for 8-bit port numbers, but it's not worth the trouble because we
\ access very few low-numbered ports.
: port-wb  ( b port# -- )   swap # al mov   # dx mov  al dx out  ;
: port-rb  ( port# -- )  # dx mov  dx al in  ;
: port-ww  ( w port# -- )   swap # ax mov   # dx mov  op: ax dx out  ;
: port-rw  ( port# -- )  ax ax xor  # dx mov  op: dx ax in  ;
: port-wl  ( l port# -- )  swap # ax mov   # dx mov  ax dx out  ;
: port-rl  ( port# -- )  # dx mov  dx ax in  ;

[ifdef] no-port80
: port80  ( byte -- )  drop  ;
[else]
: port80  ( byte -- )  " # al mov  al h# 80 # out" evaluate  ;
[then]

: config-setup  ( config-adr -- )
   [ also forth ]
   dup 3 invert and  h# 8000.0000 or   ( config-adr cf8-value )
   [ previous ]
   #  ax  mov                          ( config-adr )
   h# cf8 #  dx  mov                   ( config-adr )
   ax dx out                           ( config-adr )
   [ also forth ]
   3 and h# cfc or                     ( data-port )
   [ previous ]
   # dx mov
;
: config-wl  ( l config-adr -- )
   config-setup  ( l )
   #  ax  mov
   ax dx out
;
: config-rl  ( config-adr -- )  \ Returns value in EAX
   config-setup
   dx ax in
;
: config-ww  ( w config-adr -- )
   config-setup     ( w )
   op: # ax  mov    ( )
   op: ax dx out
;
: config-rw  ( config-adr -- )  \ Returns value in AX
   config-setup     ( )
   ax ax xor
   op: dx ax in
;
: config-wb  ( b config-adr -- )
   config-setup     ( )
   # al  mov        ( )
   al dx out
;
: config-rb  ( config-adr -- )  \ Returns value in AL
   config-setup     ( )
   ax ax xor
   dx al in
;

: set-base  ( adr -- )  # bx mov  ;
: reg-save  ( offset -- )  [bx] ax mov  ax stos  ;
: reg-restore  ( offset -- )  ax lods  ax  swap [bx]  mov  ;

previous definitions

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
