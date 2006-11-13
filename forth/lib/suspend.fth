\ See license at end of file

\ Smart keyboard driven exit
\ Type q to abort the listing, anything else to pause it.
\ While it's paused, type q to abort, anything else to resume.

decimal

only forth also hidden also
hidden definitions

headerless
variable 1-more-line?  1-more-line? off
true value page-mode?

forth definitions
headers
: no-page    ( -- )  false is page-mode?  ;
: page-mode  ( -- )  true  is page-mode?  ;
headerless
: suspend-help  ( -- )
   ." Pager keys:" cr
   ."  <space>   Another page" cr
   ."  <cr>      Another line" cr
   ."  q         Quit" cr
   ."  c         Page Mode Off" cr
   ."  p         Page Mode On" cr
   ."  i         Interact" cr
   ."  d         Debug" cr
   ."  h or ?    Help (this message)" cr
;
: suspend-interact  ( -- )  ." Type 'resume' to continue" cr  interact  ;
defer suspend-debug  ( -- )   ' noop is suspend-debug
: (reset-page)  #line off  1-more-line? off  ;
' (reset-page)  is reset-page
: suspend  ( -- flag )
   #line off
   ??cr dark  ."  More [<space>,<cr>,q,c,p,i,d,h] ? "  light
   key  #out @  (cr  spaces  (cr  #out off
   dup  ascii q  =   if  drop true  exit  then
   dup  ascii n  =   if  drop true  exit  then
   dup  ascii p  =   if  drop page-mode  false  exit  then
   dup  ascii c  =   if  drop no-page  false  exit  then
   dup  ascii i  =   if  drop suspend-interact  false  exit  then
   dup  ascii d  =   if  drop suspend-debug  false  exit  then
   dup  ascii h  =   if  drop suspend-help   false  exit  then
   dup  ascii ?  =   if  drop suspend-help   false  exit  then
   dup  linefeed =  swap carret =  or  if  1-more-line? on  then
   false
;
d# 24 value default-#lines
headers

defer lines/page  ' default-#lines is lines/page

headerless
: (exit?)  ( -- flag )  \ True if the listing should be stopped
   interactive?  0=  if  false  exit  then

   \ In case we start with lines/page already too large, we clear it out
   page-mode?  if  #line @ lines/page u>=  if  suspend exit  then  then
   1-more-line? @  if  1-more-line? off  suspend  exit  then
   page-mode?  if  #line @ 1+  lines/page =  if  suspend exit  then  then
   key?  if
      key ascii q =  if   #line off  true  else  suspend  then
   else
      false
   then
;
headers
defer exit?
' (exit?) is exit?
only forth also definitions

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
