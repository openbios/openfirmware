\ See license at end of file
purpose: Create LPT port nodes

[ifdef] PREP
7 encode-int                          " interrupts" property
[else]
7 encode-int  3 encode-int encode+    " interrupts" property
[then]

" parallel"	device-name
" parallel"	device-type

" pnpPNP,401" " compatible" string-property

\ Note: Some devices allow you to configure the parallel port to
\ be at either 3bc (LPT1), 378 (LPT2), or 278 (LPT3).

my-address my-space  4  reg

headerless
0 instance value reg-base
h# c instance value mode	\ Printer selected (8), don't init (4)
d# 10 instance value strobe-spins
d# 3000 instance value busy-timeout-ms

: data@  ( -- b )  reg-base rb@  ;
: data!  ( b -- )  reg-base rb!  ;
: stat@  ( -- b )  reg-base 1+ rb@  ;
: ctl@   ( -- b )  reg-base 2+ rb@  ;
: ctl!   ( b -- )  reg-base 2+ rb!  ;

headers

: open  ( -- flag )
   my-address my-space 4  " map-in" $call-parent to reg-base
   mode ctl!
   true
;

: close  ( -- )  reg-base 4 " map-out" $call-parent  ;

headerless
: wait-not-busy  ( -- timeout? )
   get-msecs  busy-timeout-ms +        ( timeout-target )
   begin                               ( timeout-target )
      stat@  h# 80 and  if             ( timeout-target )
	 drop false exit               ( false )
      then                             ( timeout-target )
      dup get-msecs - 0<=              ( timeout-target timeout? )
   until                               ( timeout-target )
   drop true                           ( true )
;

: wait-ack  ( -- timeout? )
   get-msecs 2+                        ( timeout-target )
   begin                               ( timeout-target )
      stat@  h# 40 and  0=  if         ( timeout-target )
	 drop false exit               ( false )
      then                             ( timeout-target )
      dup get-msecs - 0<=              ( timeout-target timeout? )
   until                               ( timeout-target )
   drop true                           ( true )
;

\ Pulse the strobe line
: strobe  ( -- )  mode 1 or ctl!  strobe-spins 0 do loop   mode ctl!  ;

: putbyte  ( byte -- error? )
   wait-not-busy  if  drop true exit  then   ( byte )
   data!
   strobe
   wait-ack
;

headers
: write  ( adr len -- actual )
   \ We don't want to miss an ACK, so we mustn't take interrupts
   \ Timeouts in the wait loops prevent hanging

   lock[  ( adr len )

      tuck  0  ?do                   ( len adr )
	 dup i + c@  putbyte  if     ( len adr )
	    2drop  i  unloop         ( actual )
	 ]unlock  exit
      then                        ( len adr )
   loop                           ( len adr )
   drop ]unlock    ( len )
;
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
