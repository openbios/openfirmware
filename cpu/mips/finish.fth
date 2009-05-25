purpose: Final steps of kernel metacompilation for MIPS
\ See license at end of file

\ ' sys-init-io is init-io

\ hex
\ " root" $sfind drop resolution@ >user-t link-t@
\ begin dup u. dup origin-t <> while /link-t - link@-t repeat drop cr
\ cr
\ " forth" $sfind drop resolution@ >user-t link-t@
\ begin dup u. dup origin-t <> while /link-t - link@-t repeat drop cr
\ cr


also assembler
\ cld 8 +         cld      branch!
\ 'body cold-code cld 8 +  branch!
previous
variable dodoesaddr

' init  is do-init

assembler dodoes meta   is dodoesaddr
forth-h
metaoff
only forth also meta also definitions
fix-vocabularies
only forth also definitions
' symbols fixall

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
