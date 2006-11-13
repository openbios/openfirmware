\ See license at end of file

hex

only forth also meta also forth-h definitions
: reloc-size   ( -- n )
   here-t origin-t -  ( user-size-t + )
   0f + 4 >>
;

: save-meta  ( str -- )
\   origin-t >hostaddr  here-t origin-t -  save-image

   origin-t  origin-t h# 1c +  le-l!-t	\ Relocation base of saved image

   here-t origin-t - is code-size
   origin-t >hostaddr is code-adr
   makeheader

   new-file
   exp-header /exp-header ofd @ fputs
   code-adr code-size ofd @ fputs
   relocation-map-t reloc-size ofd @ fputs

   ofd @ fclose
;

only forth also meta also definitions
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
