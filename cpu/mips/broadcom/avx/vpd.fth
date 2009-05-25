purpose: Specific name=value VPD variable manager
copyright: Copyright 2001 FirmWorks  All Rights Reserved

hex

\ Serial number words
: (get-vpd-serial$)  ( -- $ )
   " serial-num" $getvpd  if
      " serial-num not found"
   then
;
: get-vpd-serial$  ( -- $ )  select-fixed-vpd (get-vpd-serial$)  ;
: (.vpd-serial$)  ( -- )  (get-vpd-serial$) type  ;
: .vpd-serial$  ( -- )  select-fixed-vpd (.vpd-serial$)  ;

\ Ethernet mac address words
0 value mac-cnt
: (get-vpd-mac$)  ( -- true | mac$ false )  " eth-mac-addr" $getvpd  ;
: get-vpd-mac$  ( -- true | mac$ false )  select-fixed-vpd (get-vpd-mac$)  ;
: (get-vpd-mac#)  ( -- true | m6 m5 m4 m3 m2 m1 false )
   (get-vpd-mac$) ?dup  if  exit  then
   0 to mac-cnt
   ( mac$ )  6 0  do
      ascii : left-parse-string
      $number  ?leave
      dup d# 255 >  if  drop leave  then
      -rot
      mac-cnt 1+ to mac-cnt
   loop
   ( rem-mac$ )  nip
   mac-cnt 6 <> or  if
      mac-cnt 0  ?do  drop  loop  true
   else
      swap 2swap swap 2>r 2swap swap 2r> 2swap false
   then
;
: get-vpd-mac#  ( -- true | m6 m5 m4 m3 m2 m1 false )
   select-fixed-vpd (get-vpd-mac#)
;
: (.vpd-mac)  ( -- )
   (get-vpd-mac$)  if  " eth-mac-addr not found"  then
   type
;
: .vpd-mac  ( -- )  select-fixed-vpd (.vpd-mac)  ;
