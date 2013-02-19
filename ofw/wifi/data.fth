purpose: Supplicant data and environment data
\ See license at end of file

\ =======================================================================
\ Interface to parents

: mac-adr$  ( -- adr len )  " get-mac-address" $call-parent  ;
: wpa-ie$   ( -- adr len )  " wpa-ie$" $call-parent  ;
: write-force  ( adr len -- actual )  " write-force" $call-parent  ;
: read-force   ( adr len -- actual )  " read-force"  $call-parent  ;
: scan  ( adr len chan -- false | actual true )  " scan"  $call-parent  ;
: enable-rsn   ( -- )  " enable-rsn"  $call-parent drop  ;
: disable-rsn  ( -- )  " disable-rsn" $call-parent drop  ;
: disable-wep  ( -- )  " disable-wep" $call-parent drop  ;
: set-wep    ( wep4$ wep3$ wep2$ wep1$ idx -- )  " set-wep"   $call-parent drop  ;
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
: set-gtk-idx  ( n -- )  " set-gtk-idx" ['] $call-parent catch  if  3drop  then  ;
: disconnected?  ( -- flag )  " disconnected?" $call-parent  ;

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

\ =====================================================================
\ Country/region tables

: $, ( adr len -- )  here over allot  swap move  ;

create countries
   " US " $, h# 10 c,	\ US FCC
   " CA " $, h# 10 c,	\ IC Canada
   " SG " $, h# 10 c,	\ Singapore
   " EU " $, h# 30 c,	\ ETSI
   " AU " $, h# 30 c,	\ Australia
   " KR " $, h# 30 c,	\ Republic of Korea
   " ES " $, h# 31 c,	\ Spain
   " FR " $, h# 32 c,	\ France
   " JP " $, h# 40 c,	\ Japan
   "    " $, h#  0 c,   \ END OF LIST

: country>region  ( country$ -- region )
   countries  begin  dup 3 + c@  while   ( country$ adr )
      3dup swap comp  0=  if             ( country$ adr )
         nip nip 3 + c@ exit
      then                               ( country$ adr )
      4 +                                ( country$ adr' )
   repeat                                ( country$ adr' )
   3drop 0
;

create regions
   \ US        Len   	Channels 1-11, 100mW
   h# 10 c,    3 c,     1 c, d# 11 c, d# 20 c,	

   \ EU        Len 	Channels 1-13, 100mW
   h# 30 c,    3 c,     1 c, d# 13 c, d# 20 c,

   \ ES        Len 	Channels 10-11, 100mW
   h# 31 c,    3 c,     d# 10 c, 2 c, d# 20 c,

   \ FR        Len 	Channels 10-13, 100mW
   h# 32 c,    3 c,     d# 10 c, 4 c, d# 20 c,

   \ JP        Len 	Channels 1-13, 50mW	Channel 14, 50mW
   h# 40 c,    6 c,     1 c, d# 13 c, d# 16 c,  d# 14 c, 1 c, d# 16 c,	

   0 c,   \ END OF LIST

\ Seach the regions table
: region>ch/pwr  ( region-code -- ch-adr,len )
   regions  begin  dup c@  while   ( region-code adr )
      2dup c@ =  if                ( region-code adr )
         nip ca1+ count exit       ( region-code adr )
      then                         ( region-code adr )
      ca1+ count +                 ( region-code adr' )
   repeat                          ( region-code adr )
   2drop null$
;

d# 15 3 * dup constant /country-ie   buffer: country-ie-buf

\ country>ie fills country-ie with the country followed by the region info

0 instance value country-ie-len

: set-country-ie  ( country$ -- )
   country-ie-buf /country-ie erase                   ( country$ )
   2dup country>region ?dup 0=  if  2drop exit  then  ( country$ region# )
   region>ch/pwr dup 0=  if  4drop exit  then         ( country$ ch-adr,len )
   tuck country-ie-buf 3 + swap move                  ( country$ len )
   over + to country-ie-len                           ( country$ )
   3 max country-ie-buf swap move                     ( )
;

false value debug?
false instance value scan?

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
: last-rcnt@  ( -- d )  wifi >last-rcnt be-x@  ;
: last-rcnt!  ( d -- )  wifi >last-rcnt be-x!  ;

: last-rcnt++ ( -- )  last-rcnt@ 1. d+ last-rcnt!  ;

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
   -1. last-rcnt!
;

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
