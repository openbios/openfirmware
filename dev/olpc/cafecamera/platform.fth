\ See license at end of file
purpose: Platform specifics for OLPC Camera on XO-1

headers
hex

" camera" device-name
" olpc,camera" model
" camera" device-type
" olpc,camera" " compatible" string-property

h# 4000 constant /regs

my-address my-space               encode-phys
    0 encode-int encode+  h# 0 encode-int encode+

my-address my-space h# 200.0010 + encode-phys encode+
    0 encode-int encode+  /regs encode-int encode+

" reg" property

: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;

0 instance value chip

: cl!  ( l adr -- )  chip + rl!  ;
: cl@  ( adr -- l )  chip + rl@  ;

: map-regs ( -- )
   0 0  h# 0200.0010 my-space +  /regs " map-in" $call-parent to chip
   4 my-w@  6 or  4 my-w!
;

: unmap-regs  ( -- )
   chip /regs " map-out" $call-parent
\   4 my-w@  6 invert and  4 my-w!  \ No need to turn it off
;

h# 42 2 << constant ov-sid

: clr-smb-intr  ( -- )  7.0000 30 cl!  ;
: smbus-wait  ( -- )
   begin  28 cl@ 7.0000 and  until
   1 ms				\ 20 usec delay
;

: ov@  ( reg -- data )
   clr-smb-intr
   ov-sid 87.fc01 or b8 cl!	\ TWSI control 0: id, 8-bit, clk
   bc cl@ drop			\ Force write
   d# 16 << 100.0000 or bc cl!	\ TWSI control 1: read, reg
   smbus-wait
   bc cl@ ff and
;

: ov!  ( data reg -- )
   clr-smb-intr
   ov-sid 8.7fc01 or b8 cl!	\ TWSI control 0: id, 8-bit, clk
   bc cl@ drop			\ Force write
   d# 16 << or bc cl!		\ TWSI control 1: read, reg
   2 ms
   smbus-wait
   bc cl@ drop
;

\ This must be headerless so evaluate won't find this version
headerless
: confirm-selftest?  ( -- flag )  " confirm-selftest?" evaluate  ;
headers

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
