purpose: Save reboot info using /reboot-info device
\ See license at end of file

0 value reboot$
d# 256 value /reboot$

: copy-reboot-info  ( -- )
   " /reboot-info" open-dev ?dup 0=  if  exit  then  >r
   /reboot$ alloc-mem  to reboot$            ( )

   reboot$ 1+  /reboot$ 1- " read" r@ $call-method  ( actual )
   dup  0>=  dup to reboot?   if                    ( actual )
      reboot$ c!                                    ( )
   else                                             ( -1 )
      drop  reboot$ /reboot$ free-mem               ( )
   then
   r> close-dev
;

: (get-reboot-info)  ( -- bootcmd$ line# column# )  reboot$ count  0 0  ;
' (get-reboot-info) to get-reboot-info

: (save-reboot-info)  ( bootcmd$ line# column# -- )
   2drop
   " /reboot-info" open-dev ?dup 0=  if  2drop exit  then  >r  ( cmd$ r: ih )
   " write" r@ $call-method drop                               ( r: ih )
   r> close-dev
;
' (save-reboot-info)  to save-reboot-info

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
