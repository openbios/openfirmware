\ See license at end of file
purpose: Create a header in Linux bzImage format

\ The result of this can be used later with:
\   writing  somefile.bzi
\   bz-hdr /bz-hdr  0  " bz-header"  write-dropin

label bz-hdr
  \ Pad out first sector, accounting for the dropin header at the beginning
  here  h# 1d1 dup allot  erase  \ Gets us to h# 1f1 with dropin header

  1 c,                        \ h# 1f1 - number of real mode sectors - 1

  here  h# 1fe h# 1f2 -  dup allot  erase  \ Gets us to h# 1fe

  h# 55 c, h# aa c,    \ End of first sector

  0 w,                        \ h# 200 Linux has an (unused) jmp instruction here
  here 4 allot  " HdrS" rot swap move  \ h# 202  bzimage signature
  0 c, 2 c,                   \ h# 206 protocol version 2.00
  0 l,                        \ h# 208 realmode_swtch (not used)
  0 w,                        \ h# 20c start_sys (not used)
  0 w,                        \ h# 20e kver_addr (not used)
  0 c,                        \ h# 210 type_of_loader (not used)
  1 c,                        \ h# 211 loadflags (bzImage flag set)

  here  h# 400 h# 212 -  dup allot  erase  \ Gets us to h# 400

  \ The stuff before this point will be loaded at h# 9.0000
  \ The stuff after this point will be loaded at h# 10.0000, which
  \ is the normal load base for the 32-bit part of Linux.

\  h# eb c,  h# 3e c,   \ Skip past first dropin

\ The following code must take less than 32 bytes
here
  cld
  h# 10.0020       #  si  mov  \ Start copying after this code (offset 20)
  dropin-base      #  di  mov
  dropin-size 4 /  #  cx  mov
  rep movs

  dropin-base h# 20 + # ax mov \ Jump past the dropin header
  ax call

\ Pad to 32 bytes
here swap -  h# 20 swap -  here swap dup allot erase

end-code

here bz-hdr - constant /bz-hdr
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
