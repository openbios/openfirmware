\ Post-runin boot script $Revision$

visible

\ The Linux-based runin selftests put this file at int:\runin\olpc.fth
\ after they have finished.  On the next reboot, OFW thus boots this
\ script instead of int:\boot\olpc.fth .  This script either displays
\ the failure log (if int:\runin\fail.log is present) or modifies the
\ manufacturing data tags to cause the next boot to enter final test.

d# 20 buffer: sn-buf
: sn$  ( -- adr len )  sn-buf count  ;

: try-get-sn  ( -- )
   sn-buf 1+ d# 20 accept   ( n )
   d# 12 <>  if
      " Wrong length, try again" .problem
      exit
   then
   sn-buf 1+ " TSHC" comp  if
      " Must begin with TSHC, try again" .problem
      exit
   then
   sn-buf 2+  sn-buf 1+  d# 11 move  \ Elide the T
   d# 11 sn-buf c!
;

: get-sn  ( -- )
   ." *****"

   begin
      " Please Input Serial Number ......" .instructions
      try-get-sn
   sn-acquired? until
;

: board#$  ( -- adr len )
   " B#" find-tag  0= abort" Missing B# tag !!!"
   -null
;

: get-info  ( -- )
   get-sn
;

0 0 2value response$

\ Send the board number as the request and return the response data
: final-tag-exchange  ( -- )
   board#$ " %s.txt" open-temp-file
   sn$              " SN:"  put-key+value
   " Request" submit-file
   " Response" get-response  to response$ 
;

0 value test-passed?
: show-result-screen  ( -- )
   restore-scroller
   clear-screen
   test-passed?  if
      ." Selftest passed." cr cr cr
      green-screen
   else
      ." Selftest failed." cr cr cr
      red-screen
   then
   d# 2000 ms
;

: parse-tags  ( adr len -- )
   begin  dup  while              ( adr len )
      linefeed left-parse-string  ( rem$ line$ )
      ?remove-cr                  ( rem$ line$ )
      [char] : left-parse-string  ( rem$ value$ key$ )
      dup 2 =  if                 ( rem$ value$ key$ )
         put-tag                  ( rem$ )
      else                        ( rem$ value$ key$ )
         4drop                    ( rem$ )
      then                        ( rem$ )
   repeat                         ( adr len )
   2drop                          ( )
;

: inject-tags  ( -- )
   get-mfg-data

   " TS" ($delete-tag)
   " MS" ($delete-tag)
   " BD" ($delete-tag)

   " SHIP"  " TS" ($add-tag)

   response$ parse-tags

   put-mfg-data
;

: mfg-ntp-server  ( -- name$ )
   " NT" find-tag  if  ?-null  else  " 10.60.0.2"  then
;
' mfg-ntp-server to ntp-servers

d# 4 constant rtc-threshold
: verify-rtc-date  ( -- )
   ." Getting time from NTP server "
   begin  ntp-timestamp  while  ." Retry "  repeat  ( d.timestamp )
   cr
   ntp>time&date unix-seconds>  ( ntp-seconds )
   today unix-seconds>          ( ntp-seconds rtc-seconds )
   -                            ( difference )
   dup rtc-threshold >  if      ( difference )
      page show-fail
      ." Clock lost " .d ." seconds since SMT"  cr
      begin  halt  again
   else
      abs rtc-threshold >  if
         page show-fail
         ." Clock gained " .d ." seconds since SMT"  cr
         begin  halt  again
      then
   then
;

: finish-final-test  ( -- )
   show-result-screen

   test-passed?  0=  if
      ." Type a key to power off "
      key drop cr  power-off
   then

   wait-lan
   wait-scanner

   get-info

   verify-rtc-date

   cifs-connect
   ." Connecting to server "  final-tag-exchange  ." Done" cr
   cifs-disconnect

   inject-tags

   ." Powering off ..." d# 2000 ms
   power-off
;

d# 15 to #mfgtests

: final-tests  ( -- )
   5 #mfgtests +  5 do
      i set-current-sq
      refresh
      d# 1000 ms
      doit
      pass? 0= if  false to test-passed?  finish-final-test  unloop exit  then
   loop
   true to test-passed?  finish-final-test
;

\ Make the "wait for SD insertion" step highly visible 
dev ext
warning @  warning off
: selftest  ( -- )  page show-pass  selftest  ;
warning !
dend

\ This modifies the menu to be non-interactive
: doit-once  ( -- )  do-key  final-tests  ;
patch doit-once do-key menu-interact

: scanner?  ( -- flag )
   " usb-keyboard" expand-alias  if  2drop true  else  false  then
;   
: wait-scanner  ( -- )
   scanner?  0=  if
      " Connect USB barcode scanner"  .instructions
      begin  d# 1000 ms  silent-probe-usb  scanner?  until
   then
 ;
: wired-lan?  ( -- flag )
   " /usb/ethernet" locate-device  if  false  else  drop true  then
;
: wait-lan  ( -- )
   wired-lan?  0=  if
      " Connect USB Ethernet Adapter" .instructions
      begin  d# 1000 ms  silent-probe-usb  wired-lan?  until
   then
;
: usb-key?  ( -- flag )
   " /usb/disk" locate-device  if  false  else  drop true  then
;
: wait-usb-key  ( -- )
   usb-key?  0=  if
      " Connect USB memory stick" .instructions
      begin  d# 1000 ms  silent-probe-usb  usb-key?  until
   then
;
: wait-connections  ( -- )
   silent-probe-usb
   wait-scanner
   wait-lan
\   wait-usb-key
;             

: fail-log-file$  ( -- name$ )  " int:\runin\fail.log"   ;

: after-runin  ( -- )
   fail-log-file$ $read-file  0=  if  ( adr len )
      page
      show-fail
      ." Type a key to see the failure log"
      key drop  cr cr
      list
   else
\     set-tags-for-fqa
\      " int:\runin\olpc.fth" $delete-all

      " patch final-tests play-item mfgtest-menu" evaluate
      menu
      \ Shouldn't get here because the menu never exits
   then

   ." Type a key to power off"
   key cr
   power-off
;

after-runin

SN:SHC946009D3
B#:QTFJCA94400297
P#:1CL11ZU0KDU
M#:CL1
LA:USA
CC:2222XXXXXX
F#:F6
L#:J
S#:CL1XL00802000
T#:TSIMG_V3.0.6
WM:00-17-C4-B9-39-ED
MN:XO-1
BV:Q2E34
U#:A4112195-98FE-419A-A77B-9F33C08FF913
SD:241109
IM_IP:10.1.0.2
IM_ROOT:CL1XL00802000
IM_NAME:CL1XL00802000
WP:0
Countries:Alabama
LO:en_US.UTF-8
KA:USInternational_Keyboard
KM:olpc
KL:us
KV:olpc
ak:0
sk:20
SG:79
DT:20091124152811

SET WO=304027439

Use these info to check the tags inside the SPI flash.

Write the following tags from response file:

WP:
SG:

Get date time from NTP server 10.1.0.1 and write MD tag
        MD: 20081014T200700Z

Set TS tag to SHIP

Send the following information to shop flow

SN:
M#:
U#:
P#:
B#:
LA:
CC:
F#:
L#:
S#:
T#:
BV:
TS:
SS:
FQ:
SD:
WM:
MN:
KL:
KV:
KM:
LO:
WP:
RESULT:PASS

 

