\ See license at end of file
purpose: Interface to Linux serial driver via Forth wrapper

' (key to key

-1 value serial-fd

: baud  ( baud -- )
   serial-fd  d# 356 syscall 2drop retval  abort" c_setbaud failed"
;
: raw  ( -- )  serial-fd  d# 352 syscall drop  ;
: getattr  ( -- termios )  serial-fd  d# 364 syscall drop  retval  ;
: setattr  ( termios -- )  serial-fd  d# 368 syscall 2drop  ;
: 8n1  ( -- )
   getattr   ( termios )
   dup  8 + l@        ( termios c_cflag )
   h# 30 or           ( termios c_cflag' )  \ CS8
   h# 100 invert and  ( termios c_cflag' )  \ PARENB = 0
   h#  40 invert and  ( termios c_cflag' )  \ CSTOPB = 0
   over 8 + l!        ( termios )
   setattr   ( )
;
: blocking  ( -- )
   getattr   ( termios )
   1  over d# 17 +  6 +  c!   ( termios )  \ Set VMIN to 1
   setattr   ( )
;
: non-blocking  ( -- )
   getattr   ( termios )
   0  over d# 17 +  6 +  c!   ( termios )  \ Set VMIN to 0
   setattr   ( )
;

: $open-serial  ( dev$ -- )  \ e.g. " /dev/ttyS0"
   $cstr  0 2 rot  8 syscall  3drop retval  to serial-fd
   serial-fd 0< abort" Can't open serial device"
   raw  8n1  blocking
   d# 115200 baud
;

d# 128 buffer: line-name

: line  ( devname -- )
   safe-parse-word    ( adr len )
   dup 127 u> abort" Device name too long"
   line-name place
;

: open-serial  ( "devname" -- )
   line-name c@  if  line-name count  else  " /dev/ttyS0"  then
   $open-serial
;

1 buffer: outchar
1 buffer: inchar
0 value inchar?

: uemit  ( char -- )
   outchar c!  1 outchar serial-fd  d# 24  syscall  3drop
;
: ukey?  ( -- flag )
   inchar?  if  true exit  then
   1 inchar serial-fd  d# 20  syscall  3drop
   retval  1 =  dup to inchar?
;
: ukey  ( -- char )
   begin  ukey?  until
   inchar c@
   false to inchar?
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
