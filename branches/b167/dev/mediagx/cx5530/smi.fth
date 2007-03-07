\ See license at end of file
purpose: Cyrix 5530 I/O Companion Function 1 driver

hex headers

" smi" device-name

d# 256 constant /chipbase

0 value chipbase

: +int   ( $1 n -- $2 )   encode-int encode+  ;

\ Configuration space registers
my-address my-space        encode-phys          0 +int          0 +int

\ Memory mapped I/O space registers
4001.2000 0  my-space  8200.0010 + encode-phys encode+  0 +int  /chipbase +int

" reg" property

: my-b@  ( offset -- b )  my-space +  " config-b@" $call-parent  ;
: my-b!  ( b offset -- )  my-space +  " config-b!" $call-parent  ;

: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;

: my-l@  ( offset -- l )  my-space +  " config-l@" $call-parent  ;
: my-l!  ( offset -- l )  my-space +  " config-l!" $call-parent  ;

: map-in   " map-in"  $call-parent  ;
: map-out  " map-out" $call-parent  ;

: map-regs    ( -- )  0 0  my-space h# 0200.0010 +  /chipbase map-in  to  chipbase ;
: unmap-regs  ( -- )  chipbase /chipbase map-out  ;

external

: open  ( -- ok? )  map-regs true  ;

: close  ( -- )  unmap-regs  ;

headers

: init-pci  ( -- )
   4001.2000 10 my-l!			\ program BAR
   2 4 my-w!				\ enable memory mapped I/O
;
: init-smi  ( -- )  ;

: init  ( -- )
   init-pci
   make-properties
   init-smi
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
