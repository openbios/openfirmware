purpose: Supplicant data and environment data
\ See license at end of file

\ =======================================================================
\ Interface to parents

: mac-adr$  ( -- adr len )  " get-mac-address" $call-parent  ;
: wpa-ie$   ( -- adr len )  " wpa-ie$" $call-parent  ;
: write-force  ( adr len -- actual )  " write-force" $call-parent  ;
: read-force   ( adr len -- actual )  " read-force"  $call-parent  ;
: scan   ( adr len -- actual )  " scan"  $call-parent  ;
: enable-rsn   ( -- )  " enable-rsn"  $call-parent drop  ;
: disable-rsn  ( -- )  " disable-rsn" $call-parent drop  ;
: disable-wep  ( -- )  " disable-wep" $call-parent drop  ;
: set-wep    ( wep4$ wep3$ wep2$ wep1$ -- )  " set-wep"   $call-parent drop  ;
: associate  ( ch ssid$ target-mac$ -- ok? )     " associate" $call-parent  ;
: supported-rates$  ( -- adr len )  " supported-rates$" $call-parent  ;
: set-common-rates  ( adr len -- )  " set-common-rates" $call-parent  ;
: set-ptk   ( pkey$ -- )  " set-ptk"  $call-parent  ;
: set-gtk   ( gkey$ -- )  " set-gtk"  $call-parent  ;
: enforce-protection  ( -- )  " enforce-protection" $call-parent  ;
: disable-protection  ( -- )  " disable-protection" $call-parent  ;
: set-bss-type  ( bsstype -- )  " set-bss-type" $call-parent drop  ;
: set-cap  ( cap -- )  " set-cap" $call-parent  ;
: set-preamble  ( preamble -- )  " set-preamble" $call-parent  ;
: set-auth-mode  ( amode -- )  " set-auth-mode" $call-parent  ;
: set-key-type   ( ctp ctg ktype -- )  " set-key-type" $call-parent  ;
: set-country-info  ( adr len -- )  " set-country-info" $call-parent  ;
: set-atim-window   ( n -- )  " set-atim-window" $call-parent  ;

\ =======================================================================
\ Global data

true value first-open?

struct
   d# 16 field >kck			\ EAPOL-key confirmation key
   d# 16 field >kek			\ EAPOL-key encryption key
   d# 16 field >tk1			\ Temporal key 1
       0 field >tk2			\ Temporal key 2
   d#  8 field >tx-mic-key		\ Tx MIC key
   d#  8 field >rx-mic-key		\ Rx MIC key
constant /ptk				\ Pairwise temporal key (PTK)

d# 33 constant /ssid			\ Add one byte for 0 termination
8 constant /rcnt
6 constant /mac-adr

list: wifi-list
listnode
   /ssid    field >ssid			\ SSID
   /mac-adr field >my-mac		\ My mac address
   /mac-adr field >his-mac		\ Target mac address
   /c field >valid?			\ Validity flag
   /c field >channel			\ Channel
   /c field >ktype			\ Security type
   /c field >ctype-p			\ Pairwise key cipher type
   /c field >ctype-g			\ Group key cipher type
   /c field >atype			\ Authentication & AKM suite type
   /rcnt field >last-rcnt		\ Last replay counter
   /ptk field >ptk			\ Pairwise temporal key (PTK)
nodetype: wifi-node			\ Data to persist between opens

0 wifi-node !				\ Initialize to empty at compile time
0 wifi-list !				\ Initialize to empty at compile time

\ >ktype values
0 constant kt-wep
1 constant kt-wpa
2 constant kt-wpa2
h# ff constant kt-none

\ >ctype-x values
0 constant ct-none
1 constant ct-tkip
2 constant ct-aes

\ >atype values
0 constant at-none
1 constant at-eap
2 constant at-preshared

0 0 2value country-ie			\ Address of country IE


\ =======================================================================
\ Instance data 

false instance value debug?
false instance value scan?
false instance value country?
0 instance value wifi			\ Current wifi-node

: ptk  ( -- adr )  wifi >ptk  ;
: valid?    ( -- n )  wifi >valid?  c@  ;
: atype     ( -- n )  wifi >atype   c@  ;
: ktype     ( -- n )  wifi >ktype   c@  ;
: ctype-p   ( -- n )  wifi >ctype-p c@  ;
: ctype-g   ( -- n )  wifi >ctype-g c@  ;
: channel   ( -- n )  wifi >channel c@  ;
: valid!    ( n -- )  wifi >valid?  c!  ;
: atype!    ( n -- )  wifi >atype   c!  ;
: ktype!    ( n -- )  wifi >ktype   c!  ;
: ctype-p!  ( n -- )  wifi >ctype-p c!  ;
: ctype-g!  ( n -- )  wifi >ctype-g c!  ;
: channel!  ( n -- )  wifi >channel c!  ;
: target-mac$  ( -- adr len )  wifi >his-mac /mac-adr  ;
: target-mac!  ( adr -- )      wifi >his-mac /mac-adr move  ;
: my-mac$      ( -- adr len )  wifi >my-mac  /mac-adr  ;
: my-mac!      ( adr -- )      wifi >my-mac  /mac-adr move  ;
: ssid$       ( -- $ )  wifi >ssid cscount  ;
: ssid!       ( $ -- )  /ssid 1- min wifi >ssid dup /ssid erase swap move  ;
: last-rcnt   ( -- adr )  wifi >last-rcnt  ;
: last-rcnt!  ( adr -- )  wifi >last-rcnt /rcnt move  ;
: last-rcnt++ ( -- )
   wifi >last-rcnt 4 + dup be-l@ 1+ dup rot be-l!
   0=  if  wifi >last-rcnt dup be-l@ 1+ swap be-l!  then
;

: init-wifi-node  ( mac$ -- )
   drop my-mac!
   kt-none ktype!
   ct-none ctype-p!
   ct-none ctype-g!
   false valid!
;

: mac=?  ( mac$ node-adr -- mac$ mac$=? )
   >my-mac 2 pick 2 pick comp 0=
;

: init-wifi-data  ( mac$ -- )
   wifi-list ['] mac=? find-node ?dup  if
      \ Retrieve saved data for an existing node
      to wifi  3drop
   else
      \ Create a new node
      wifi-node allocate-node dup to wifi
      swap insert-after
      init-wifi-node
   then
   last-rcnt /rcnt ff fill
;


\ =======================================================================
\ wifi-cfg data

: adrlen@   ( src -- adr len )  dup @ swap na1+ @  ;
: wifi-ssid$  ( -- $ )  wifi-cfg >wc-ssid adrlen@  ;
: wifi-pmk$   ( -- $ )  wifi-cfg >wc-pmk  adrlen@  ;
: wifi-wep1$  ( -- $ )  wifi-cfg >wc-wep1 adrlen@  ;
: wifi-wep2$  ( -- $ )  wifi-cfg >wc-wep2 adrlen@  ;
: wifi-wep3$  ( -- $ )  wifi-cfg >wc-wep3 adrlen@  ;
: wifi-wep4$  ( -- $ )  wifi-cfg >wc-wep4 adrlen@  ; 
: wifi-wep-idx   ( -- n )  wifi-cfg >wc-wep-idx @ 1- 0 max 4 min  ;
: wifi-country$  ( -- $ )  wifi-cfg >wc-country 3  ;

: set-country  ( adr len -- )  2dup upper  country>ie to country-ie  ;


\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
