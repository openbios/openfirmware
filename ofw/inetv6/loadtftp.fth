\ See license at end of file
purpose: Load file for (TFTP) network booting package


\ Load file for Trivial File Transfer Protocol (TFTP) network booting package

headers
fload ${BP}/ofw/inetv6/macaddr.fth	\ MAC address sensing and display

defer show-progress
\ : show-address  ( adr -- adr )  dup (cr .  ;

0 value meter-counter
: -/|\ ( -- adr ) " -/|\" drop ;
: show-meter  ( adr -- adr )  \ show progress by toggle meter
   meter-counter 1+ dup is meter-counter   ( counter )
   \ one can change frequency of display by changing following number
   d# 10
   /mod swap  if    ( smaller-counter )
      drop
   else             ( smaller-counter )
      4 mod -/|\ + c@ emit 1 backspaces
   then 	    (   )
;
' show-meter is show-progress

headers
0 value bootnet-debug  \ XXX ???? XXX
: debug-net  ( -- )  true to bootnet-debug  ;
: undebug-net  ( -- )  false to bootnet-debug  ;

0 value udp-checksum?
d# 100 constant tftp-retries

defer setup-ip-attr
['] noop is setup-ip-attr     \ for proms not requiring ip-addr as properties.

create use-dhcp
create do-ip-frag-reasm

0 value rpc-xid
0 value obp-tftp-ih

[ifdef] resident-packages
dev /packages new-device
   start-module
      " obp-tftp" device-name
      fload ${BP}/ofw/inetv6/loadpkg.fth
   end-module
finish-device device-end
[then]

\ params: debug-net debug-ip debug-udp debug-bootp undebug-net
: (show-net)  ( adr len -- )
   0 0 " obp-tftp" $open-package  ?dup  if
      dup >r  $call-method
      r> close-package
   else
      2drop
   then
;
: show-net  ( -- )    " debug-net" (show-net)  ;
: show-ip   ( -- )    " debug-ip"  (show-net)  ;
: show-udp  ( -- )    " debug-udp" (show-net)  ;
: show-bootp  ( -- )  " debug-bootp" (show-net)  ;

fload ${BP}/ofw/inetv6/watchnet.fth         \ Watch-net command

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
