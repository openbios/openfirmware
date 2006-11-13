\ See license at end of file
purpose: Find-dropin, assuming that the stack is available

\ Destroys: ax, si, di
label strcmp  ( si: str1 di: str2 -- Z flag set if match, not set if mismatch )
   begin
      al lodsb
      0 [di]  ah  mov
      di inc

      0 # al cmp
   0<> while	\ Fall through if al not null, go to 2nd then otherwise

      0 # ah cmp
   0<> while	\ Fall through if ah not null, go to 1st then otherwise

      ah al cmp
   <> until	\ Continue looping if characters match, otherwise fall through
      \ If we fall through to here, the strings did not match, and the
      \ Z flag is already set properly
      ret
   then then
   \ If we exit here, we hit the end of at least one of the strings

   ah al cmp
   ret
end-code

\ Destroys: si, di, bx, dx
label find-dropin    ( ax: module-name-ptr -- ax: address|-1 )

   ax dx mov
   dropin-base #  bx  mov

   begin

      0 [bx]  ax  mov		\ bx: header
      h# 444d424f #  ax  cmp    \ 'OBMD' in little-endian
   = while

      d# 16 [bx]  si  lea	\ si: Name field of this module
      dx          di  mov	\ di: Name of module we seek	
      strcmp #)       call

      = if			\ If the strings match, we found the dropin
         bx  ax  mov		\ Return the address of the dropin header
         ret
      then

      4 [bx]  ax  mov		\ Length of dropin image (byte-swapped)
      ax          bswap		\ Length of dropin image

      ax      bx  add		\ Added to base address of previous dropin
      d# 35 # bx  add		\ Plus length of header (32) + roundup (3)
      h# ffff.fffc #  bx  and	\ Aligned to 4-byte boundary = new dropin addr
   repeat

   -1 #   ax  mov	\ No more dropins; return -1 to indicate failure
   ret
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
