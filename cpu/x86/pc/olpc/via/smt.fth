\ SMT test script $Revision$

visible

: wanted-fw$  ( -- $ )  " q3a20"  ;


: nocase-$=  ( $1 $2 -- flag )
   rot tuck <>  if       ( adr1 adr2 len2 )
      3drop false exit   ( -- false )
   then                  ( adr1 adr2 len2 )
   caps-comp 0=          ( flag )
;

: find-firmware-file  ( -- name$ )
   wanted-fw$  " u:\\boot\\%s.rom" sprintf    ( name$ )
   ." Trying " 2dup type cr                 ( name$ )
   2dup $file-exists?  if  exit  then       ( name$ )
   2drop                                    ( )

   wanted-fw$ factory-server$ " %s\\%s.rom" sprintf  ( name$ )
   ." Trying " 2dup type cr                 ( name$ )
   2dup $file-exists?  if  exit  then       ( name$ )
   2drop

   true  abort" Can't find new firmware file" 
;

: ?update-firmware  ( -- )
   \ Exit if the existing firmware and the wanted firmware are the same
   fw-version$  wanted-fw$  nocase-$=  if  exit  then
   ." Updating firmware to version " fw-version$ type cr
   d# 2000 ms
   ?enough-power
   find-firmware-file  $get-file  reflash
;

: mfg-ntp-server  ( -- name$ )
   " NT" find-tag  if  ?-null  else  " 10.60.0.2"  then
;
' mfg-ntp-server to ntp-servers

: .instructions  ( adr len -- )
   cr blue-letters  type  black-letters  cr
;
: .problem  ( adr len -- )
   red-letters type  black-letters cr
;

d# 20 buffer: bn-buf  \ Buffer for scanned-in board number string
: board#$  ( -- adr len )  bn-buf count  ;

: accept-to-buf  ( buf len -- actual )
   over 1+ swap accept  ( buf actual )
   tuck swap c!         ( actual )
;

\ Get a board number from the user, retrying until valid
\ Usually the number is entered with a barcode scanner
: get-board#  ( -- )
   ." *****"
   begin
      " Please Input Board Number ......" .instructions
      bn-buf d# 20 accept-to-buf   ( n )
      d# 14 <>  if
         " Wrong length (must be 14 characters), try again" .problem
      else
         bn-buf 1+ c@ [char] Q =  if  exit  then
         " Must begin with Q, try again" .problem
      then
   again
;

d# 20 buffer: station#-buf
: station#$  ( -- adr len )  station#-buf count  ;  \ e.g. J01

: get-station#  ( -- )
   ." *****"
   begin
      " Please Input Station Number ......" .instructions

      station#-buf d# 20 accept-to-buf   ( n )
      d# 3 <>  if
         " Wrong length (must be like J01), try again" .problem
      else
         station#-buf 1+ c@ [char] A [char] Z between  if  exit  then
         " Must begin with A-Z, try again" .problem
      then
   again
;

d# 20 buffer: opid-buf
: opid$  ( -- adr len )  opid-buf count  ;  \ e.g. 12345678

\ Get and validate an operator ID
: get-opid  ( -- )
   ." *****"
   begin
      " Please Input Operator ID ......" .instructions
      opid-buf d# 20 accept-to-buf   ( n )

      d# 8 <>  if
         " Wrong length (must be 8 digits), try again" .problem
      else
         opid$  push-decimal  $number  pop-base  if   ( )
            " Must be a number, try again" .problem
         else                                         ( n )
            drop exit
         then
      then
   again
;

\ Construct the filename used for communicating with the server
d# 20 buffer: filename-buf
: smt-filename$  ( -- adr len )  filename-buf count  ;
: set-filename  ( -- )
   board#$ " %s.txt" sprintf  filename-buf place
;

: get-info  ( -- )
   get-board#
   set-filename
   get-station#
   get-opid
;

0 value test-passed?

\ Upload the result data 
: smt-result  ( -- )
   smt-filename$  open-temp-file
   test-passed?  if  " PASS"  else  " FAIL"  then  " RESULT="  put-key+value
   " PROCESS=FVT" put-key-line
   " STATION="    put-key-line
   " OPID="       put-key-line
   " GUID="       put-key-line
   board#$  " MB_NUM=" put-key+value
   " Result" submit-file
;

\ Send the board number as the request and return the response data
: smt-request$  ( -- adr len )
   smt-filename$ open-temp-file
   board#$          " MB_NUM="  put-key+value
   opid$            " OPID="    put-key+value
   station#$        " STATION=" put-key+value
   " Request" submit-file
   " Response" get-response
;

: clear-mfg-buf  ( -- )  mfg-data-buf  /flash-block  h# ff fill  ;

