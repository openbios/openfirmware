purpose: CRC calculation for PR*P NVRAM
\ See license at end of file

\ Uses CCITT polynomial  x**16 + x**12 + x**5 + 1

: rol  ( x y mask -- n )  -rot 2dup << -rot  d# 16 swap - >>  or  and  ;
: ror  ( x y mask -- n )  -rot 2dup >> -rot  d# 16 swap - <<  or  and  ;

: crcgen  ( oldcrc data -- newcrc )
   swap wbsplit rot xor    ( old.lo pd>> )
   dup rot bwjoin          ( pd>> crc )
   swap 8 << swap          ( pd crc )
   over 4 h# f00f rol xor  ( pd crc' )
   over 3 h# 1fe0 ror xor  ( pd crc'' )
   over   h# f000 and xor  ( pd crc''' )
   swap 7 h# 01e0 ror xor  ( newcrc )
;

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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

