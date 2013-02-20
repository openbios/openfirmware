\ See license at end of file
purpose: Remote diagnosis console - shares the interpreter with a remote host

\
\ rdc - a telnetd that makes rather than accepting a connection.
\ rdcd - a telnet that accepts rather than making a connection.
\

\
\ Instructions for use over internet:
\
\ 1.  set up a TCP relay on ports 8024 and 8023 of a host that is
\     accessible to the user over the internet,
\
\     % socat \
\       TCP-LISTEN:8024,fork,reuseaddr,nodelay,bind=127.0.0.1 \
\       TCP-LISTEN:8023,reuseaddr,nodelay
\
\ 2.  start your telnet client and connect to port 8024,
\
\     % telnet -- 127.0.0.1 -8024
\
\     (the odd arguments are to force automatic initiation of TELNET options
\     which would otherwise be omitted due to the non-standard port number).
\
\ 3.  ask the user to type "rdc IP" on the remote system, where IP is the IP
\     address of the host running socat,
\
\     ok rdc IP
\
\ 4.  use the remote system via the connection.  When done, type
\     "exit-rdc" or just close the connection.
\

\
\ Instructions for use over a local network:
\
\ 1.  on the host firmware system, start rdcd to listen for
\     connections, and note the IP address shown,
\
\     ok rdcd
\
\ 2.  on the target firmware system, type "rdc IP",
\
\     ok rdc IP
\
\ 3.  use the remote system via the connection.  When done, type
\     "exit-rdc" or close the connection with ctrl-].
\

\needs telnet fload ${BP}/ofw/inet/telnet.fth
\needs telnetd fload ${BP}/ofw/inet/telnetd.fth

: exit-rdc
   telnet-ih  0=  if  exit  then
   demux
   close-telnet
   ." rdc: off" cr
;

: $rdc  ( host$ port# -- )
   " tcp//telnet:passive" open-telnet
   " connect?" telnet-ih $call-method  0=  if
      close-telnet true abort" Can't connect to host"
   then
   ." rdc: connected" cr
   mux  banner
;

: parse-port  ( ["port"] -- port# )
   parse-word dup if                                    ( port$ )
      push-decimal $number pop-base abort" Bad port"    ( port# )
   else
      2drop d# 8023
   then                                                 ( port# )
;

: rdc  ( "host" ["port"] -- )  \ share this console with remote host
   safe-parse-word  parse-port  $rdc
;

: rdcd  ( ["port"] -- )  \ wait for a shared console connection
   parse-port
   open-tcp
   ." rdcd: listening for a connection" cr
   tcp-accept
   ." rdcd: connected" cr
   (telnet)
   close-tcp
   ." rdcd: disconnected" cr
;

\ LICENSE_BEGIN
\ Copyright (c) 2013 FirmWorks
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
