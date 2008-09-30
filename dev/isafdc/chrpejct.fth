purpose: Amend floppy nodes to implement and report the CHRP eject function
\ See license at end of file

dev /fdc

0 0 encode-bytes
h# 3f0     1 encode-phys encode+  7 encode-int encode+
h# 3f7     1 encode-phys encode+  1 encode-int encode+
eject-port 1 encode-phys encode+  1 encode-int encode+
" reg" property

" chrp,fdc" +compatible

0 0 encode-bytes  " auto-eject"  property

: eject  ( -- )
   floppy-xselect				\ Select drive, enable motor
   eject-port pc@ dup		( orig orig )	\ Old port value
   dup 1 and if			( orig orig )	\ Is eject bit currently 1?
      h# fe and			( orig eject )	\ Set low (active low eject)
   else
      1 or			( orig eject )	\ Set high (active high eject)
   then
   eject-port pc!		( orig )	\ Set the eject bit
   1 ms				( orig )	\ Wait
   eject-port pc!		( )		\ Put back original value
   floppy-xdeselect		\ Unselect drive, disable motor
;

dev /fdc/disk
: eject  ( -- )
   my-unit  " set-address" $call-parent
   " eject" $call-parent
;
device-end


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
