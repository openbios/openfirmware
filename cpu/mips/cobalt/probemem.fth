purpose: Memory probing
\ See license at end of file

\ The memory regions are 0xxx.xxxx, 8xxx.xxxx, 9xxx.xxxx, and cxxx.xxxx
: (memory?)  ( adr -- flag )  d# 28 rshift  0=  ;
' (memory?) to memory?

" /memory" find-device

headerless

h# 0400.0000 constant /ram-bank  \ 64 MB banks

h# ffff.ffff value low
h#         0 value high

: log&release  ( adr len -- )

   \ Don't erase the firmware!  Reduce the length to avoid it.
   2dup  over +                              ( adr len adr adr+len )
   origin h# 20 - kseg0 -  umin  over -      ( adr len adr len' )

   \ Don't zero the memory
   2drop

   over    low  umin to low             ( adr len )
   2dup +  high umax to high            ( adr len )
   release
;

: >bank-base  ( index -- bank-pa )  d# 26 lshift  ;
: scan-banks  ( total-size -- )
   d# 4 0  do                           ( size )
      dup  if                           ( size )
         i >bank-base                   ( size bank-adr )
         over /ram-bank min             ( size bank-adr this-size )
         tuck log&release               ( size this-size )
         -                              ( size' )
      then                              ( size' )
   loop                                 ( size' )
   drop
;
headers
: claim  ( [ phys ] size align -- kseg0-adr )  claim kseg0 +  ;
: release  ( kseg0-adr size -- )
   over kseg0 u>=  if  swap kseg0 - swap  then   release
;

: probe  ( -- )
   h# 1000.0000
   ( memsize-loc @ )  scan-banks

   0 0 encode-bytes                                   ( adr 0 )
   physavail  ['] make-phys-memlist  find-node        ( adr len  prev 0 )
   2drop  " reg" property

   \ Claim the megabyte used for the trap vectors, Forth, and the section table
   0                  /resetjmp       0 claim  drop
   high h# 10.0000 -  h# 10.0000      0 claim  drop
;

device-end

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
