\ See license at end of file
purpose: Adler-32 checksum (used in zlib compression)

code adler32  ( adr len -- adler )
   0 [sp]  bp  xchg   \ bp: len  and save bp
   4 [sp]  si  xchg   \ si: adr  and save si
   bp cx mov          \ cx: len
   di push            \ Save di
   d# 65521 # di mov  \ MOD_ADLER

   bx bx xor          \ A
   bx inc             \ bx: A=1
   bp bp xor          \ bp: B=0
   begin
      ax ax xor
      al lods         \ ax: data[index]
      bx ax add       \ ax: A + data[index]
      dx dx xor       \ Clear high word of dividend
      di  div         \ Remainder in dx
      dx bx mov       \ bx: A = (A + data[index]) % MOD_ADLER
      bx bp add       \ bp: B + A
      dx dx xor       \ Clear high word of dividend
      bp ax mov       \ ax: low word of dividend
      di  div         \ Remainder in dx
      dx bp mov       \ bp: B = (B + A) % MOD_ADLER
   loopa
   d# 16 # bp shl     \ bp: (B << 16)
   bp bx or           \ bx: (B << 16) | A
   di pop             \ Restore di
   bp pop             \ Restore bp
   si pop             \ Restore si
   bx push            \ Return result
c;

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
