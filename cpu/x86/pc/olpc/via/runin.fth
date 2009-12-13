\ Post-runin boot script $Revision$

visible

\ Location of the files containing KA tag data
: ka-dir$  ( -- adr len )  " http:\\10.0.0.1\ka\"  ;

: nocase-$=  ( $1 $2 -- flag )
   rot tuck <>  if       ( adr1 adr2 len2 )
      3drop false exit   ( -- false )
   then                  ( adr1 adr2 len2 )
   caps-comp 0=          ( flag )
;

: .instructions  ( adr len -- )
   cr blue-letters  type  black-letters  cr
;
: .problem  ( adr len -- )
   red-letters type  black-letters cr
;

\ The Linux-based runin selftests put this file at int:\runin\olpc.fth
\ after they have finished.  On the next reboot, OFW thus boots this
\ script instead of int:\boot\olpc.fth .  This script either displays
\ the failure log (if int:\runin\fail.log is present) or modifies the
\ manufacturing data tags to cause the next boot to enter final test.

d# 20 buffer: sn-buf
: sn$  ( -- adr len )  sn-buf count  ;

: try-scan-sn  ( -- gotit? )
   sn-buf 1+ d# 20 accept   ( n )
   d# 12 <>  if
      " Wrong length, try again" .problem
      false exit
   then
   sn-buf 1+ " TSHC" comp  if
      " Must begin with TSHC, try again" .problem
      false exit
   then
   sn-buf 2+  sn-buf 1+  d# 11 move  \ Elide the T
   d# 11 sn-buf c!
   true
;

: scan-sn  ( -- )
   ." *****"

   begin
      " Please Input Serial Number ......" .instructions
      try-scan-sn
   until
;

: board#$  ( -- adr len )
   " B#" find-tag  0= abort" Missing B# tag !!!"
   -null
;

: get-info  ( -- )
   scan-sn
;

0 0 2value response$

: final-filename$  ( -- adr len )  board#$ " %s.txt"  ;

\ Send the board number as the request and return the response data
: final-tag-exchange  ( -- )
   final-filename$ open-temp-file
   sn$              " SN:"  put-key+value
   " Request" submit-file
   " Response" get-response  to response$ 
;

: show-result-screen  ( -- )
   pass?  if
      clear-screen
      ." PASS" cr cr
      green-screen
   else
      ." FAIL" cr cr
      red-screen
   then
;

