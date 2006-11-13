\ See license at end of file
purpose: watch-net network debugging command

headerless
0 value net-ih
0 value max-packet
0 value packet-buf
: (watch-net)  ( ihandle -- )
   to net-ih
   " max-frame-size" net-ih ihandle>phandle  get-package-property  if  ( )
      d# 2000            ( length )
   else                  ( adr len )
      get-encoded-int    ( length )
   then                  ( length )
   to max-packet         ( )
   max-packet alloc-mem to packet-buf
   ." Watching network traffic." cr
   ." '.' is a good packet, 'X' is a bad packet.  Type any key to stop." cr
   begin
      packet-buf max-packet " read" net-ih $call-method  case
         -2 of  endof
         -1 of  ." X"  endof
	 ." ."
      endcase
   key?  until  key drop cr
   packet-buf max-packet free-mem
   net-ih close-dev
;
headers

: watch-net  ( [ "name" ] -- )
   parse-word dup  0=  if  2drop " net"  then   ( name )

   2dup " watch-net" execute-device-method  if
      2drop
   else
      "temp place
      " :promiscuous" "temp $cat        
      "temp count open-dev
      dup 0= abort" Can't open network device"
      (watch-net)
   then
;

: watch-net-all  ( -- )
   optional-arg-or-/$  " watch-net"   execute-all-methods
;
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
