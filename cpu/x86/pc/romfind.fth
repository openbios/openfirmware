\ See license at end of file
purpose: Find-dropin, assuming that a stack is not available

\ Destroys: si, di, bx, dx
label find-dropin  ( ax: module-name-ptr -- ax: address|-1 )

   ax dx mov
   dropin-base #  bx  mov

   begin

      0 [bx]  ax  mov		\ bx: header
      h# 444d424f #  ax  cmp    \ 'OBMD' in little-endian
   = while

      d# 16 [bx]  si  lea	\ si: Name field of this module
      dx          di  mov	\ di: Name of module we seek	
      begin			\ Put strcmp inline
         al lodsb
         0 [di] ah mov
         di inc
         0 # al cmp
      0<> while
         0 # ah cmp
      0<> while
         ah al cmp
      <> until
      then then

      ah al cmp
      = if			\ If the strings match, we found the dropin
         bx  ax  mov		\ Return the address of the dropin header

         begin
            0 [dx] bl mov
            dx inc
	    0 # bl cmp
         = until
         dx jmp
      then

      4 [bx]  ax  mov		\ Length of dropin image (byte-swapped)
      ax          bswap		\ Length of dropin image

      ax      bx  add		\ Added to base address of previous dropin
      d# 35 # bx  add		\ Plus length of header (32) + roundup (3)
      h# ffff.fffc #  bx  and	\ Aligned to 4-byte boundary = new dropin addr
   repeat

ascii D report
ascii E report
ascii A report
ascii D report
   -1 #   ax  mov	\ No more dropins; return -1 to indicate failure
   begin again
end-code

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
