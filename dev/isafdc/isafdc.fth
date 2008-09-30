purpose: Setup for i82077 floppy chip driver
\ See license at end of file

hex
\ Map a virtual address to the floppy device.

\ " i82077" device-name		\  Name of device node
my-address my-space 8  reg

headerless
2  constant terminal-count
0 instance value floppy-chip
: map-floppy  ( -- )
   my-address my-space 8 " map-in" $call-parent  4 +  is floppy-chip
;

: fifo@   ( -- char )  floppy-chip 1+ rb@  ;
: fifo!   ( char -- )  floppy-chip 1+ rb!  ;
: fstat@  ( -- char )  floppy-chip rb@  ;
: fstat!  ( char -- )  floppy-chip rb!  ;
: dor@	  ( -- char )  floppy-chip 2- rb@  ;
: dor!	  ( -- char )  floppy-chip 2- rb!  ;
: dir@	  ( -- char )  floppy-chip 3 + rb@  ;
: dir!	  ( -- char )  floppy-chip 3 + rb!  ;

headers
: unmap-floppy  ( -- )  floppy-chip 4 -  8  " map-out" $call-parent  ;


\ LICENSE_BEGIN
\ Copyright (c) 1994 FirmWorks
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
