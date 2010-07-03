purpose: User interface for NAND multicast updater - reception
\ See license at end of file

\ nb-zd-#sectors is the number of blocks that NANDblaster read in zdata mode
\ nb15_rx calls set-nb-zd-#sectors via the interpret client service.
-1 value nb-zd-#sectors
: set-nb-zd-#sectors  ( n -- )  to nb-zd-#sectors  ;

\ This is the wireless version
: nandblaster  ( -- )
   false to already-go?
   -1 to nb-zd-#sectors
   " boot rom:nb15_rx ssid:OLPC-NANDblaster" sprintf eval
;
alias nb nandblaster

\ This is the wired version that is used in the factory with big Ethernet switches.
: $nb-rx  ( multicast-ip$ -- )
   false to already-go?
   boot-as-call(
   ( multicast-ip$ )  " boot rom:nb15_rx mcast:%s" sprintf  eval
   )boot-as-call
;
: nb-rx:  ( "multicast-ip" -- )  safe-parse-word  $nb-rx  ;
: nb-rx  ( -- )  " 224.0.0.100" $nb-rx  ;

[ifdef] adhoc-NANDblaster
\ The adhoc version doesn't work well
: nba  ( "filename" -- )
   false to already-go?
   safe-parse-word
   " boot rom:nb_tx adhoc:OLPC-NANDblaster,239.255.1.2,1 %s 20 131072" sprintf eval
;
: rnba  ( -- )
   false to already-go?
   -1 to nb-zd-#sectors
   " boot rom:nb15_rx adhoc:OLPC-NANDblaster,239.255.1.2" sprintf eval
;
: lnba  ( "filename" -- )
   false to already-go?
   safe-parse-word
   " load rom:nb_tx adhoc:OLPC-NANDblaster,239.255.1.2,1 %s 20 131072" sprintf eval
;
[then]

create NB-sniffing
[ifdef] NB-sniffing
\ nbcount tests whether the receiver can keep up with the sender
0 value nb-ih
0 value #frames
: mcopen
   " net:force" open-dev to nb-ih
   nb-ih 0= abort" Can't open net"
   ['] null$ to default-ssids
   " OLPC-NANDblaster" $essid
   " do-associate" nb-ih $call-method drop
   " "(01 00 5e 7f 01 02)" " set-multicast" nb-ih $call-method
;
: mcclose  ( -- )  nb-ih close-dev  0 to nb-ih  ;
: nbcount  ( -- )
   mcopen cr
   begin
      load-base d# 2000 " read" nb-ih $call-method
      -2 <>  if
         1 #frames +!
         #frames @  d# 100 /mod  drop  0=  if
            #frames @ .d  (cr
         then
      then
   key? until  key drop
   mcclose
;
[then]

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
