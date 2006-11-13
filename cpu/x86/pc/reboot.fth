\ See license at end of file
purpose: Reboot system: save reboot info in nvram configuration variables

headerless
: put-env-number  ( n name$ -- )  hex   rot (.) 2swap (put-ge-var) drop  ;
: get-env-number  ( name$ -- n )
   hex   $getenv  if  0  else  $number  if  0  then  then
;

0 value reboot-info
: +rb  ( offset -- adr )  reboot-info +  ;
: copy-reboot-info  ( -- )
   " reboot-command" $getenv  if  false to reboot?  exit  then

   d# 140 alloc-mem  to reboot-info
   " reboot-command" $getenv  if  " "  then  d#   0 +rb place
   " reboot-line#"   get-env-number          d# 132 +rb !
   " reboot-column#" get-env-number          d# 136 +rb !

   " reboot-command" $unsetenv
   " reboot-line#"   $unsetenv
   " reboot-column#" $unsetenv

   true to reboot?
;

: (save-reboot-info)  ( cmd$ line# column# -- )
   " reboot-column#" put-env-number
   " reboot-line#"   put-env-number
   " reboot-command" (put-ge-var) drop
;
' (save-reboot-info) to save-reboot-info

: (get-reboot-info)  ( -- cmd$ line# column# )
   0 +rb count  d# 132 +rb @  d# 136 +rb @
;
' (get-reboot-info) to get-reboot-info
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
