\ See license at end of file
purpose: TCP application convenience words

0 value tcp-ih
: $call-tcp  ( ?? name$ -- ?? )  tcp-ih $call-method  ;

: close-tcp  ( -- )  tcp-ih close-dev  0 to tcp-ih  ;
: open-tcp  ( -- )
   tcp-ih  if  exit  then
   " tcp" open-dev to tcp-ih
   tcp-ih 0= abort" Can't open TCP/IP stack"
;
: set-tcp-server  ( hostname$ -- )
   dup  if  " $set-host" $call-tcp  else  2drop  then
;
: tcp-connect  ( port# -- )
   " connect" $call-tcp  0= abort" Connection refused
;
: tcp-disconnect  ( -- )  " disconnect" $call-tcp  ;
: open-tcp-connection  ( hostname$ port# -- )
   open-tcp  -rot set-tcp-server  tcp-connect
;

: tcp-read   ( adr len -- actual )  " read"  $call-tcp  ;
: tcp-type   ( adr len -- )  " write" $call-tcp  drop  ;

variable tcp-out
: tcp-emit    ( c -- )   tcp-out c!  tcp-out 1 tcp-type  ;

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
