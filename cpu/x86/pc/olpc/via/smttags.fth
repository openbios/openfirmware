\ SMT test

\ visible

\ This is for testing, until we get the MS tag injected into the final image
[ifdef] factory-server$
: set-server  ( -- )
   factory-server$  nip  0=  if
      " cifs:\\bekins:bekind2@10.60.0.2\nb2_fvs" to factory-server$
   then
;
[then]

: .instructions  ( adr len -- )
   cr blue-letters  type  black-letters  cr
;
: .problem  ( adr len -- )
   red-letters type  black-letters cr
;

d# 20 buffer: bn-buf  \ Buffer for scanned-in board number string
: scanned-board#$  ( -- adr len )  bn-buf count  ;

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
         " Wrong length, try again" .problem
      else
         bn-buf 1+ c@ [char] Q =  if  exit  then
         " Must begin with Q, try again" .problem
      then
   again
;

d# 20 buffer: station#-buf
: station#$  ( -- adr len )  station#-buf count  ;  \ e.g. 01

: get-station#  ( -- )
   ." *****"
   begin
      " Please Input Station Number ......" .instructions

      station#-buf d# 20 accept-to-buf   ( n )
      d# 2 <>  if
         " Wrong length, try again" .problem
      else
         station#$  push-decimal  $number  pop-base  if  ( )
            " Must be a number, try again" .problem
         else                                            ( n )
            drop exit
         then
      then
   again
;

d# 20 buffer: opid-buf
: opid$  ( -- adr len )  opid-buf count  ;  \ e.g. A001

\ Get and validate an operator ID
: get-opid  ( -- )
   ." *****"
   begin
      " Please Operator ID ......" .instructions
      opid-buf d# 20 accept-to-buf   ( n )
      d# 4 <>  if
         " Wrong length, try again" .problem
      else
         opid-buf 1+ c@ [char] A =  if  exit  then
         " Must begin with A, try again" .problem
      then
   again
;

\ Construct the filename used for communicating with the server
d# 20 buffer: filename-buf
: smt-filename$  ( -- )  filename-buf count  ;
: set-filename  ( -- )
   scanned-board#$ filename-buf place
   " .txt" filename-buf $cat
;

: get-info  ( -- )
   get-board#
   set-filename
   get-station#
   get-opid
;

\ Upload the result data 
: smt-result  ( pass? -- adr len )
   smt-filename$  open-temp-file
   if  " PASS"  else  " FAIL"  then  " RESULT="  put-key+value
   " PROCESS=FVT" put-key-line
   " STATION="    put-key-line
   " OPID="       put-key-line
   " GUID="       put-key-line
   scanned-board#$ " MB_NUM=" put-key+value
   " Result" submit-file
;

\ Send the board number as the request and return the response data
: smt-request$  ( -- adr len )
   smt-filename$ open-temp-file
   scanned-board#$  " MB_NUM="  put-key+value
   opid$            " OPID="    put-key+value
   station#$        " STATION=" put-key+value
   " Request" submit-file
   " Response" get-response
;

: clear-mfg-buf  ( -- )  mfg-data-buf  /flash-block  h# ff fill  ;

: put-ascii-tag  ( value$ key$ -- )
   2swap  dup  if  add-null  then  2swap  ( value$' key$ )
   ($add-tag)                             ( )
;

\ Decode the server's response and insert appropriate mfg data tags
: parse-smt-response  ( adr len -- error? )
   drop  " Timeout" comp 0=  if  true exit  then

   flash-write-enable

   clear-mfg-buf                          ( )
\ XXX propagate tag values from response - code in Notes/mfgtags.fth
   " "      " ww"  put-ascii-tag          ( )
   " EN"    " SS"  put-ascii-tag          ( )
   " ASSY"  " TS"  put-ascii-tag          ( )
   " C1"    " SG"  put-ascii-tag          ( )
   scanned-board#$  " B#"  put-ascii-tag  ( )
   (put-mfg-data)                         ( )

   \ check-tags

   no-kbc-reboot
   kbc-on

   false
;

\ Perform the exchange with the manufacturing server
: smt-tag-exchange  ( -- error? )
   smt-request$                    ( adr len )
   2>r  2r@ parse-smt-response     ( error? r: adr len )
   2r> free-mem                    ( error? )
;

d# 15 to #mfgtests

: smt-tests  ( -- pass? )
   5 #mfgtests +  5 do
      i set-current-sq
      refresh
      d# 200 0 do
         d# 10 ms  key? if  unloop unloop exit  then
      loop
      doit
      pass? 0= if  unloop false exit  then
   loop
   all-tests-passed
   true
;

0 value usb-ih
: open-usb   ( -- )
   " /usb:noprobe" open-dev to usb-ih
   usb-ih 0= abort" Can't open USB!"  
;
: close-usb  ( -- )  usb-ih close-dev  0 to usb-ih  ;
: silent-probe-usb  ( -- )
   " /" ['] (probe-usb2) scan-subtree
   " /" ['] (probe-usb1) scan-subtree
   report-disk report-net report-keyboard
;
: usb-ports-changed?  ( -- flag )
   open-usb
   " ports-changed?" usb-ih $call-method  ( changed? )
   close-usb
;

: ?reprobe-usb  ( -- )  usb-ports-changed?  if  silent-probe-usb  then  ;
: reprobe-usb  ( -- )
   begin  d# 100 ms  usb-ports-changed?  until
   silent-probe-usb
;
: scanner?  ( -- flag )
   " usb-keyboard" expand-alias  if  2drop true  else  false  then
;   
: wait-scanner  ( -- )
   begin  scanner?  0= while  ( )
      " Connect USB barcode scanner"  .instructions
      reprobe-usb
   repeat
 ;
: wired-lan?  ( -- flag )
   " /usb/ethernet" locate-device  if  false  else  drop true  then
;
: wait-lan  ( -- )
   begin  wired-lan?  0=  while
      " Connect USB Ethernet Adapter" .instructions
      reprobe-usb
   repeat
;
: usb-key?  ( -- flag )
   " /usb/disk" locate-device  if  false  else  drop true  then
;
: wait-usb-key  ( -- )
   begin  usb-key?  0=  while
      " Connect USB memory stick" .instructions
      reprobe-usb
   repeat
;
: wait-connections  ( -- )
   ?reprobe-usb
   wait-scanner
   wait-lan
   wait-usb-key
;             

: do-smt-test  ( -- )
   wait-connections

   ." Setting clock "  ntp-set-clock  ." Done" cr

   get-info
   ." Connecting "  cifs-connect ." Done" cr

   ." Writing mfg data tags "  smt-tag-exchange  ." Done" cr

   ['] true is (diagnostic-mode?)
   " patch smt-tests play-item mfgtest-menu" evaluate
   menu
   ['] false is (diagnostic-mode?)

   ." Uploading test result "  smt-result  ." Done" cr

   cifs-disconnect
;

\ patch do-smt-test play-item mfgtest-menu

true value once?
: doit-once  ( -- )
   do-key
   once?  if
      false to once?
\      doit
      smt-tests
   then
;
patch doit-once do-key menu-interact
