purpose: Load file for ISA floppy chip
\ See license at end of file

" fdc" device-name
" fdc" device-type

[ifdef] PREP
    6 encode-int  " interrupts" property
    2 encode-int  h# 68 encode-int encode+  " dma" property
[else]
    6 encode-int  3 encode-int encode+  " interrupts" property
    2 encode-int		\ Channel
    1 encode-int encode+	\ Type (1=A)
    8 encode-int encode+	\ Data bits
d# 16 encode-int encode+	\ Count bits
    0 encode-int encode+	\ Not bus mastering
    " dma" property
[then]

" pnpPNP,700" " compatible" string-property

headerless
defer getsec  defer putsec

headers
fload ${BP}/dev/isafdc/isafdc.fth

headerless
: clear-terminal-count  ( -- )  ;
: fdc-fifo-wait  ( -- stat )
   0 d# 300 0 do		\ wait up to 3 second
      drop fstat@ dup h# 80 and h# 80 = ?leave
      d# 10 ms
   loop
;
headers

fload ${BP}/dev/isafdc/fdcdma.fth
fload ${BP}/dev/isafdc/fdcconf.fth
fload ${BP}/dev/isafdc/fdccntrl.fth
fload ${BP}/dev/isafdc/fdcdata.fth
fload ${BP}/dev/isafdc/fdc-test.fth
fload ${BP}/dev/isafdc/fdcpkg.fth


\ LICENSE_BEGIN
\ Copyright (c) 1994 FirmWorks
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
