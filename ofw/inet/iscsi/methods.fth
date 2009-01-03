purpose: iSCSI high level routines
\ See license at end of file

hex

\ proposed syntax is	select iscsi:server:port//disk@0:\filename
\ ofw will open this node with arguments "server:port"
\ and will open the subsidiary disk node with arguments "\filename"

: decode-server  ( server$ -- port# server$' )
   [char] : left-parse-string           ( port$ server$ )
   2swap  dup  if                       ( server$ port$ )
      push-decimal  $number  pop-base   ( server$ port# error? )
      abort" Bad port number"           ( server$ port# )
   else                                 ( server$ port$ )
      2drop is_port                       ( server$ port# )
   then                                 ( server$ port# )
   -rot                                 ( port# server$ )
;
: mount  ( target$ -- error? )
   decode-server			( port# server$ )
   set-server                      	( port# )
   dup to use_port
   connect 0=  if   true exit   then
   
   ['] login-discovery catch		( failed? )
   debug?  if
      ." login-discovery "
      dup if  ." failed"  else  ." succeeded"  then  cr
   then
   if  true exit  then

   
   ['] login-normal catch		( failed? )
   debug?  if
      ." login-normal "
      dup if  ." failed"  else  ." succeeded"  then  cr
   then
;

\ Called when an instance, but not the last instance, of the driver
\ is being closed
: reclose-hardware  ( -- )  ;

\ Called when the last instance of driver is being closed
: close-hardware  ( -- )
   logout
   disconnect
;

: seed-rng   ( -- )
   " get-time" clock-node @  $call-method 	( s m h d m y )
   3drop d# 60 * + d# 60 * + rn !
   3 0 do  random drop  loop	\ stir the bits
;
: reopen-hardware  ( -- okay? )
   seed-rng
   true
;
: open-hardware  ( -- status )
   reopen-hardware  0=  if  false exit  then

   my-args dup  if
      bootnet-debug  if
         2dup ." iSCSI: target is: " type cr
      then
      mount 0=
      bootnet-debug  if
         ." iSCSI: "
         dup  if   ." Succeeded"  else ." Failed!"  then  cr
      then
   else
      2drop true
   then
\   true to debug?
\   true to verbose?
;

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
