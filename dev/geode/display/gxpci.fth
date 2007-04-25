\ See license at end of file
purpose: PCI footprint for AMD GX graphics controller

hex
headers

: phys+ encode-phys encode+  ;
: i+  encode-int encode+  ;

0 0 encode-bytes
0 0 h# 0000.0000  my-space +  phys+   0 i+  h# 0000.0100 i+   \ Config registers
0 0 h# 0200.0010  my-space +  phys+   0 i+  h# 0080.0000 i+   \ Frame buffer
0 0 h# 0200.0014  my-space +  phys+   0 i+  h# 0000.4000 i+   \ Display controller
0 0 h# 0200.0018  my-space +  phys+   0 i+  h# 0000.4000 i+   \ Video controller
0 0 h# 0200.001c  my-space +  phys+   0 i+  h# 0000.4000 i+   \ Graphics controller
0 0 h# 0200.0020  my-space +  phys+   0 i+  h# 0000.4000 i+   \ Video Input Port
" reg" property

: map-membar  ( bar size -- adr )
   >r
   my-space +  h# 0200.0000 or 0 0  rot  ( phys )
   r> " map-in" $call-parent
;
: unmap  ( adr size -- )  " map-out" $call-parent  ;
: (map-io-regs)  ( -- gp dc vp )
   h# 14 h# 4000 map-membar   ( gp-base )
   h# 18 h# 4000 map-membar   ( gp-base dc-base )
   h# 1c h# 4000 map-membar   ( gp-base dc-base vp-base )
;
: (map-frame-buffer)  ( -- adr )
   h# 10  h# 80.0000  map-membar
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