: put-ascii-tag  ( value$ key$ -- )
   2swap  dup  if  add-null  then  2swap  ( value$' key$ )
   ($add-tag)                             ( )
;
: put-ka-tag  ( value$ key$ -- )
   2over  8 min  ka-dir$ " %s%s" sprintf  ( value$ key$ filename$ )
   $read-file  if                     ( value$ key$ )
      ." ERROR: No KA tag file for " 2swap type cr  ( key$ )
      2drop                           ( )
   else                               ( value$ key$ file-data$ )
      2swap ($add-tag)                ( value$ )
      2drop                           ( )
   then
;

false value write-protect?

: special-tag?  ( value$ key$ -- true | value$ key$ false )
   2dup " KA" $=  if                       ( value$ key$ )
      put-ka-tag                           ( )
      true  exit                           ( -- true )
   then                                    ( value$ key$ )
   2dup " WP" nocase-$=  if                ( value$ key$ )
      2drop " 0" $=  0= to write-protect?  ( )
      true exit                            ( -- true )
   then                                    ( value$ key$ )
   2dup " ak" nocase-$=  if                ( value$ key$ )
      2drop " 0" $=  0=  if                ( )
         " "  " ak"  ($add-tag)            ( )
      then                                 ( )
      true exit                            ( -- true )
   then                                    ( value$ key$ )
   false                                   ( value$ key$ false )
;
: put-tag  ( value$ key$ -- )
   special-tag?  if  exit  then
   put-ascii-tag
;
: show-tag  ( value$ -- )
   $tag-printable?  if  ?-null type  else  wrapped-cdump  then
;
: do-tag-error  ( -- )
   \ Don't know what to do here
   begin halt again
;
: handle-tag  ( value$ key$ -- )
   2dup find-tag  if  ( value$ key$ old-value$ )       \ Tag already exists, check it
      2over " KA" $=  0=  if  ?-null  then   ( value$ key$ old-value$' )
      2>r 2over 2r@ $=  if                   ( value$ key$ r: old-value$' )
         2drop 2drop r> 2drop                ( )
      else                                   ( value$ key$ r: old-value$' )
         type ." tag changed!" cr            ( value$ r: old-value$' )
         ."   Old: " r> show-tag cr          ( value$ )
         ."   New: " show-tag cr             ( )
         do-tag-error
      then
   else                                      ( value$ key$ )   \ New tag, add it
      put-tag
   then
;

\ Remove possible trailing carriage return from the line
: ?remove-cr  ( adr len -- adr len' )
   dup  if                        ( adr len )
      2dup + 1- c@ carret =  if   ( adr len )
         1-
      then
   then
;

: parse-tags  ( adr len -- )
   begin  dup  while              ( adr len )
      linefeed left-parse-string  ( rem$ line$ )
      ?remove-cr                  ( rem$ line$ )
      [char] : left-parse-string  ( rem$ value$ key$ )
      dup 2 =  if                 ( rem$ value$ key$ )
         handle-tag               ( rem$ )
      else                        ( rem$ value$ key$ )
         4drop                    ( rem$ )
      then                        ( rem$ )
   repeat                         ( adr len )
   2drop                          ( )
;
: format-date  ( s m h d m y -- adr len )
   push-decimal
   >r >r >r >r >r >r
   <#
   [char] Z hold
   r> u# u# drop
   r> u# u# drop
   r> u# u# drop
   [char] T hold
   r> u# u# drop
   r> u# u# drop
   r> u# u# u# u#
   u#>
   pop-base
;
: make-md-tag  ( -- )
   ntp>time&date  ( s m h d m y )  format-date  " MD" put-ascii-tag
;
: inject-tags  ( -- )
   get-mfg-data

   " TS" ($delete-tag)
   " MS" ($delete-tag)
   " BD" ($delete-tag)
   make-md-tag
   " SHIP"  " TS" ($add-tag)

   response$ parse-tags

   flash-write-enable
   (put-mfg-data)
   \ Change "ww" to "wp" if we want security to be enabled
   write-protect?  if  " wp"  h# efffe  write-spi-flash  then
   no-kbc-reboot
   kbc-on
;

: mfg-ntp-server  ( -- name$ )
   " NT" find-tag  if  ?-null  else  " 10.60.0.2"  then
;
' mfg-ntp-server to ntp-servers

d# 4 constant rtc-threshold
: verify-rtc-date  ( -- )
\ XXX check RTC power lost bit
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

: put-key:value  ( value$ key$ -- )  " %s:%s" sprintf put-key-line  ;

: upload-tag  ( data$ tag$ -- )
   2dup " wp" $=  if                       ( data$ tag$ )
      4drop  " 1" " WP" put-key:value      ( )
      exit
   then
   2dup " ww" $=  if                       ( data$ tag$ )
      4drop  " 0" " WP" put-key:value      ( )
      exit
   then
   2dup " ak" $=  if                       ( data$ tag$ )
      4drop  " 1" " ak" put-key:value      ( )
      exit
   then
   2dup " KA" $=  if                       ( data$ tag$ )
      4drop                                ( )
      exit
   then
   2dup " SG" $=  if                       ( data$ tag$ )
      4drop                                ( )
      exit
   then                                    ( data$ tag$ )

   put-key:value                           ( )
;

: upload-tags  ( -- )
   mfg-data-top                 ( adr )
   begin  another-tag?  while   ( adr' data$ tname-adr )
      2 upload-tag              ( adr )
   repeat                       ( adr )
   drop
;


\ Upload the result data 
: final-result  ( -- )
   final-filename$  open-temp-file
   upload-tags
   pass?  if  " PASS"  else  " FAIL"  then  " RESULT="  put-key+value
   " Result" submit-file
;

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

: finish-final-test  ( -- )
   wait-connections

   get-info

   verify-rtc-date

   ." Getting final tags .. "
   cifs-connect final-tag-exchange cifs-disconnect
   ." Done" cr

   inject-tags

   cifs-connect final-result cifs-disconnect
   \ " int:\runin\olpc.fth" $delete-all

   \ Ultimately this should just be delete of runin\olpc.fth
   " int:\runin\olpc.fth" " int:\runin\final.fth" $rename
;

\ Make the "wait for SD insertion" step highly visible 
dev ext
warning @  warning off
: wait&clear  ( -- error? )  wait-card? page  ;
patch wait&clear wait-card? selftest
: selftest  ( -- )  page show-pass  selftest  ;
warning !
dend


: fail-log-file$  ( -- name$ )  " int:\runin\fail.log"   ;

\ The operator can type this to reset the state to run
\ the Linux-based runin tests again.
: rerunin  ( -- )
   " int:\runin\olpc.fth" $delete-all
   " int:\runin\fail.log" $delete-all
;

: after-runin  ( -- )
   fail-log-file$ $read-file  0=  if  ( adr len )
      page
      show-fail
      ." Type a key to see the failure log"
      key drop  cr cr
      list
   else
      autorun-mfg-tests
      pass?  if  finish-final-test  then
      show-result-screen
   then

   ." Type a key to power off"
   key cr
   power-off
;

after-runin

0 [if]

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
B#:
P#:
M#:
LA:
CC:
F#:
L#:
S#:
T#:
WM:
MN:
BV:
U#:
SD:
WP:
LO:
  KA
KM:
KL:
KV:
  ak
  sk
  SG
  DT
     TS:  test station
     SS:  smt status
     FQ:  ??

RESULT:PASS
[then]
