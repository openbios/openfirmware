\ See license at end of file
purpose: IP redirector package

dev /packages
new-device
" ip" device-name

headerless
0 value #ip-opens
0 value we-opened?

: call-tftp:  ( "name" -- )
   create  does>  body> find-name name>string $call-parent
;

headers
: close  ( -- )
   #ip-opens 1- dup  0 max  to #ip-opens      ( open-level )
   0=  if
      we-opened?  false to we-opened?  if  exit  then
   then
   0 to my-parent
;

: open  ( -- flag )
   #ip-opens 1+ to #ip-opens

   obp-tftp-ih  if
      obp-tftp-ih to my-parent
      true  exit
   then

   " net//obp-tftp:last" open-dev  to my-parent    ( )

   true to we-opened?
   true
;

call-tftp: send-udp-packet  ( adr len src-port dst-port -- )
call-tftp: receive-udp-packet  ( dst-port -- true | adr len src-port false )
call-tftp: allocate-udp  ( payload-len -- payload-adr )
call-tftp: free-udp  ( payload-adr payload-len -- )

call-tftp: send-ip-packet  ( adr len protocol -- )
call-tftp: receive-ip-packet  ( type -- true | adr len false )
call-tftp: allocate-ip  ( payload-len -- payload-adr )
call-tftp: free-ip  ( payload-adr payload-len -- )

call-tftp: unlock-ip-address  ( -- )

call-tftp: set-timeout     ( #milliseconds -- )
call-tftp: update-timeout  ( -- )
call-tftp: compute-srtt   ( -- )
call-tftp: name-server-ip  ( -- 'ip )
call-tftp: domain-name     ( -- 'ip )
call-tftp: next-xid        ( -- id )
call-tftp: my-ip-addr      ( -- 'ip )
call-tftp: his-ip-addr     ( -- 'ip )
call-tftp: netmask         ( -- 'ip )
call-tftp: set-dest-ip     ( 'ip -- )
call-tftp: $set-host ( hostname$ -- )
call-tftp: oc-checksum     ( n adr len -- n' )
call-tftp: link-mtu        ( -- n )
call-tftp: max-ip-payload  ( -- n )
call-tftp: alloc-udp-port  ( -- port# )

finish-device
device-end
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
