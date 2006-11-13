\ See license at end of file
purpose: Search for Linux on disks

\needs search-disks  fload ${BP}/ofw/gui/findos.fth

headerless
: present?  ( partition# target# filename$ -- flag )
   null-output
   2swap >disk-name  open-dev  restore-output   ( ihandle|0 )
   dup  if  close-dev  then
;

: last-file-name  ( -- adr len )  disk-name count  ;
: .found  ( target# -- target# )
   ." Found Linux at " last-file-name type  cr
;
: target-find-linux?  ( target# -- found? )
   5 1  do                                      ( target# )
      i over  " \vmlinux.gz" present?  if       ( target# )
         .found                                 ( target# )
         unloop  true exit
      then                                      ( target# )
      i over  " \vmlinux"  present?  if         ( target# )
         .found                                                ( target# )
         unloop  true exit
      then                                      ( target# )
      i over  " \boot\vmlinux"  present?  if    ( target# )
         .found                                 ( target# )
         unloop  true exit
      then                                      ( target# )
      i over  " \boot\vmlinux.gz" present?  if  ( target# )
         .found                                 ( target# )
         unloop  true exit
      then                                      ( target# )
   loop                                         ( target# )
   drop false
   restore-output
;

: linux-present?  ( -- found? )
   ." Locating the Windows NT operating system ..." cr
   ['] target-find-linux?  search-disks  dup  0=  if
      ." Linux does not appear to be installed in any of the usual places." cr
   then
;
headers
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
