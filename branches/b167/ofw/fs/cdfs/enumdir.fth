\ See license at end of file
purpose: Directory entry enumeration for ISO 9660 file system

headerless
: (reset-dir)  ( -- )
   dir-block0 @  dir-block# !
   get-dirblk
   0 totoff !
   dir-buf  diroff @  +  select-file

;
: fdc@  ( offset -- byte )  +fd c@  ;
: file-date  ( -- s m h d m y )
   d# 23 fdc@  d# 22 fdc@  d# 21 fdc@
   d# 20 fdc@  d# 19 fdc@  d# 18 fdc@  d# 1900 +
   \ XXX handle GMT offset
;
: file-attributes  ( -- attributes )
   dir?  if  h# 4000  else  h# 8000  then  o# 555 or
   \ XXX handle extended attribute records
;
headers
: file-info  ( -- s m h d m y len attributes name$ )
   file-date  file-size  file-attributes  file-name
;

: next-file-info  ( id -- false | id' h m s d m y len attributes name$ true )
   dup  if  next-file  else  (reset-dir)  then   ( id )
   another-file?  if        ( id )
      case
         0 of  1 file-info  2drop " ."   endof
         1 of  2 file-info  2drop " .."  endof
              1+ file-info  0
      endcase
      true    ( id' h m s d m y len attributes name$ true )
   else                     ( id )
      drop false            ( false )
   then
;
: free-bytes  ( -- d.#bytes )  0.  ;  \ No free bytes on a read-only device
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
