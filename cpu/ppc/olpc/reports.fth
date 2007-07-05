purpose: Simple serial output routines for debugging startup code
\ See license at end of file

transient
\ Assembler macro to assemble code to set the location "isa-adr" in
\ ISA I/O space to the value "data".  Assumes that r1 is already set
\ to the base addess of ISA I/O space.
: isa-c!  ( data isa-adr -- )
   swap " set r3,*" evaluate  1 " eieio  stb r3,*" evaluate
;

resident

h# f101.2000 constant uart-base

label putbyte  ( r3: byte -- )  \ Destroys r0-r1
   uart-base  set  r1,*
   begin   lbz r0,h#14(r1)   andi. r0,r0,h#20   0<> until
   eieio   stb r3,h#0(r1)
   begin   lbz r0,h#14(r1)   andi. r0,r0,h#20   0<> until   
   bclr 20,0
end-code

\ destroys: r0-r4
label putdigit  ( r3: nibble -- )  \ print 4-bit value in r3
   mfspr r4,lr
   andi. r3,r3,h#0f   cmpi 0,0,r3,9   > if  addi r3,r3,h#27  then
   addi r3,r3,h#30
   putbyte bl *
   mtspr lr,r4
   bclr 20,0
end-code

transient
: be-report  ( char -- )  " set r3,* be-putbyte bl *" evaluate  ;
resident

\ destroys: r0-r6
label dot   ( r3: n -- )	\ print 32-bit value in r3
   mfspr r5,lr
   mr    r6,r3

   set r3,h#20  putbyte bl *

   rlwinm r3,r6,04,28,31   putdigit bl *
   rlwinm r3,r6,08,28,31   putdigit bl *
   rlwinm r3,r6,12,28,31   putdigit bl *
   rlwinm r3,r6,16,28,31   putdigit bl *
   rlwinm r3,r6,20,28,31   putdigit bl *
   rlwinm r3,r6,24,28,31   putdigit bl *
   rlwinm r3,r6,28,28,31   putdigit bl *
   rlwinm r3,r6,00,28,31   putdigit bl *

   set r3,h#20  putbyte bl *
   mtspr lr,r5
   bclr 20,0
end-code

\ destroys: r0-r4
label dcr  ( -- )
   mfspr r4,lr
   carret   set r3,*   putbyte bl *
   linefeed set r3,*   putbyte bl *
   mtspr lr,r4
   bclr 20,0
end-code

[ifdef] pc@
stand-init-debug?  [if]
: putc  ( char -- )
   begin  5 uart@  h# 20 and  until
   0 uart!
   begin  5 uart@  h# 20 and  until
;
: ?putc  ( "char" -- )  postpone [char]  postpone putc  ; immediate
[else]
transient
: ?putc  ( "char" -- )  safe-parse-word 2drop  ; immediate
resident
[then]
[then]

[ifdef] notdef
: digits  " 0123456789abcdef" drop ;
: xx.  0  d# 28  do  dup i >> h# f and  digits + c@ emit  -4 +loop space  drop ;
[then]

headers
transient
: .r3  ( -- )  " dot bl *" evaluate  ;

[ifdef] stand-init-debug?
: ?report  ( char -- )
   stand-init-debug?  if
      " set r3,*  putbyte bl *" evaluate
   else
      drop
   then
;
[else]
: ?report  ( char -- )  " set r3,*  putbyte bl *" evaluate  ;
[then]

resident

transient
: spins  ( n -- )  " set r0,*  mtspr ctr,r0  begin countdown" evaluate  ;
resident

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
