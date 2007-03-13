purpose: RC4 stream generation
\ See license at end of file

\ XOR RC4 stream to given data with skip-stream-start
\
\ Generate RC4 pseudo random stream for the given key, skip beginning of the
\ stream, and XOR the end result with the data buffer to perform RC4
\ encryption/decryption.

d# 256 constant /s
/s buffer: s
0 value rj
0 value kpos
0 value skip
0 value rkey
0 value /rkey
0 value rdata
0 value /rdata

: s@      ( idx -- )  h# ff and s + c@  ;
: s!      ( b idx -- )  h# ff and s + c!  ;
: +rj     ( n -- )  rj + h# ff and to rj  ;
: rkey@   ( idx -- )  rkey + c@  ;
: rdata++ ( -- )  rdata 1+ to rdata  ;
: kpos++  ( -- )  kpos 1+ dup /rkey >=  if  drop 0  then  to kpos  ;
: sswap   ( i j -- )
   over s@ over s@			( i j s[i] s[j] )
   -rot swap s!				( i s[j] )
   swap s!				( )
;
: rc4-skip  ( data$ key$ skip -- )
   to skip  to /rkey  to rkey  to /rdata  to rdata

   \ Setup RC4 state
   /s 0  do  i dup s!  loop
   0 to rj 0 to kpos
   /s 0  do
      i s@ kpos rkey@ + +rj
      kpos++
      i rj sswap
   loop

   \ Skip the start of the stream
   0 to rj
   skip 1+ 1  ?do
      i s@ +rj
      i rj sswap
   loop

   \ Apply RC4 to data
   /rdata 1+ 1  ?do
      i s@ +rj
      i rj sswap
      i s@ rj s@ + s@ rdata c@ xor rdata c!
      rdata++
   loop
;

\ XOR RC4 stream to given data
\ Generate RC4 pseudo random stream for the given key and XOR this with the
\ data buffer to perform RC4 encryption/decryption.

: rc4  ( data$ key$ -- )  0 rc4-skip  ;


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

