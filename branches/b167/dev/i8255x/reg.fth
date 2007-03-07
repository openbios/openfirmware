\ See license at end of file
purpose: Registers

hex
headers

d# 64   constant /csr-io
d# 4096 constant /csr-mem
d# 128 d# 1024 * constant /flash

: +int   ( $1 n -- $2 )   encode-int encode+  ;

\ Configuration space registers
my-address my-space        encode-phys          0 +int         0 +int

\ I/O space registers
0 0  my-space  0100.0014 + encode-phys encode+  0 +int   /csr-io +int

\ Memory mapped I/O space registers
0 0  my-space  0200.0010 + encode-phys encode+  0 +int  /csr-mem +int
0 0  my-space  0200.0018 + encode-phys encode+  0 +int    /flash +int

" reg" property

: my-b@  ( offset -- b )  my-space +  " config-b@" $call-parent  ;
: my-b!  ( b offset -- )  my-space +  " config-b!" $call-parent  ;

: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;

: my-l@  ( offset -- l )  my-space +  " config-l@" $call-parent  ;
: my-l!  ( offset -- l )  my-space +  " config-l!" $call-parent  ;

0 value csr-base

: map-regs  ( -- )
   0 0  my-space h# 0100.0010 +  /csr-io " map-in" $call-parent  to csr-base
   4 my-w@  7 or  4 my-w!
;
: unmap-regs  ( -- )
   4 my-w@  7 invert and  4 my-w!
   csr-base /csr-io " map-out" $call-parent
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
