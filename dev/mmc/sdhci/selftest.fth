purpose: Driver for SDHCI (Secure Digital Host Controller)
\ See license at end of file

headers

: /block  ( -- u )  " /block" $call-parent  ;

0 instance value sbuf
0 instance value ibuf
0 instance value obuf
: alloc-test-bufs  ( -- )
   ibuf  if  exit  then
   /block dma-alloc to ibuf
   /block dma-alloc to obuf
   /block dma-alloc to sbuf
;
: free-test-bufs  ( -- )
   ibuf 0=  if  exit  then
   ibuf /block dma-free  0 to ibuf
   obuf /block dma-free  0 to obuf
   sbuf /block dma-free  0 to sbuf
;
: read-block  ( adr block# -- error? )  1  read-blocks 1 <>  ;
: write-block ( adr block# -- error? )  1 write-blocks 1 <>  ;
: test-block  ( block# pattern -- error? )
   obuf /block 2 pick     fill  obuf 2 pick write-block  if  true exit  then
   ibuf /block rot invert fill  ibuf swap   read-block   if  true exit  then
   ibuf obuf /block comp
;

: write-protected?  ( -- )  " write-protected?" $call-parent  ;

: (selftest)  ( -- error? )
   write-protected?  if  ." SD card is locked" cr  true  exit  then

   sbuf 0  read-block  if  true exit  then
   0 h# 5a test-block  if  true exit  then
   0 h# a5 test-block  if  true exit  then
   sbuf 0 write-block	   	        \ Restore original content
;
: $=  ( $1 $2 -- flag )
   rot tuck <>  if        ( adr1 adr2 len1 )
      3drop false exit
   then                   ( adr1 adr2 len1 )
   comp 0=                ( flag )
;
: external?  ( -- flag )
   " slot-name" get-my-property  if
      false
   else
      decode-string " external" $=
   then
;
: .slot-name  ( -- )
   " slot-name" get-my-property  0=  if
      decode-string type space  2drop
   then
   ." SD slot"
;
: card-present?  ( -- )  " card-inserted?" $call-parent  ;
: test-abort?  ( -- flag )
   key?  if  key h# 1b =  else  false  then
;
: wait-card?  ( -- error? )
   card-present?  if  false exit  then
   diagnostic-mode?  if
      ." Please insert card in " .slot-name ."  to continue test."  cr
      begin
         d# 100 ms
         test-abort?  if  ." Aborted" true exit  then
      card-present? until
      ." Card insertion correctly detected." cr
      d# 200 ms  \ Settling time
      false
   else
      ." No card in " .slot-name cr
      true
   then
;

: wait-removal?  ( -- error? )
   diagnostic-mode?  0=  if  false exit  then
   external?  0=  if  false exit  then

   ." Please remove card from " .slot-name ."  to continue test."  cr         

   begin
      d# 100 ms
      test-abort?  if  ." Aborted" true exit  then
   card-present? 0= until
   ." Card removal correctly detected." cr
   false
;

external
: selftest  ( -- error? )
   set-unit

   wait-card?  if  true exit  then

   open 0=  if  ." Open SD card failed" cr true exit  then
   alloc-test-bufs
   ['] (selftest) catch  if  true  then  ( error? )
   free-test-bufs                        ( error? )
   close                                 ( error? )

   if  true exit  then                   ( )

   wait-removal?                         ( error? )
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