\ Remove possible trailing carriage return from the line
: ?remove-cr  ( adr len -- adr len' )
   dup  if                        ( adr len )
      2dup + 1- c@ carret =  if   ( adr len )
         1-
      then
   then
;

: put-ascii-tag  ( value$ key$ -- )
   2swap  dup  if  add-null  then  2swap  ( value$' key$ )
   ($add-tag)                             ( )
;

1 buffer: sg-buf
: special-tag?  ( value$ key$ -- true | value$ key$ false )
   2dup " SG" $=  if                            ( value$ key$ )
      2swap                                     ( key$ value$ )
      over " 0x" comp  0=  if  2 /string  then  ( key$ value$' )
      push-hex $number pop-base  abort" Invalid tag value: SG tag value is not a hex number"  ( key$ n )
      dup  h# ff u>  abort" Invalid tag value: SG tag value will not fit in one byte"         ( key$ n )
      sg-buf c!  sg-buf 1  2swap  ($add-tag)    ( )
      true  exit
   then                                         ( value$ key$ )
   false
;

: put-tag  ( value$ key$ -- )
   special-tag?  if  exit  then
   put-ascii-tag
;

0 0 2value response$

false value any-tags?

\ If the server sends us tags in the response file, we put
\ them in the mfg data
: write-new-tags  ( adr len -- )
   begin  dup  while              ( adr len )
      linefeed left-parse-string  ( rem$ line$ )
      ?remove-cr                  ( rem$ line$ )
      [char] = left-parse-string  ( rem$ value$ key$ )
      dup 2 =  if                 ( rem$ value$ key$ )
         true to any-tags?        ( rem$ value$ key$ )
         put-tag                  ( rem$ )
      else                        ( rem$ value$ key$ )
         4drop                    ( rem$ )
      then                        ( rem$ )
   repeat                         ( adr len )
   2drop                          ( )
;

\ Decode the server's response and insert appropriate mfg data tags
: parse-smt-response  ( -- )
   ." Server responded with:  "  cr  response$ list cr    ( )

   response$ nip 0=  if  ." Null manufacturing data" cr  exit  then

   clear-mfg-buf                          ( )
   " "      " ww"  ($add-tag)             ( )

   response$ write-new-tags               ( )

\   board#$  " B#"  put-ascii-tag         ( )
\   " EN"    " SS"  put-ascii-tag         ( )
\   " ASSY"  " TS"  put-ascii-tag         ( )
\   " "(D3)" " SG"  ($add-tag)            ( )

   any-tags?  if
      flash-write-enable
      (put-mfg-data)
      no-kbc-reboot
      kbc-on
   then
;

: silent-probe-usb  ( -- )
   " /" ['] (probe-usb2) scan-subtree
   " /" ['] (probe-usb1) scan-subtree
   report-disk report-net report-keyboard
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
: stall  ( -- )  begin  halt  again  ;
: require-int-sd  ( -- )
   " int:0" open-dev  ?dup  if  close-dev exit  then
   " Power off and insert internal SD card" .problem
   stall
;

: wait-connections  ( -- )
   require-int-sd
   silent-probe-usb
   wait-scanner
   wait-lan
   wait-usb-key
;             

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

: finish-smt-test  ( pass? -- )
   show-result-screen

   ." Sending test result "
   cifs-connect  smt-result  cifs-disconnect
   ." Done" cr

   test-passed?  if
      ." Writing tags "  parse-smt-response  ." Done" cr
   then

   any-tag? 0=  if
      cr cr cr
      " WARNING: Invalid response from shop floor server - no tags." .problem
      cr cr cr
      begin  halt  again
   then    ( )

   ." Powering off ..." d# 2000 ms
   power-off
;

d# 15 to #mfgtests

: smt-tests  ( -- )
   5 #mfgtests +  5 do
      i set-current-sq
      refresh
      d# 1000 ms
      doit
      pass? 0= if  false to test-passed?  finish-smt-test  unloop exit  then
   loop
   true to test-passed?  finish-smt-test
;

\ This modifies the menu to be non-interactive
: doit-once  ( -- )  do-key  smt-tests  ;
patch doit-once do-key menu-interact

: start-smt-test  ( -- )
   ?update-firmware

   wait-connections

   ." Setting clock "  ntp-set-clock  ." Done" cr

   get-info

   ." Getting SMT tags .. "
   ." Connecting .. "  cifs-connect ." Connected .. "
   smt-request$  to response$
   cifs-disconnect
  ." Done" cr

   true to diag-switch?
   " patch smt-tests play-item mfgtest-menu" evaluate
   menu
   false to diag-switch?
;

dev /wlan
: selftest  ( -- error? )
   true to force-open?  open  false to force-open?  ( opened? )
   if  close false  else  true  then                ( error? )
;
dend

\ Automatically run the sequence
start-smt-test
